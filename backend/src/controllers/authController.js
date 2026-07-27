// Module 3 Authentication & Security - Authentication Controller

const db = require("../config/db");
const bcrypt = require("bcrypt");
const generateToken = require("../utils/jwt");
const otpService = require("../services/otpService");
const { sendResetPasswordEmail } = require("../services/emailService");
const jwt = require("jsonwebtoken");

// ==========================================
// ADMIN LOGIN
// ==========================================
const adminLogin = async (req, res, next) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: "Email and Password are required."
            });
        }

        const result = await db.query(
            "SELECT * FROM public.admins WHERE email = $1",
            [email]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: "Invalid Email or Password"
            });
        }

        const admin = result.rows[0];
        const validPassword = await bcrypt.compare(password, admin.password_hash);

        if (!validPassword) {
            return res.status(401).json({
                success: false,
                message: "Invalid Email or Password"
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
    } catch (error) {
        next(error);
    }
};

// ==========================================
// FACULTY LOGIN
// ==========================================
const facultyLogin = async (req, res, next) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: "Email and Password are required."
            });
        }

        const result = await db.query(
            "SELECT * FROM public.faculty WHERE email = $1",
            [email]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: "Invalid Email or Password"
            });
        }

        const faculty = result.rows[0];

        if (!faculty.is_active) {
            return res.status(403).json({
                success: false,
                message: "Faculty account is disabled. Contact Admin."
            });
        }

        const validPassword = await bcrypt.compare(password, faculty.password_hash);

        if (!validPassword) {
            return res.status(401).json({
                success: false,
                message: "Invalid Email or Password"
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
    } catch (error) {
        next(error);
    }
};

// ==========================================
// PARENT SEND OTP
// ==========================================
const parentSendOTP = async (req, res, next) => {
    try {
        const { mobile } = req.body;

        if (!mobile) {
            return res.status(400).json({
                success: false,
                message: "Mobile number is required."
            });
        }

        // Verify if mobile matches primary or secondary parent mobile of any student
        const result = await db.query(
            `SELECT id FROM public.students 
             WHERE primary_parent_mobile = $1 OR secondary_parent_mobile = $1`,
            [mobile]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Mobile number is not registered."
            });
        }

        // Generate secure OTP using otpService
        const otp = await otpService.generateOTP(mobile);

        // Print to console for development/demo testing
        console.log("");
        console.log("====================================");
        console.log("PARENT OTP GENERATED (SECURE)");
        console.log("====================================");
        console.log("Mobile :", mobile);
        console.log("OTP    :", otp);
        console.log("====================================");
        console.log("");

        res.status(200).json({
            success: true,
            message: "OTP sent successfully."
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// PARENT VERIFY OTP (Multi-child Support)
// ==========================================
const parentVerifyOTP = async (req, res, next) => {
    try {
        const { mobile, otp } = req.body;

        if (!mobile || !otp) {
            return res.status(400).json({
                success: false,
                message: "Mobile number and OTP are required."
            });
        }

        // Verify OTP via otpService
        const verification = await otpService.verifyOTP(mobile, otp);
        if (!verification.success) {
            return res.status(400).json({
                success: false,
                message: verification.message
            });
        }

        // Retrieve all student mappings associated with the parent's phone number
        const result = await db.query(
            `SELECT s.*, scm.id as student_class_mapping_id, scm.class_id, scm.academic_year_id 
             FROM public.students s
             LEFT JOIN public.student_class_mapping scm 
                ON s.id = scm.student_id AND scm.is_current = true
             WHERE s.primary_parent_mobile = $1 OR s.secondary_parent_mobile = $1`,
            [mobile]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "No registered students found for this mobile number."
            });
        }

        const students = result.rows;
        // Default to the first student in the list for initial compatibility
        const primaryStudent = students[0];

        // Generate parent token
        const token = generateToken({
            id: primaryStudent.id, // compatibility with single-child checks
            student_class_mapping_id: primaryStudent.student_class_mapping_id,
            role: "PARENT",
            mobile: mobile,
            student_ids: students.map(s => s.id)
        });

        res.status(200).json({
            success: true,
            message: "Parent Login Successful",
            token,
            currentStudentId: primaryStudent.id,
            students: students.map(s => ({
                id: s.id,
                student_class_mapping_id: s.student_class_mapping_id,
                admission_no: s.admission_no,
                student_name: s.student_name,
                class_name: s.class_name,
                section: s.section,
                primary_parent_name: s.primary_parent_name,
                primary_parent_mobile: s.primary_parent_mobile
            }))
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// PARENT SWITCH CHILD
// ==========================================
const parentSwitchChild = async (req, res, next) => {
    try {
        const { studentId } = req.body;
        const parentMobile = req.user.mobile; // populated by auth token

        if (!studentId) {
            return res.status(400).json({
                success: false,
                message: "Student ID is required."
            });
        }

        // Verify if selected student belongs to the parent mobile
        const result = await db.query(
            `SELECT s.*, scm.id as student_class_mapping_id, scm.class_id, scm.academic_year_id 
             FROM public.students s
             LEFT JOIN public.student_class_mapping scm 
                ON s.id = scm.student_id AND scm.is_current = true
             WHERE s.id = $1 AND (s.primary_parent_mobile = $2 OR s.secondary_parent_mobile = $2)`,
            [studentId, parentMobile]
        );

        if (result.rows.length === 0) {
            return res.status(403).json({
                success: false,
                message: "Access denied. Student not associated with this parent."
            });
        }

        const student = result.rows[0];

        // Retrieve full list of child IDs to rebuild payload
        const allChildren = await db.query(
            `SELECT id FROM public.students 
             WHERE primary_parent_mobile = $1 OR secondary_parent_mobile = $1`,
            [parentMobile]
        );

        const newToken = generateToken({
            id: student.id,
            student_class_mapping_id: student.student_class_mapping_id,
            role: "PARENT",
            mobile: parentMobile,
            student_ids: allChildren.rows.map(r => r.id)
        });

        res.status(200).json({
            success: true,
            message: `Switched view to student: ${student.student_name}`,
            token: newToken,
            student: {
                id: student.id,
                student_class_mapping_id: student.student_class_mapping_id,
                admission_no: student.admission_no,
                student_name: student.student_name,
                class_name: student.class_name,
                section: student.section,
                primary_parent_name: student.primary_parent_name,
                primary_parent_mobile: student.primary_parent_mobile
            }
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// FACULTY FORGOT PASSWORD (Email Verification)
// ==========================================
const facultyForgotPassword = async (req, res, next) => {
    try {
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({
                success: false,
                message: "Email is required."
            });
        }

        const result = await db.query(
            "SELECT id, faculty_name FROM public.faculty WHERE email = $1",
            [email]
        );

        if (result.rows.length === 0) {
            // Standard security practice: return success even if email not found to prevent user enumeration
            return res.status(200).json({
                success: true,
                message: "If the email is registered, a password reset link has been sent."
            });
        }

        const faculty = result.rows[0];

        // Generate short-lived reset token (15 mins)
        const resetToken = jwt.sign(
            { id: faculty.id, role: "FACULTY", type: "password_reset" },
            process.env.JWT_SECRET,
            { expiresIn: "15m" }
        );

        // Standard web reset link (can also be parsed by mobile deep link)
        const resetLink = `http://localhost:${process.env.PORT || 5000}/api/auth/faculty/reset-password?token=${resetToken}`;

        // Send email via emailService
        await sendResetPasswordEmail(email, resetLink);

        res.status(200).json({
            success: true,
            message: "Password reset link sent to registered email address."
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// FACULTY RESET PASSWORD
// ==========================================
const facultyResetPassword = async (req, res, next) => {
    try {
        const token = req.query.token || req.body.token;
        const { password } = req.body;

        if (!token || !password) {
            return res.status(400).json({
                success: false,
                message: "Reset token and new password are required."
            });
        }

        // Verify token validity
        let decoded;
        try {
            decoded = jwt.verify(token, process.env.JWT_SECRET);
        } catch (err) {
            return res.status(400).json({
                success: false,
                message: "Invalid or expired reset token."
            });
        }

        if (decoded.role !== "FACULTY" || decoded.type !== "password_reset") {
            return res.status(400).json({
                success: false,
                message: "Invalid token payload."
            });
        }

        // Hash new password
        const password_hash = await bcrypt.hash(password, 10);

        // Update database
        const updateResult = await db.query(
            "UPDATE public.faculty SET password_hash = $1 WHERE id = $2 RETURNING id",
            [password_hash, decoded.id]
        );

        if (updateResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Faculty account not found."
            });
        }

        res.status(200).json({
            success: true,
            message: "Password reset successfully. You can now login with your new credentials."
        });
    } catch (error) {
        next(error);
    }
};

module.exports = {
    adminLogin,
    facultyLogin,
    parentSendOTP,
    parentVerifyOTP,
    parentSwitchChild,
    facultyForgotPassword,
    facultyResetPassword
};