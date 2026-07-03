const pool = require("../config/db");

// ==========================================
// CREATE HOMEWORK
// ==========================================
exports.createHomework = async (req, res) => {
    try {

        const {
            class_id,
            academic_year_id,
            subject_id,
            title,
            description,
            due_date,
            attachment_name,
            attachment_path,
            created_by
        } = req.body;

        const result = await pool.query(
            `INSERT INTO homework
            (
                class_id,
                academic_year_id,
                subject_id,
                title,
                description,
                due_date,
                attachment_name,
                attachment_path,
                created_by
            )
            VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)
            RETURNING *`,
            [
                class_id,
                academic_year_id,
                subject_id,
                title,
                description,
                due_date,
                attachment_name,
                attachment_path,
                created_by
            ]
        );

        res.status(201).json({
            success: true,
            message: "Homework created successfully",
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
// GET ALL HOMEWORK
// ==========================================
exports.getAllHomework = async (req, res) => {

    try {

        const result = await pool.query(`
            SELECT
                h.id,
                c.class_name,
                c.section,
                ay.year_name,
                s.subject_name,
                h.title,
                h.description,
                h.due_date,
                h.attachment_name,
                f.faculty_name AS created_by
            FROM homework h
            JOIN classes c ON h.class_id=c.id
            JOIN academic_years ay ON h.academic_year_id=ay.id
            JOIN subjects s ON h.subject_id=s.id
            JOIN faculty f ON h.created_by=f.id
            ORDER BY h.id DESC
        `);

        res.json({
            success: true,
            count: result.rows.length,
            data: result.rows
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
// GET HOMEWORK BY ID
// ==========================================
exports.getHomeworkById = async(req,res)=>{

    try{

        const {id}=req.params;

        const result=await pool.query(
            "SELECT * FROM homework WHERE id=$1",
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
// UPDATE HOMEWORK
// ==========================================
exports.updateHomework=async(req,res)=>{

    try{

        const {id}=req.params;

        const {
            title,
            description,
            due_date
        }=req.body;

        const result=await pool.query(

            `UPDATE homework
            SET
            title=$1,
            description=$2,
            due_date=$3
            WHERE id=$4
            RETURNING *`,

            [
                title,
                description,
                due_date,
                id
            ]

        );

        res.json({
            success:true,
            message:"Homework updated successfully",
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
// DELETE HOMEWORK
// ==========================================
exports.deleteHomework=async(req,res)=>{

    try{

        const {id}=req.params;

        await pool.query(
            "DELETE FROM homework WHERE id=$1",
            [id]
        );

        res.json({
            success:true,
            message:"Homework deleted successfully"
        });

    }catch(err){

        console.error(err);

        res.status(500).json({
            success:false,
            message:err.message
        });

    }

};