const db = require("../config/db");
const bcrypt = require("bcrypt");

// ==========================================
// CREATE FACULTY
// ==========================================

const createFaculty = async (req, res) => {

    try {

        const {

            employee_id,
            faculty_name,
            email,
            password,
            mobile,
            subject,
            role

        } = req.body;

        if (
            !employee_id ||
            !faculty_name ||
            !email ||
            !password
        ) {

            return res.status(400).json({

                success: false,
                message: "Required fields are missing."

            });

        }

        const existingFaculty = await db.query(

            "SELECT * FROM faculty WHERE email=$1",

            [email]

        );

        if (existingFaculty.rows.length > 0) {

            return res.status(400).json({

                success: false,
                message: "Faculty already exists."

            });

        }

        const password_hash = await bcrypt.hash(password, 10);

        const result = await db.query(

            `
            INSERT INTO faculty
            (
                employee_id,
                faculty_name,
                email,
                password_hash,
                mobile,
                subject,
                role
            )

            VALUES
            (
                $1,$2,$3,$4,$5,$6,$7
            )

            RETURNING
                id,
                employee_id,
                faculty_name,
                email,
                mobile,
                subject,
                role,
                is_active,
                created_at
            `,

            [

                employee_id,
                faculty_name,
                email,
                password_hash,
                mobile,
                subject,
                role

            ]

        );

        res.status(201).json({

            success: true,
            message: "Faculty Created Successfully",
            faculty: result.rows[0]

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
// GET ALL FACULTY
// ==========================================

const getAllFaculty = async (req, res) => {

    try {

        const result = await db.query(

            `
            SELECT

                id,
                employee_id,
                faculty_name,
                email,
                mobile,
                subject,
                role,
                is_active,
                created_at

            FROM faculty

            ORDER BY id DESC
            `

        );

        res.json({

            success: true,
            count: result.rows.length,
            faculty: result.rows

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
// GET FACULTY BY ID
// ==========================================

const getFacultyById = async (req, res) => {

    try {

        const { id } = req.params;

        const result = await db.query(

            `
            SELECT

                id,
                employee_id,
                faculty_name,
                email,
                mobile,
                subject,
                role,
                is_active,
                created_at

            FROM faculty

            WHERE id=$1
            `,

            [id]

        );

        if (result.rows.length === 0) {

            return res.status(404).json({

                success: false,
                message: "Faculty not found."

            });

        }

        res.json({

            success: true,
            faculty: result.rows[0]

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
// UPDATE FACULTY
// ==========================================

const updateFaculty = async (req, res) => {

    try {

        const { id } = req.params;

        const {

            employee_id,
            faculty_name,
            email,
            mobile,
            subject,
            role,
            is_active

        } = req.body;

        const checkFaculty = await db.query(

            "SELECT * FROM faculty WHERE id=$1",

            [id]

        );

        if (checkFaculty.rows.length === 0) {

            return res.status(404).json({

                success: false,
                message: "Faculty not found."

            });

        }

        const result = await db.query(

            `
            UPDATE faculty

            SET

                employee_id = $1,
                faculty_name = $2,
                email = $3,
                mobile = $4,
                subject = $5,
                role = $6,
                is_active = $7

            WHERE id = $8

            RETURNING

                id,
                employee_id,
                faculty_name,
                email,
                mobile,
                subject,
                role,
                is_active,
                created_at
            `,

            [

                employee_id,
                faculty_name,
                email,
                mobile,
                subject,
                role,
                is_active,
                id

            ]

        );

        res.json({

            success: true,
            message: "Faculty updated successfully.",
            faculty: result.rows[0]

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
// DELETE FACULTY
// ==========================================

const deleteFaculty = async (req, res) => {

    try {

        const { id } = req.params;

        const checkFaculty = await db.query(

            "SELECT * FROM faculty WHERE id=$1",

            [id]

        );

        if (checkFaculty.rows.length === 0) {

            return res.status(404).json({

                success: false,
                message: "Faculty not found."

            });

        }

        await db.query(

            "DELETE FROM faculty WHERE id=$1",

            [id]

        );

        res.json({

            success: true,
            message: "Faculty deleted successfully."

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
// GET FACULTY PROFILE
// ==========================================

const getFacultyProfile = async (req, res) => {

    try {

        const id = req.user.id;

        const result = await db.query(

            `
            SELECT

                id,
                employee_id,
                faculty_name,
                email,
                mobile,
                subject,
                role,
                is_active,
                created_at

            FROM faculty

            WHERE id = $1
            `,

            [id]

        );

        if (result.rows.length === 0) {

            return res.status(404).json({

                success: false,
                message: "Faculty not found."

            });

        }

        res.json({

            success: true,
            faculty: result.rows[0]

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
// EXPORTS
// ==========================================

module.exports = {

    createFaculty,
    getAllFaculty,
    getFacultyById,
    updateFaculty,
    deleteFaculty,
    getFacultyProfile

};