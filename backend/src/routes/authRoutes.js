const express = require("express");

const router = express.Router();

const {

    adminLogin,

    facultyLogin,

    parentSendOTP,

    parentVerifyOTP,

    parentSwitchChild,

    facultyForgotPassword,

    facultyResetPassword

} = require("../controllers/authController");

const verifyToken = require("../middleware/authMiddleware");


// ============================
// ADMIN LOGIN
// ============================

router.post("/admin/login", adminLogin);


// ============================
// FACULTY LOGIN & PASSWORD RESET
// ============================

router.post("/faculty/login", facultyLogin);

router.post("/faculty/forgot-password", facultyForgotPassword);

router.post("/faculty/reset-password", facultyResetPassword);


// ============================
// PARENT LOGIN & OPERATIONS
// ============================

router.post("/parent/send-otp", parentSendOTP);

router.post("/parent/verify-otp", parentVerifyOTP);

router.post("/parent/switch-child", verifyToken, parentSwitchChild);


module.exports = router;