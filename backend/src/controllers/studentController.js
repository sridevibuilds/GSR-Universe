const db = require("../config/db");

// ==========================================
// CREATE STUDENT
// ==========================================

const createStudent = async (req, res) => {
    try {

        const {
            admission_no,
            student_name,
            class_name,
            section,
            primary_parent_name,
            secondary_parent_name,
            primary_parent_mobile,
            secondary_parent_mobile,
            parent_email,
            date_of_birth
        } = req.body;

        const existing = await db.query(
            "SELECT id FROM students WHERE admission_no=$1",
            [admission_no]
        );

        if (existing.rows.length > 0) {
            return res.status(400).json({
                success: false,
                message: "Admission Number already exists."
            });
        }

        const result = await db.query(
            `INSERT INTO students
            (
                admission_no,
                student_name,
                class_name,
                section,
                primary_parent_name,
                secondary_parent_name,
                primary_parent_mobile,
                secondary_parent_mobile,
                parent_email,
                date_of_birth
            )
            VALUES
            ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
            RETURNING *`,
            [
                admission_no,
                student_name,
                class_name,
                section,
                primary_parent_name,
                secondary_parent_name,
                primary_parent_mobile,
                secondary_parent_mobile,
                parent_email,
                date_of_birth
            ]
        );

        res.status(201).json({
            success: true,
            message: "Student Created Successfully",
            student: result.rows[0]
        });

    } catch (err) {

        console.log(err);

        res.status(500).json({
            success: false,
            message: "Server Error"
        });

    }
};

// ==========================================
// GET ALL STUDENTS
// ==========================================

const getAllStudents = async (req, res) => {

    try {

        const result = await db.query(
            "SELECT * FROM students ORDER BY student_name"
        );

        res.json({
            success: true,
            total: result.rows.length,
            students: result.rows
        });

    } catch (err) {

        console.log(err);

        res.status(500).json({
            success: false,
            message: "Server Error"
        });

    }

};

// ==========================================
// GET STUDENT BY ID
// ==========================================

const getStudentById = async (req, res) => {

    try {

        const result = await db.query(
            "SELECT * FROM students WHERE id=$1",
            [req.params.id]
        );

        if (result.rows.length === 0) {

            return res.status(404).json({
                success: false,
                message: "Student Not Found"
            });

        }

        res.json({
            success: true,
            student: result.rows[0]
        });

    } catch (err) {

        console.log(err);

        res.status(500).json({
            success: false,
            message: "Server Error"
        });

    }

};

// ==========================================
// UPDATE STUDENT
// ==========================================

const updateStudent = async (req, res) => {

    try {

        const id = req.params.id;

        const {
            student_name,
            class_name,
            section,
            primary_parent_name,
            secondary_parent_name,
            primary_parent_mobile,
            secondary_parent_mobile,
            parent_email,
            date_of_birth
        } = req.body;

        const result = await db.query(
            `UPDATE students
            SET
                student_name=$1,
                class_name=$2,
                section=$3,
                primary_parent_name=$4,
                secondary_parent_name=$5,
                primary_parent_mobile=$6,
                secondary_parent_mobile=$7,
                parent_email=$8,
                date_of_birth=$9
            WHERE id=$10
            RETURNING *`,
            [
                student_name,
                class_name,
                section,
                primary_parent_name,
                secondary_parent_name,
                primary_parent_mobile,
                secondary_parent_mobile,
                parent_email,
                date_of_birth,
                id
            ]
        );

        if (result.rows.length === 0) {

            return res.status(404).json({
                success: false,
                message: "Student Not Found"
            });

        }

        res.json({
            success: true,
            message: "Student Updated Successfully",
            student: result.rows[0]
        });

    } catch (err) {

        console.log(err);

        res.status(500).json({
            success: false,
            message: "Server Error"
        });

    }

};

// ==========================================
// DELETE STUDENT
// ==========================================

const deleteStudent = async (req, res) => {

    try {

        const result = await db.query(
            "DELETE FROM students WHERE id=$1 RETURNING *",
            [req.params.id]
        );

        if (result.rows.length === 0) {

            return res.status(404).json({
                success: false,
                message: "Student Not Found"
            });

        }

        res.json({
            success: true,
            message: "Student Deleted Successfully"
        });

    } catch (err) {

        console.log(err);

        res.status(500).json({
            success: false,
            message: "Server Error"
        });

    }

};

module.exports = {

    createStudent,
    getAllStudents,
    getStudentById,
    updateStudent,
    deleteStudent

};