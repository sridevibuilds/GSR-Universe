const pool = require("../config/db");

// ==========================================
// CREATE ASSIGNMENT
// ==========================================
exports.createAssignment = async (req, res) => {
    try {

        const {
            class_id,
            academic_year_id,
            subject_id,
            title,
            description,
            submission_date,
            attachment_name,
            attachment_path,
            created_by
        } = req.body;

        const result = await pool.query(
            `
            INSERT INTO assignments
            (
                class_id,
                academic_year_id,
                subject_id,
                title,
                description,
                submission_date,
                attachment_name,
                attachment_path,
                created_by
            )
            VALUES
            ($1,$2,$3,$4,$5,$6,$7,$8,$9)
            RETURNING *;
            `,
            [
                class_id,
                academic_year_id,
                subject_id,
                title,
                description,
                submission_date,
                attachment_name,
                attachment_path,
                created_by
            ]
        );

        res.status(201).json({
            success: true,
            message: "Assignment created successfully",
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
// GET ALL ASSIGNMENTS
// ==========================================
exports.getAllAssignments = async (req, res) => {

    try {

        const result = await pool.query(`
            SELECT
                a.id,
                c.class_name,
                c.section,
                ay.year_name,
                s.subject_name,
                a.title,
                a.description,
                a.submission_date,
                a.attachment_name,
                f.faculty_name AS created_by

            FROM assignments a

            JOIN classes c
                ON a.class_id=c.id

            JOIN academic_years ay
                ON a.academic_year_id=ay.id

            JOIN subjects s
                ON a.subject_id=s.id

            JOIN faculty f
                ON a.created_by=f.id

            ORDER BY a.id DESC
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
// GET ASSIGNMENT BY ID
// ==========================================
exports.getAssignmentById = async(req,res)=>{

    try{

        const {id}=req.params;

        const result=await pool.query(
            "SELECT * FROM assignments WHERE id=$1",
            [id]
        );

        if(result.rows.length===0){

            return res.status(404).json({
                success:false,
                message:"Assignment not found"
            });

        }

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
// UPDATE ASSIGNMENT
// ==========================================
exports.updateAssignment=async(req,res)=>{

    try{

        const {id}=req.params;

        const{
            title,
            description,
            submission_date
        }=req.body;

        const result=await pool.query(

            `
            UPDATE assignments
            SET
                title=$1,
                description=$2,
                submission_date=$3
            WHERE id=$4
            RETURNING *;
            `,

            [
                title,
                description,
                submission_date,
                id
            ]

        );

        res.json({

            success:true,
            message:"Assignment updated successfully",
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
// DELETE ASSIGNMENT
// ==========================================
exports.deleteAssignment=async(req,res)=>{

    try{

        const{id}=req.params;

        await pool.query(

            "DELETE FROM assignments WHERE id=$1",
            [id]

        );

        res.json({

            success:true,
            message:"Assignment deleted successfully"

        });

    }catch(err){

        console.error(err);

        res.status(500).json({

            success:false,
            message:err.message

        });

    }

};