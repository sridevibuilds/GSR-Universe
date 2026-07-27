const pool = require("../config/db");

// ==========================================
// CREATE TIMETABLE
// ==========================================
exports.createTimetable = async (req, res) => {
    try {
        let {
            class_id,
            academic_year_id,
            title,
            file_name,
            file_path,
            uploaded_by,
            remarks,
            // frontend format
            class_name,
            section
        } = req.body;

        // Resolve academic_year_id
        if (!academic_year_id) {
            const yearRes = await pool.query("SELECT id FROM academic_years WHERE is_current = true LIMIT 1");
            if (yearRes.rows.length > 0) {
                academic_year_id = yearRes.rows[0].id;
            } else {
                academic_year_id = 1;
            }
        }

        // Resolve class_id using class_name and section
        if (!class_id && class_name) {
            const cleanClassName = class_name.trim();
            const cleanSection = (section || 'A').trim();
            let classRes = await pool.query(
                "SELECT id FROM classes WHERE (class_name = $1 OR class_name = $2) AND section = $3 LIMIT 1",
                [cleanClassName, cleanClassName.replace("Class ", "") + "th", cleanSection]
            );
            if (classRes.rows.length > 0) {
                class_id = classRes.rows[0].id;
            } else {
                const insertClass = await pool.query(
                    "INSERT INTO classes (class_name, section, academic_year) VALUES ($1, $2, (SELECT year_name FROM academic_years WHERE id = $3)) RETURNING id",
                    [cleanClassName, cleanSection, academic_year_id]
                );
                class_id = insertClass.rows[0].id;
            }
        }

        if (!uploaded_by) uploaded_by = 1;

        const result = await pool.query(
            `
            INSERT INTO timetable
            (
                class_id,
                academic_year_id,
                title,
                file_name,
                file_path,
                uploaded_by,
                remarks
            )
            VALUES
            ($1,$2,$3,$4,$5,$6,$7)
            RETURNING *;
            `,
            [
                class_id,
                academic_year_id,
                title,
                file_name,
                file_path,
                uploaded_by,
                remarks
            ]
        );

        const newTimetable = result.rows[0];

        // Insert single notification for class
        if (class_id) {
            try {
                await pool.query(
                    `INSERT INTO public.parent_notifications (student_id, class_id, type, title, message, reference_id)
                     VALUES (NULL, $1::integer, 'TIMETABLE', $2::text, $3::text, $4::integer)`,
                    [parseInt(class_id, 10), `New Timetable: ${title || 'Class Schedule'}`, `Class timetable has been updated.`, parseInt(newTimetable.id, 10)]
                );
            } catch (e) {
                console.error("Failed to insert parent timetable notification:", e);
            }
        }

        res.status(201).json({
            success: true,
            message: "Timetable uploaded successfully",
            data: newTimetable
        });

    } catch(err){

        console.error(err);

        res.status(500).json({

            success:false,
            message:err.message

        });

    }

};

// ==========================================
// GET ALL TIMETABLES
// ==========================================
exports.getAllTimetables = async(req,res)=>{

    try{

        const result=await pool.query(`

        SELECT

        t.id,
        c.class_name,
        c.section,
        ay.year_name,
        t.title,
        t.file_name,
        t.file_path,
        t.uploaded_at,
        t.remarks,
        f.faculty_name AS uploaded_by_name

        FROM timetable t

        JOIN classes c
        ON t.class_id=c.id

        JOIN academic_years ay
        ON t.academic_year_id=ay.id

        JOIN faculty f
        ON t.uploaded_by=f.id

        ORDER BY t.id DESC;

        `);

        res.json({

            success:true,
            count:result.rows.length,
            data:result.rows

        });

    }catch(err){

        console.error(err);

        res.status(500).json({

            success:false,
            message:err.message

        });

    }

};

// ==========================================
// GET TIMETABLE BY ID
// ==========================================
exports.getTimetableById=async(req,res)=>{

    try{

        const{id}=req.params;

        const result=await pool.query(

            "SELECT * FROM timetable WHERE id=$1",

            [id]

        );

        res.json({

            success:true,
            data:result.rows[0]

        });

    }catch(err){

        console.error(err);

        res.status(500).json({

            success:false,
            message:err.message

        });

    }

};

// ==========================================
// UPDATE TIMETABLE
// ==========================================
exports.updateTimetable=async(req,res)=>{

    try{

        const{id}=req.params;

        const{

            title,
            file_name,
            file_path,
            remarks

        }=req.body;

        const result=await pool.query(

        `
        UPDATE timetable

        SET

        title=$1,
        file_name=$2,
        file_path=$3,
        remarks=$4

        WHERE id=$5

        RETURNING *;

        `,

        [

        title,
        file_name,
        file_path,
        remarks,
        id

        ]

        );

        res.json({

            success:true,
            message:"Timetable updated successfully",
            data:result.rows[0]

        });

    }catch(err){

        console.error(err);

        res.status(500).json({

            success:false,
            message:err.message

        });

    }

};

// ==========================================
// DELETE TIMETABLE
// ==========================================
exports.deleteTimetable=async(req,res)=>{

    try{

        const{id}=req.params;

        await pool.query(

            "DELETE FROM timetable WHERE id=$1",

            [id]

        );

        res.json({

            success:true,
            message:"Timetable deleted successfully"

        });

    }catch(err){

        console.error(err);

        res.status(500).json({

            success:false,
            message:err.message

        });

    }

};