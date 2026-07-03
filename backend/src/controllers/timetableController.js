const pool = require("../config/db");

// ==========================================
// CREATE TIMETABLE
// ==========================================
exports.createTimetable = async (req, res) => {

    try {

        const {
            class_id,
            academic_year_id,
            title,
            file_name,
            file_path,
            uploaded_by,
            remarks
        } = req.body;

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

        res.status(201).json({

            success:true,
            message:"Timetable uploaded successfully",
            data:result.rows[0]

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