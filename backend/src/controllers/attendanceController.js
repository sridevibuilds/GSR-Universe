const pool = require("../config/db");

// ==========================================
// MARK ATTENDANCE
// ==========================================

const markAttendance = async (req, res) => {

    try {

        const {
            student_class_mapping_id,
            attendance_date,
            period_number,
            subject,
            status,
            remarks
        } = req.body;

        const faculty_id = req.user.id;

        if (
            !student_class_mapping_id ||
            !attendance_date ||
            !period_number ||
            !subject ||
            !status
        ) {
            return res.status(400).json({
                success: false,
                message: "All required fields are mandatory."
            });
        }

        const alreadyMarked = await pool.query(
            `
            SELECT id
            FROM attendance
            WHERE
                student_class_mapping_id = $1
                AND attendance_date = $2
                AND period_number = $3
                AND subject = $4
            `,
            [
                student_class_mapping_id,
                attendance_date,
                period_number,
                subject
            ]
        );

        if (alreadyMarked.rows.length > 0) {

            return res.status(400).json({
                success: false,
                message: "Attendance already marked."
            });

        }

        const result = await pool.query(

            `
            INSERT INTO attendance
            (
                student_class_mapping_id,
                attendance_date,
                period_number,
                subject,
                faculty_id,
                status,
                remarks
            )
            VALUES
            (
                $1,$2,$3,$4,$5,$6,$7
            )
            RETURNING *
            `,

            [
                student_class_mapping_id,
                attendance_date,
                period_number,
                subject,
                faculty_id,
                status,
                remarks
            ]

        );

        res.status(201).json({

            success: true,
            message: "Attendance Marked Successfully",

            attendance: result.rows[0]

        });

    }

    catch (error) {

        console.log(error);

        res.status(500).json({

            success: false,
            message: "Server Error"

        });

    }

};

// ==========================================
// GET ALL ATTENDANCE
// ==========================================

const getAllAttendance = async (req, res) => {

    try {

        const result = await pool.query(

            `
            SELECT
                attendance.*,
                students.student_name,
                students.admission_no
            FROM attendance

            JOIN student_class_mapping
            ON attendance.student_class_mapping_id =
               student_class_mapping.id

            JOIN students
            ON student_class_mapping.student_id =
               students.id

            ORDER BY attendance_date DESC
            `

        );

        res.json({

            success: true,

            total: result.rows.length,

            attendance: result.rows

        });

    }

    catch (error) {

        console.log(error);

        res.status(500).json({

            success: false,

            message: "Server Error"

        });

    }

};

// ==========================================
// GET ATTENDANCE BY STUDENT
// ==========================================

const getAttendanceByStudent = async (req, res) => {

    try {

        const studentId = req.params.studentId;

        const result = await pool.query(

            `
            SELECT
                attendance.*
            FROM attendance

            JOIN student_class_mapping
            ON attendance.student_class_mapping_id =
               student_class_mapping.id

            WHERE student_class_mapping.student_id = $1

            ORDER BY attendance_date DESC
            `,

            [studentId]

        );

        res.json({

            success: true,

            total: result.rows.length,

            attendance: result.rows

        });

    }

    catch (error) {

        console.log(error);

        res.status(500).json({

            success: false,

            message: "Server Error"

        });

    }

};

// ==========================================
// UPDATE ATTENDANCE
// ==========================================

const updateAttendance = async (req, res) => {

    try {

        const id = req.params.id;

        const {

            status,

            remarks

        } = req.body;

        const result = await pool.query(

            `
            UPDATE attendance

            SET

                status = $1,

                remarks = $2

            WHERE id = $3

            RETURNING *
            `,

            [

                status,

                remarks,

                id

            ]

        );

        if (result.rows.length === 0) {

            return res.status(404).json({

                success: false,

                message: "Attendance not found."

            });

        }

        res.json({

            success: true,

            message: "Attendance Updated Successfully",

            attendance: result.rows[0]

        });

    }

    catch (error) {

        console.log(error);

        res.status(500).json({

            success: false,

            message: "Server Error"

        });

    }

};

// ==========================================
// DELETE ATTENDANCE
// ==========================================

const deleteAttendance = async (req, res) => {

    try {

        const id = req.params.id;

        const result = await pool.query(

            `
            DELETE FROM attendance

            WHERE id = $1

            RETURNING *
            `,

            [id]

        );

        if (result.rows.length === 0) {

            return res.status(404).json({

                success: false,

                message: "Attendance not found."

            });

        }

        res.json({

            success: true,

            message: "Attendance Deleted Successfully"

        });

    }

    catch (error) {

        console.log(error);

        res.status(500).json({

            success: false,

            message: "Server Error"

        });

    }

};

module.exports = {

    markAttendance,

    getAllAttendance,

    getAttendanceByStudent,

    updateAttendance,

    deleteAttendance

};