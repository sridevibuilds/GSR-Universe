const db = require("../config/db");
const bcrypt = require("bcrypt");
const generateToken = require("../utils/jwt");
const otpStore = require("../utils/otpStore");

// ==========================================
// ADMIN LOGIN
// ==========================================

const adminLogin = async (req, res) => {

    try {

        const { email, password } = req.body;

        if (!email || !password) {

            return res.status(400).json({

                success: false,
                message: "Email and Password are required."

            });

        }

        const result = await db.query(

            "SELECT * FROM admins WHERE email = $1",

            [email]

        );

        if (result.rows.length === 0) {

            return res.status(401).json({

                success: false,
                message: "Invalid Email"

            });

        }

        const admin = result.rows[0];

        const validPassword = await bcrypt.compare(

            password,

            admin.password_hash

        );

        if (!validPassword) {

            return res.status(401).json({

                success: false,
                message: "Invalid Password"

            });

        }

        const token = generateToken({

            id: admin.id,
            role: "ADMIN"

        });

        res.status(200).json({

            success: true,
            message: "Admin Login Successful",
            token,

            admin: {

                id: admin.id,
                admin_name: admin.admin_name,
                email: admin.email

            }

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
// FACULTY LOGIN
// ==========================================

const facultyLogin = async (req, res) => {

    try {

        const { email, password } = req.body;

        if (!email || !password) {

            return res.status(400).json({

                success: false,
                message: "Email and Password are required."

            });

        }

        const result = await db.query(

            "SELECT * FROM faculty WHERE email = $1",

            [email]

        );

        if (result.rows.length === 0) {

            return res.status(401).json({

                success: false,
                message: "Invalid Email"

            });

        }

        const faculty = result.rows[0];

        if (!faculty.is_active) {

            return res.status(403).json({

                success: false,
                message: "Faculty account is disabled."

            });

        }

        const validPassword = await bcrypt.compare(

            password,

            faculty.password_hash

        );

        if (!validPassword) {

            return res.status(401).json({

                success: false,
                message: "Invalid Password"

            });

        }

        const token = generateToken({

            id: faculty.id,
            role: "FACULTY"

        });

        res.status(200).json({

            success: true,
            message: "Faculty Login Successful",
            token,

            faculty: {

                id: faculty.id,
                employee_id: faculty.employee_id,
                faculty_name: faculty.faculty_name,
                email: faculty.email,
                subject: faculty.subject,
                role: faculty.role

            }

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
// PARENT SEND OTP (Demo)
// ==========================================

const parentSendOTP = async (req, res) => {

    try {

        const { mobile } = req.body;

        if (!mobile) {

            return res.status(400).json({

                success: false,
                message: "Mobile number is required."

            });

        }

        const result = await db.query(

            `SELECT *
             FROM students
             WHERE primary_parent_mobile = $1
                OR secondary_parent_mobile = $1`,

            [mobile]

        );

        if (result.rows.length === 0) {

            return res.status(404).json({

                success: false,
                message: "Mobile number not registered."

            });

        }

        const otp = "123456";

        otpStore.set(mobile, otp);

        console.log("");
        console.log("====================================");
        console.log("PARENT DEMO OTP");
        console.log("====================================");
        console.log("Mobile :", mobile);
        console.log("OTP    :", otp);
        console.log("====================================");
        console.log("");

        res.status(200).json({

            success: true,
            message: "OTP Generated Successfully"

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
// VERIFY OTP
// ==========================================

const parentVerifyOTP = async (req, res) => {

    try {

        const { mobile, otp } = req.body;

        if (!mobile || !otp) {

            return res.status(400).json({

                success: false,
                message: "Mobile number and OTP are required."

            });

        }

        const savedOTP = otpStore.get(mobile);

        if (!savedOTP) {

            return res.status(400).json({

                success: false,
                message: "OTP Expired"

            });

        }

        if (savedOTP !== otp) {

            return res.status(400).json({

                success: false,
                message: "Invalid OTP"

            });

        }

        const result = await db.query(

            `SELECT *
             FROM students
             WHERE primary_parent_mobile = $1
                OR secondary_parent_mobile = $1`,

            [mobile]

        );

        const student = result.rows[0];

        const token = generateToken({

            id: student.id,
            role: "PARENT"

        });

        otpStore.delete(mobile);

        res.status(200).json({

            success: true,
            message: "Parent Login Successful",
            token,

            student: {

                id: student.id,
                admission_no: student.admission_no,
                student_name: student.student_name,
                class_name: student.class_name,
                section: student.section,
                primary_parent_name: student.primary_parent_name,
                primary_parent_mobile: student.primary_parent_mobile

            }

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

    adminLogin,
    facultyLogin,
    parentSendOTP,
    parentVerifyOTP

};