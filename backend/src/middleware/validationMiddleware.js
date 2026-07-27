// Module 2 Base Backend Architecture & Security - Joi Validation Middleware

const validateRequest = (schema, source = "body") => {
    return (req, res, next) => {
        const { error, value } = schema.validate(req[source], {
            abortEarly: false,
            stripUnknown: true // strip unexpected properties to prevent parameter pollution
        });

        if (error) {
            const errorMessage = error.details.map((detail) => detail.message).join(", ");
            return res.status(400).json({
                success: false,
                message: `Validation Error: ${errorMessage}`
            });
        }

        // Replace raw input with validated and sanitized values
        req[source] = value;
        next();
    };
};

module.exports = validateRequest;
