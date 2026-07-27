const pool = require("../config/db");
const path = require("path");
const fs = require("fs");

// ==========================================
// CREATE MEETING ANNOUNCEMENT (ADMIN)
// ==========================================
exports.createMeetingAnnouncement = async (req, res) => {
    try {
        const {
            title,
            description,
            meeting_date,
            meeting_time,
            venue,
            priority,
            attachment_name,
            attachment_url
        } = req.body;

        let finalAttachmentUrl = attachment_url || null;
        let finalAttachmentName = attachment_name || null;

        if (req.file) {
            finalAttachmentUrl = `/uploads/${req.file.filename}`;
            finalAttachmentName = req.file.originalname;
        }

        const validPriority = ['Normal', 'Important', 'Urgent'].includes(priority) ? priority : 'Normal';

        // 1. Save Meeting Announcement in Database
        const meetingRes = await pool.query(
            `INSERT INTO public.meeting_announcements
             (title, description, meeting_date, meeting_time, venue, priority, attachment_url, attachment_name, created_by)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
             RETURNING *`,
            [
                title,
                description,
                meeting_date,
                meeting_time,
                venue,
                validPriority,
                finalAttachmentUrl,
                finalAttachmentName,
                req.user ? req.user.id : 1
            ]
        );

        const meeting = meetingRes.rows[0];

        // 2. Fetch ALL Faculty members to notify
        const facultyRes = await pool.query("SELECT id FROM public.faculty");
        const facultyList = facultyRes.rows;

        const notifTitle = "New Staff Meeting Scheduled";
        const notifMessage = `Staff Meeting on ${meeting_date} at ${meeting_time} in ${venue}.`;

        let notificationsCreated = 0;
        for (const f of facultyList) {
            await pool.query(
                `INSERT INTO public.faculty_meeting_notifications
                 (meeting_id, faculty_id, title, message, is_read)
                 VALUES ($1, $2, $3, $4, false)`,
                [meeting.id, f.id, notifTitle, notifMessage]
            );
            notificationsCreated++;
        }

        res.status(201).json({
            success: true,
            message: "Meeting Announcement published successfully and sent to faculty.",
            data: meeting,
            notifications_sent: notificationsCreated
        });

    } catch (err) {
        console.error("Error creating meeting announcement:", err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// ==========================================
// GET PUBLISHED MEETING HISTORY (ADMIN & FACULTY)
// ==========================================
exports.getMeetingHistory = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT * FROM public.meeting_announcements
             ORDER BY created_at DESC, meeting_date DESC`
        );

        res.json({
            success: true,
            count: result.rows.length,
            data: result.rows
        });
    } catch (err) {
        console.error("Error fetching meeting history:", err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// ==========================================
// GET FACULTY NOTIFICATIONS (FACULTY ONLY)
// ==========================================
exports.getFacultyNotifications = async (req, res) => {
    try {
        let facultyId = req.query.faculty_id;
        if (!facultyId && req.user && req.user.role === 'faculty') {
            facultyId = req.user.id;
        }

        let query;
        let params = [];

        if (facultyId) {
            query = `
                SELECT 
                    fmn.id as notification_id,
                    fmn.meeting_id,
                    fmn.faculty_id,
                    fmn.title as notif_title,
                    fmn.message as notif_message,
                    fmn.is_read,
                    fmn.created_at as notification_created_at,
                    ma.title as meeting_title,
                    ma.description,
                    TO_CHAR(ma.meeting_date, 'YYYY-MM-DD') as meeting_date,
                    ma.meeting_time,
                    ma.venue,
                    ma.priority,
                    ma.attachment_url,
                    ma.attachment_name
                FROM public.faculty_meeting_notifications fmn
                JOIN public.meeting_announcements ma ON fmn.meeting_id = ma.id
                WHERE fmn.faculty_id = $1
                ORDER BY fmn.created_at DESC
            `;
            params = [facultyId];
        } else {
            query = `
                SELECT DISTINCT ON (ma.id)
                    fmn.id as notification_id,
                    fmn.meeting_id,
                    fmn.faculty_id,
                    fmn.title as notif_title,
                    fmn.message as notif_message,
                    fmn.is_read,
                    fmn.created_at as notification_created_at,
                    ma.title as meeting_title,
                    ma.description,
                    TO_CHAR(ma.meeting_date, 'YYYY-MM-DD') as meeting_date,
                    ma.meeting_time,
                    ma.venue,
                    ma.priority,
                    ma.attachment_url,
                    ma.attachment_name
                FROM public.faculty_meeting_notifications fmn
                JOIN public.meeting_announcements ma ON fmn.meeting_id = ma.id
                ORDER BY ma.id DESC, fmn.created_at DESC
            `;
        }

        const result = await pool.query(query, params);
        const unreadCount = result.rows.filter(r => r.is_read === false).length;

        res.json({
            success: true,
            count: result.rows.length,
            unread_count: unreadCount,
            data: result.rows
        });
    } catch (err) {
        console.error("Error fetching faculty notifications:", err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// ==========================================
// MARK NOTIFICATION AS READ
// ==========================================
exports.markNotificationAsRead = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `UPDATE public.faculty_meeting_notifications
             SET is_read = true
             WHERE id = $1
             RETURNING *`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Notification not found"
            });
        }

        res.json({
            success: true,
            message: "Notification marked as read",
            data: result.rows[0]
        });
    } catch (err) {
        console.error("Error marking notification as read:", err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// ==========================================
// VIEW / DOWNLOAD ATTACHMENT
// ==========================================
exports.getMeetingAttachment = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(
            "SELECT attachment_url, attachment_name, title FROM public.meeting_announcements WHERE id = $1",
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: "Meeting announcement not found" });
        }

        const meeting = result.rows[0];
        if (!meeting.attachment_url) {
            const fallbackPdf = "%PDF-1.4 %âãÏÓ 1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj 2 0 obj << /Type /Pages /Kinds [ /Page ] /Count 1 /Kids [ 3 0 R ] >> endobj 3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [ 0 0 612 792 ] /Contents 4 0 R /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >> >> endobj 4 0 obj << /Length 56 >> stream BT /F1 18 Tf 100 700 Td (Meeting Announcement Document) Tj ET endstream endobj xref 0 5 0000000000 65535 f 0000000015 00000 n 0000000074 00000 n 0000000161 00000 n 0000000341 00000 n trailer << /Size 5 /Root 1 0 R >> startxref 448 %%EOF";
            res.setHeader("Content-Type", "application/pdf");
            res.setHeader("Content-Disposition", `inline; filename="${meeting.title.replace(/[^a-zA-Z0-9]/g, '_')}_Attachment.pdf"`);
            return res.send(Buffer.from(fallbackPdf));
        }

        const filePath = path.join(__dirname, "..", meeting.attachment_url);
        if (fs.existsSync(filePath)) {
            return res.sendFile(filePath);
        } else {
            const fallbackPdf = "%PDF-1.4 %âãÏÓ 1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj 2 0 obj << /Type /Pages /Kinds [ /Page ] /Count 1 /Kids [ 3 0 R ] >> endobj 3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [ 0 0 612 792 ] /Contents 4 0 R /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >> >> endobj 4 0 obj << /Length 56 >> stream BT /F1 18 Tf 100 700 Td (Meeting Announcement Document) Tj ET endstream endobj xref 0 5 0000000000 65535 f 0000000015 00000 n 0000000074 00000 n 0000000161 00000 n 0000000341 00000 n trailer << /Size 5 /Root 1 0 R >> startxref 448 %%EOF";
            res.setHeader("Content-Type", "application/pdf");
            res.setHeader("Content-Disposition", `inline; filename="${meeting.title.replace(/[^a-zA-Z0-9]/g, '_')}_Attachment.pdf"`);
            return res.send(Buffer.from(fallbackPdf));
        }
    } catch (err) {
        console.error("Error serving meeting attachment:", err);
        res.status(500).json({ success: false, message: err.message });
    }
};

// ==========================================
// DELETE MEETING ANNOUNCEMENT (ADMIN)
// ==========================================
exports.deleteMeetingAnnouncement = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            "DELETE FROM public.meeting_announcements WHERE id = $1 RETURNING *",
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Meeting announcement not found"
            });
        }

        res.json({
            success: true,
            message: "Meeting announcement deleted successfully",
            data: result.rows[0]
        });
    } catch (err) {
        console.error("Error deleting meeting announcement:", err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};
