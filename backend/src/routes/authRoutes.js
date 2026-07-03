const express = require("express");

const router = express.Router();

const {

    adminLogin,

    facultyLogin,

    parentSendOTP,

    parentVerifyOTP

} = require("../controllers/authController");


// ============================
// ADMIN LOGIN
// ============================

router.post("/admin/login", adminLogin);


// ============================
// FACULTY LOGIN
// ============================

router.post("/faculty/login", facultyLogin);


// ============================
// PARENT LOGIN
// ============================

router.post("/parent/send-otp", parentSendOTP);

router.post("/parent/verify-otp", parentVerifyOTP);


module.exports = router;