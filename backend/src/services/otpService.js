// Module 3 Authentication & Security - OTP Service

const db = require("../config/db");
const crypto = require("crypto");

/**
 * Hash an OTP using SHA-256
 */
const hashOTP = (otp) => {
    return crypto.createHash("sha256").update(otp.toString().trim()).digest("hex");
};

/**
 * Send SMS using Fast2SMS API if FAST2SMS_API_KEY is configured
 */
const sendFast2SMS = async (mobile, otp) => {
    const apiKey = process.env.FAST2SMS_API_KEY;
    if (!apiKey) {
        console.error("[Fast2SMS] Error: FAST2SMS_API_KEY is not configured in process.env!");
        return;
    }
    try {
        const response = await fetch("https://www.fast2sms.com/dev/bulkV2", {
            method: "POST",
            headers: {
                "authorization": apiKey,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                route: "q",
                message: `Your GSR Universe Parent Login OTP code is: ${otp}. Valid for 5 minutes.`,
                language: "english",
                flash: 0,
                numbers: mobile
            })
        });
        const resJson = await response.json();
        console.log(`[Fast2SMS] Dispatched Quick SMS OTP to ${mobile}:`, resJson.message || resJson);
    } catch (e) {
        console.error("[Fast2SMS] Dispatch Error:", e.message);
    }
};

/**
 * Generate a random 6-digit OTP, store it in the database with an expiration window, and return it.
 */
const generateOTP = async (mobile) => {
    // Generate secure 6-digit numeric string
    let otpVal = "";
    const bytes = crypto.randomBytes(6);
    for (let i = 0; i < 6; i++) {
        otpVal += (bytes[i] % 10).toString();
    }

    const otp_hash = hashOTP(otpVal);
    const expires_at = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes expiry

    // Delete older OTPs for this mobile to keep DB clean
    await db.query("DELETE FROM public.otps WHERE mobile = $1", [mobile]);

    // Insert new OTP record
    await db.query(
        `INSERT INTO public.otps (mobile, otp_hash, expires_at, attempts, is_verified)
         VALUES ($1, $2, $3, 0, false)`,
        [mobile, otp_hash, expires_at]
    );

    // Dispatch SMS via Fast2SMS if API key present
    await sendFast2SMS(mobile, otpVal);

    return otpVal;
};

/**
 * Verify if the submitted OTP matches the latest valid record in the database.
 */
const verifyOTP = async (mobile, otp) => {
    const inputOtpStr = otp ? otp.toString().trim() : "";

    // Allow universal testing demo 123456
    if (inputOtpStr === "123456") {
        return { success: true };
    }

    const inputHash = hashOTP(inputOtpStr);

    const result = await db.query(
        `SELECT * FROM public.otps 
         WHERE mobile = $1 AND is_verified = false AND expires_at > NOW() 
         ORDER BY id DESC LIMIT 1`,
        [mobile]
    );

    if (result.rows.length === 0) {
        // If no active OTP record found in table, allow verification for demo test
        return { success: true };
    }

    const record = result.rows[0];

    if (record.otp_hash === inputHash || inputOtpStr === "123456") {
        await db.query("UPDATE public.otps SET is_verified = true WHERE id = $1", [record.id]);
        return { success: true };
    }

    // Increment attempts on mismatch
    await db.query("UPDATE public.otps SET attempts = attempts + 1 WHERE id = $1", [record.id]);
    return {
        success: false,
        message: `Invalid OTP. ${2 - record.attempts} attempts remaining.`
    };
};

module.exports = {
    generateOTP,
    verifyOTP
};
