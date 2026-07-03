const pool = require("../config/db");

// ==========================================
// CREATE FEE
// ==========================================
exports.createFee = async (req, res) => {

    try {

        const {
            student_class_mapping_id,
            academic_year_id,
            total_fee,
            paid_amount,
            pending_amount,
            due_date,
            updated_by,
            remarks
        } = req.body;

        const result = await pool.query(
            `
            INSERT INTO fees
            (
                student_class_mapping_id,
                academic_year_id,
                total_fee,
                paid_amount,
                pending_amount,
                due_date,
                updated_by,
                remarks
            )
            VALUES
            ($1,$2,$3,$4,$5,$6,$7,$8)
            RETURNING *
            `,
            [
                student_class_mapping_id,
                academic_year_id,
                total_fee,
                paid_amount,
                pending_amount,
                due_date,
                updated_by,
                remarks
            ]
        );

        res.status(201).json({
            success: true,
            message: "Fee created successfully",
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
// GET ALL FEES
// ==========================================
exports.getAllFees = async (req, res) => {

    try {

        const result = await pool.query(`
            SELECT
                f.id,
                s.student_name,
                c.class_name,
                ay.year_name,
                f.total_fee,
                f.paid_amount,
                f.pending_amount,
                f.due_date,
                f.remarks

            FROM fees f

            JOIN student_class_mapping scm
                ON f.student_class_mapping_id=scm.id

            JOIN students s
                ON scm.student_id=s.id

            JOIN classes c
                ON scm.class_id=c.id

            JOIN academic_years ay
                ON f.academic_year_id=ay.id

            ORDER BY f.id DESC
        `);

        res.json({

            success:true,
            count:result.rows.length,
            data:result.rows

        });

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success:false,
            message:err.message

        });

    }

};

// ==========================================
// GET FEE BY ID
// ==========================================
exports.getFeeById = async (req, res) => {

    try {

        const { id } = req.params;

        const result = await pool.query(
            "SELECT * FROM fees WHERE id=$1",
            [id]
        );

        res.json({

            success:true,
            data:result.rows[0]

        });

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success:false,
            message:err.message

        });

    }

};

// ==========================================
// UPDATE FEE
// ==========================================
exports.updateFee = async (req, res) => {

    try {

        const { id } = req.params;

        const {

            paid_amount,
            pending_amount,
            due_date,
            remarks

        } = req.body;

        const result = await pool.query(

            `
            UPDATE fees
            SET

                paid_amount=$1,
                pending_amount=$2,
                due_date=$3,
                remarks=$4

            WHERE id=$5

            RETURNING *

            `,

            [

                paid_amount,
                pending_amount,
                due_date,
                remarks,
                id

            ]

        );

        res.json({

            success:true,
            message:"Fee updated successfully",
            data:result.rows[0]

        });

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success:false,
            message:err.message

        });

    }

};

// ==========================================
// DELETE FEE
// ==========================================
exports.deleteFee = async (req, res) => {

    try {

        const { id } = req.params;

        await pool.query(

            "DELETE FROM fees WHERE id=$1",

            [id]

        );

        res.json({

            success:true,
            message:"Fee deleted successfully"

        });

    } catch (err) {

        console.error(err);

        res.status(500).json({

            success:false,
            message:err.message

        });

    }

};