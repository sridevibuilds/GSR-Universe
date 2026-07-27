// Module 8 Automated Fee Reminders - Twilio Caller Provider

/**
 * Initiates an outbound IVR voice call via Twilio REST API.
 * Falls back to mock execution logging if parameters are not configured.
 */
const twilioCall = async (to, studentName, amountDue, config = {}) => {
    const accountSid = config.twilio_account_sid || process.env.TWILIO_ACCOUNT_SID;
    const authToken = config.twilio_auth_token || process.env.TWILIO_AUTH_TOKEN;
    const from = config.calling_number || process.env.TWILIO_CALLER_ID;

    // Standardize phone format (remove spaces, ensure leading + country code)
    let formattedTo = to.trim();
    if (!formattedTo.startsWith("+")) {
        // Assume Indian country code by default if 10 digits
        if (formattedTo.length === 10) {
            formattedTo = "+91" + formattedTo;
        } else {
            formattedTo = "+" + formattedTo;
        }
    }

    // Mock execution fallback if configuration details are blank
    if (!accountSid || !authToken || !from || accountSid.includes("YOUR_") || authToken.includes("YOUR_")) {
        console.log("");
        console.log("====================================");
        console.log("TWILIO OUTBOUND VOICE CALL (MOCK)");
        console.log("====================================");
        console.log("To         :", formattedTo);
        console.log("From       :", from || "[System Mock]");
        console.log("Student    :", studentName);
        console.log("Pending Fee:", amountDue);
        console.log("Status     : Simulated Call Completed");
        console.log("====================================");
        console.log("");
        return {
            success: true,
            callSid: `mock_sid_${Math.floor(100000000 + Math.random() * 900000000)}`
        };
    }

    try {
        // Construct standard TwiML voice instruction
        const twimlText = `<Response><Say voice="alice">Hello, this is a fee payment reminder from GSR Universe. The fees for student ${studentName} are pending. The outstanding amount is ${amountDue} rupees. Please clear the payment at your earliest convenience. Thank you.</Say></Response>`;
        
        const url = `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Calls.json`;
        const authHeader = "Basic " + Buffer.from(`${accountSid}:${authToken}`).toString("base64");

        const formBody = new URLSearchParams();
        formBody.append("To", formattedTo);
        formBody.append("From", from);
        formBody.append("Twiml", twimlText);

        const response = await fetch(url, {
            method: "POST",
            headers: {
                "Authorization": authHeader,
                "Content-Type": "application/x-www-form-urlencoded"
            },
            body: formBody.toString()
        });

        const data = await response.json();
        
        if (!response.ok) {
            console.error("Twilio API error response:", data);
            throw new Error(data.message || `HTTP error ${response.status}`);
        }

        return {
            success: true,
            callSid: data.sid
        };
    } catch (error) {
        console.error("Twilio provider dispatch failed:", error);
        throw error;
    }
};

module.exports = twilioCall;
