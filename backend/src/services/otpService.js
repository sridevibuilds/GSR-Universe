// Module 3 Authentication & Security - OTP Service

const db = require("../config/db");
const crypto = require("crypto");

/**
 * Hash an OTP using SHA-256
 */
const hashOTP = (otp) => {
    return crypto.createHash("sha256").update(otp).digest("hex");
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
    const expires_at = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes expiry

    // Delete older OTPs for this mobile to keep DB clean
    await db.query("DELETE FROM public.otps WHERE mobile = $1", [mobile]);

    // Insert new OTP record
    await db.query(
        `INSERT INTO public.otps (mobile, otp_hash, expires_at, attempts, is_verified)
         VALUES ($1, $2, $3, 0, false)`,
        [mobile, otp_hash, expires_at]
    );

    return otpVal;
};

/**
 * Verify if the submitted OTP matches the latest valid record in the database.
 */
const verifyOTP = async (mobile, otp) => {
    const result = await db.query(
        `SELECT * FROM public.otps 
         WHERE mobile = $1 AND is_verified = false AND expires_at > NOW() 
         ORDER BY id DESC LIMIT 1`,
        [mobile]
    );

    if (result.rows.length === 0) {
        return {
            success: false,
            message: "OTP expired or not found. Please request a new one."
        };
    }

    const record = result.rows[0];

    // Lockout after 3 failed attempts
    if (record.attempts >= 3) {
        return {
            success: false,
            message: "Too many incorrect attempts. Please generate a new OTP."
        };
    }

    const inputHash = hashOTP(otp);
    if (record.otp_hash !== inputHash) {
        // Increment attempts on failure
        await db.query("UPDATE public.otps SET attempts = attempts + 1 WHERE id = $1", [record.id]);
        return {
            success: false,
            message: `Invalid OTP. ${2 - record.attempts} attempts remaining.`
        };
    }

    // Mark as verified
    await db.query("UPDATE public.otps SET is_verified = true WHERE id = $1", [record.id]);
    return {
        success: true
    };
};

module.exports = {
    generateOTP,
    verifyOTP
};
