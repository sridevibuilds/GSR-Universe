const pool = require("../config/db");

// ==========================================
// CREATE PROGRESS CARD
// ==========================================
exports.createProgressCard = async (req, res) => {
    try {

        const {
            student_class_mapping_id,
            academic_year_id,
            uploaded_by,
            file_name,
            file_path,
            remarks
        } = req.body;

        const result = await pool.query(
            `
            INSERT INTO progress_cards
            (
                student_class_mapping_id,
                academic_year_id,
                uploaded_by,
                file_name,
                file_path,
                remarks
            )
            VALUES($1,$2,$3,$4,$5,$6)
            RETURNING *;
            `,
            [
                student_class_mapping_id,
                academic_year_id,
                uploaded_by,
                file_name,
                file_path,
                remarks
            ]
        );

        const newProgressCard = result.rows[0];

        // Insert single notification for mapped student
        if (student_class_mapping_id) {
            try {
                const scmRes = await pool.query("SELECT student_id, class_id FROM student_class_mapping WHERE id = $1", [student_class_mapping_id]);
                const targetStudentId = scmRes.rows.length > 0 ? scmRes.rows[0].student_id : null;
                const targetClassId = scmRes.rows.length > 0 ? scmRes.rows[0].class_id : null;

                await pool.query(
                    `INSERT INTO public.parent_notifications (student_id, class_id, type, title, message, reference_id)
                     VALUES ($1::integer, $2::integer, 'PROGRESS_CARD', $3::text, $4::text, $5::integer)`,
                    [targetStudentId, targetClassId, `New Progress Card Uploaded`, remarks || 'Academic progress card is now available.', parseInt(newProgressCard.id, 10)]
                );
            } catch (e) {
                console.error("Failed to insert parent progress card notification:", e);
            }
        }

        res.status(201).json({
            success: true,
            message: "Progress Card uploaded successfully",
            data: newProgressCard
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
// GET ALL PROGRESS CARDS
// ==========================================
exports.getAllProgressCards = async (req,res)=>{

    try{

        const result=await pool.query(`
            SELECT
                pc.id,
                s.student_name,
                c.class_name,
                c.section,
                ay.year_name,
                pc.file_name,
                pc.file_path,
                pc.uploaded_at,
                pc.remarks,
                f.faculty_name AS uploaded_by

            FROM progress_cards pc

            JOIN student_class_mapping scm
                ON pc.student_class_mapping_id=scm.id

            JOIN students s
                ON scm.student_id=s.id

            JOIN classes c
                ON scm.class_id=c.id

            JOIN academic_years ay
                ON pc.academic_year_id=ay.id

            JOIN faculty f
                ON pc.uploaded_by=f.id

            ORDER BY pc.id DESC;
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
// GET PROGRESS CARD BY ID
// ==========================================
exports.getProgressCardById=async(req,res)=>{

    try{

        const{id}=req.params;

        const result=await pool.query(
            "SELECT * FROM progress_cards WHERE id=$1",
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
// UPDATE PROGRESS CARD
// ==========================================
exports.updateProgressCard=async(req,res)=>{

    try{

        const{id}=req.params;

        const{
            file_name,
            file_path,
            remarks
        }=req.body;

        const result=await pool.query(

            `
            UPDATE progress_cards
            SET
                file_name=$1,
                file_path=$2,
                remarks=$3
            WHERE id=$4
            RETURNING *;
            `,

            [
                file_name,
                file_path,
                remarks,
                id
            ]

        );

        res.json({
            success:true,
            message:"Progress Card updated successfully",
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
// DELETE PROGRESS CARD
// ==========================================
exports.deleteProgressCard=async(req,res)=>{

    try{

        const{id}=req.params;

        await pool.query(
            "DELETE FROM progress_cards WHERE id=$1",
            [id]
        );

        res.json({
            success:true,
            message:"Progress Card deleted successfully"
        });

    }catch(err){

        console.error(err);

        res.status(500).json({
            success:false,
            message:err.message
        });

    }

};