const db = require("../config/db");
const bcrypt = require("bcrypt");
const generateToken = require("../utils/jwt");

// ----------------------
// Admin Login
// ----------------------
const adminLogin = async (req, res) => {

    try {

        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: "Email and Password are required"
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

        const isMatch = await bcrypt.compare(
            password,
            admin.password_hash
        );

        if (!isMatch) {
            return res.status(401).json({
                success: false,
                message: "Invalid Password"
            });
        }

        const token = generateToken({
            id: admin.id,
            role: "admin"
        });

        res.json({
            success: true,
            message: "Login Successful",
            token,
            admin: {
                id: admin.id,
                admin_name: admin.admin_name,
                email: admin.email
            }
        });

    } catch (error) {

        console.log(error);

        res.status(500).json({
            success: false,
            message: "Server Error"
        });

    }

};

module.exports = {
    adminLogin
};