const pool = require("../src/config/db");
const authController = require("../src/controllers/authController");
const otpService = require("../src/services/otpService");

async function testParentOtp() {
    console.log("=== TESTING PARENT OTP & STUDENT LOOKUP ===");

    // 1. Fetch all parent mobile numbers in students table
    const studentsRes = await pool.query(`
        SELECT id, student_name, primary_parent_mobile, secondary_parent_mobile 
        FROM public.students
    `);

    console.log("Registered Parent Mobiles in Database:");
    console.table(studentsRes.rows);

    if (studentsRes.rows.length > 0) {
        const testMobile = studentsRes.rows[0].primary_parent_mobile;
        console.log(`\nTesting Send OTP for registered mobile: ${testMobile}`);
        
        const generatedOtp = await otpService.generateOTP(testMobile);
        console.log(`Generated OTP: ${generatedOtp}`);

        console.log(`\nTesting Verify OTP with generated OTP (${generatedOtp})...`);
        const ver1 = await otpService.verifyOTP(testMobile, generatedOtp);
        console.log("Verification result for generated OTP:", ver1);

        console.log(`\nTesting Verify OTP with demo OTP (123456)...`);
        const ver2 = await otpService.verifyOTP(testMobile, "123456");
        console.log("Verification result for demo OTP (123456):", ver2);
    }

    await pool.end();
}

testParentOtp();
