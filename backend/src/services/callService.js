// Module 8 Automated Fee Reminders - Call Service Abstraction Gateway

const twilioCall = require("./providers/twilioProvider");

// Provider dictionary registry for easy extension (e.g. Exotel/Plivo)
const providers = {
    twilio: twilioCall
};

/**
 * Initiates an outbound reminder call using the selected provider.
 * 
 * @param {string} to Destination parent mobile number
 * @param {string} studentName Name of student with pending fee
 * @param {number} amountDue Pending balance amount
 * @param {string} providerType Provider label ('twilio')
 * @param {object} config Provider credentials mapping
 */
const initiateFeeReminderCall = async (to, studentName, amountDue, providerType = "twilio", config = {}) => {
    const selectedProvider = providers[providerType.toLowerCase()];
    
    if (!selectedProvider) {
        throw new Error(`Unsupported calling provider type: '${providerType}'`);
    }

    return await selectedProvider(to, studentName, amountDue, config);
};

module.exports = {
    initiateFeeReminderCall
};
