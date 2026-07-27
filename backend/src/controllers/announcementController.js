const pool = require('../config/db');

const normalizePriority = (p) => {
    if (!p) return 'Normal';
    const lower = p.toString().trim().toLowerCase();
    if (lower.includes('urg') || lower.includes('high')) return 'Urgent';
    if (lower.includes('imp') || lower.includes('med')) return 'Important';
    return 'Normal';
};

// ==========================================
// CREATE ANNOUNCEMENT (One-Announcement Many-Targets Architecture)
// ==========================================
exports.createAnnouncement = async (req, res) => {
    try {
        let {
            class_id,
            academic_year_id,
            title,
            message,
            priority,
            created_by,
            target_scope,
            classes,
            sections,
            announcement_date
        } = req.body;

        // Resolve academic_year_id
        if (!academic_year_id) {
            const yearRes = await pool.query("SELECT id FROM academic_years WHERE is_current = true LIMIT 1");
            academic_year_id = yearRes.rows.length > 0 ? yearRes.rows[0].id : 1;
        }

        if (!created_by) created_by = 1;
        const upperScope = target_scope ? target_scope.toUpperCase() : 'CLASS';
        const cleanPriority = normalizePriority(priority);
        const broadcastTimestamp = announcement_date ? new Date(announcement_date) : new Date();

        // 1. Insert EXACTLY ONE announcement row into DB
        const insertAnnRes = await pool.query(
            `INSERT INTO announcements (academic_year_id, title, message, priority, created_by, target_scope, created_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
            [academic_year_id, title, message, cleanPriority, created_by, upperScope, broadcastTimestamp]
        );
        const announcement = insertAnnRes.rows[0];

        // 2. Associate Target Classes in announcement_targets table
        const sectionsToTarget = (sections && Array.isArray(sections) && sections.length > 0) ? sections : ['A', 'B', 'C'];
        if (classes && Array.isArray(classes) && classes.length > 0) {
            for (const className of classes) {
                const cleanClassName = className.trim();
                for (const sec of sectionsToTarget) {
                    let targetClassId;
                    let classRes = await pool.query(
                        "SELECT id FROM classes WHERE (class_name = $1 OR class_name = $2) AND section = $3 LIMIT 1",
                        [cleanClassName, cleanClassName.replace("Class ", "") + "th", sec]
                    );
                    if (classRes.rows.length > 0) {
                        targetClassId = classRes.rows[0].id;
                    } else {
                        const insertClass = await pool.query(
                            "INSERT INTO classes (class_name, section, academic_year) VALUES ($1, $2, (SELECT year_name FROM academic_years WHERE id = $3)) RETURNING id",
                            [cleanClassName, sec, academic_year_id]
                        );
                        targetClassId = insertClass.rows[0].id;
                    }

                    await pool.query(
                        `INSERT INTO announcement_targets (announcement_id, class_id)
                         VALUES ($1, $2) ON CONFLICT (announcement_id, class_id) DO NOTHING`,
                        [announcement.id, targetClassId]
                    );
                }
            }
        } else if (class_id) {
            await pool.query(
                `INSERT INTO announcement_targets (announcement_id, class_id)
                 VALUES ($1, $2) ON CONFLICT (announcement_id, class_id) DO NOTHING`,
                [announcement.id, class_id]
            );
        }

        // Insert single notification for announcement
        try {
            const targetClassId = (upperScope === 'ALL' || upperScope === 'ENTIRE_SCHOOL' || !class_id) ? null : parseInt(class_id, 10);
            await pool.query(
                `INSERT INTO public.parent_notifications (student_id, class_id, type, title, message, reference_id)
                 VALUES (NULL, $1::integer, 'ANNOUNCEMENT', $2::text, $3::text, $4::integer)`,
                [targetClassId, `New Announcement: ${title}`, message || 'New announcement published by faculty.', parseInt(announcement.id, 10)]
            );
        } catch (e) {
            console.error("Failed to insert parent announcement notification:", e);
        }

        res.status(201).json({
            success: true,
            message: "Announcement created successfully",
            data: announcement
        });

    } catch (err) {
        console.error(err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// ==========================================
// GET ALL ANNOUNCEMENTS (One Card per Announcement Row)
// ==========================================
exports.getAllAnnouncements = async (req, res) => {
    try {
        const rawRes = await pool.query(`
            SELECT
                a.id,
                a.title,
                a.message,
                a.priority,
                a.created_at,
                COALESCE(f.faculty_name, 'Admin') AS created_by,
                c.class_name,
                c.section
            FROM announcements a
            LEFT JOIN announcement_targets at ON a.id = at.announcement_id
            LEFT JOIN classes c ON at.class_id = c.id
            LEFT JOIN faculty f ON a.created_by = f.id
            ORDER BY a.id DESC
        `);

        // Group target classes per single announcement ID
        const announcementMap = new Map();
        for (const row of rawRes.rows) {
            if (!announcementMap.has(row.id)) {
                announcementMap.set(row.id, {
                    id: row.id,
                    title: row.title,
                    message: row.message,
                    priority: row.priority || 'Normal',
                    created_at: row.created_at,
                    created_by: row.created_by,
                    classMap: new Map()
                });
            }

            const item = announcementMap.get(row.id);
            if (row.class_name) {
                let cName = row.class_name.toString().trim().replace(/^Class\s+/i, '').replace(/th$/i, '');
                let sec = (row.section || 'A').toString().trim().toUpperCase();
                if (!item.classMap.has(cName)) {
                    item.classMap.set(cName, new Set());
                }
                item.classMap.get(cName).add(sec);
            }
        }

        const data = [];
        for (const item of announcementMap.values()) {
            const formattedParts = [];
            for (const [cName, secSet] of item.classMap.entries()) {
                const sortedSecs = Array.from(secSet).sort().join(',');
                formattedParts.push(`${cName}(${sortedSecs})`);
            }

            data.push({
                id: item.id,
                title: item.title,
                message: item.message,
                priority: item.priority,
                created_at: item.created_at,
                created_by: item.created_by,
                target_classes: formattedParts.length > 0 ? formattedParts.join(', ') : 'All Classes'
            });
        }

        res.json({
            success: true,
            count: data.length,
            data: data
        });

    } catch (err) {
        console.error(err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// ==========================================
// GET ANNOUNCEMENT BY ID
// ==========================================
exports.getAnnouncementById = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query("SELECT * FROM announcements WHERE id=$1", [id]);
        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Announcement not found"
            });
        }
        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// ==========================================
// UPDATE ANNOUNCEMENT
// ==========================================
exports.updateAnnouncement = async (req, res) => {
    try {
        const { id } = req.params;
        const { title, message, priority, target_scope } = req.body;
        const result = await pool.query(
            `UPDATE announcements
             SET title=$1, message=$2, priority=$3, target_scope=$4
             WHERE id=$5 RETURNING *`,
            [title, message, priority, target_scope, id]
        );
        res.json({
            success: true,
            message: "Announcement updated successfully",
            data: result.rows[0]
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// ==========================================
// DELETE ANNOUNCEMENT (ON DELETE CASCADE removes target mappings)
// ==========================================
exports.deleteAnnouncement = async (req, res) => {
    try {
        const { id } = req.params;
        await pool.query("DELETE FROM announcements WHERE id=$1", [id]);
        res.json({
            success: true,
            message: "Announcement deleted successfully"
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};