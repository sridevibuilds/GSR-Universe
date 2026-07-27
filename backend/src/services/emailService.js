// Module 3 Authentication & Security - Email Service

const nodemailer = require("nodemailer");

/**
 * Sends a password reset verification link to the faculty's email address.
 */
const sendResetPasswordEmail = async (email, resetLink) => {
    try {
        // Mail transporter configuration using environment variables or falling back to a mock ethereal server
        const transporter = nodemailer.createTransport({
            host: process.env.SMTP_HOST || "smtp.ethereal.email",
            port: parseInt(process.env.SMTP_PORT) || 587,
            secure: process.env.SMTP_SECURE === "true",
            auth: {
                user: process.env.SMTP_USER || "mockuser@ethereal.email",
                pass: process.env.SMTP_PASS || "mockpass"
            }
        });

        const mailOptions = {
            from: process.env.SMTP_FROM || '"GSR Universe ERP" <noreply@gsruniverse.com>',
            to: email,
            subject: "Password Reset Request - GSR Universe ERP",
            html: `
                <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 5px; max-width: 600px; margin: 0 auto;">
                    <h2 style="color: #1e3c72; border-bottom: 2px solid #1e3c72; padding-bottom: 10px;">Password Reset Request</h2>
                    <p>Hello,</p>
                    <p>We received a request to reset the password for your Faculty account at GSR Universe ERP.</p>
                    <p>Please click the button below to reset your password. This link is valid for 15 minutes:</p>
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="${resetLink}" target="_blank" style="display: inline-block; background-color: #1e3c72; color: white; padding: 12px 25px; text-decoration: none; border-radius: 5px; font-weight: bold;">Reset Password</a>
                    </div>
                    <p>If you did not request this, please ignore this email or contact the administrator if you suspect unauthorized access.</p>
                    <p style="color: #666; font-size: 12px; margin-top: 40px; border-top: 1px solid #eee; padding-top: 20px;">This is an automated system email. Please do not reply to this message.</p>
                </div>
            `
        };

        // Fallback for development logging
        if (!process.env.SMTP_HOST || process.env.SMTP_HOST === "smtp.ethereal.email") {
            console.log("");
            console.log("====================================");
            console.log("FACULTY PASSWORD RESET EMAIL (MOCK)");
            console.log("====================================");
            console.log("Recipient  :", email);
            console.log("Reset Link :", resetLink);
            console.log("====================================");
            console.log("");
            return true;
        }

        const info = await transporter.sendMail(mailOptions);
        console.log(`Password reset email sent: ${info.messageId}`);
        return true;
    } catch (error) {
        console.error("Nodemailer transport error:", error);
        // Do not block the execution flow for development, but log it
        throw new Error("Unable to send reset email. Contact system administrator.");
    }
};

module.exports = {
    sendResetPasswordEmail
};
