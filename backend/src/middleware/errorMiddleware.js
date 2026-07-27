// Module 2 Base Backend Architecture & Security - Error Handler Middleware

const errorHandler = (err, req, res, next) => {
    const statusCode = err.statusCode || 500;
    const message = err.message || "Internal Server Error";

    // Log error stack trace internally
    console.error(`[Error] ${req.method} ${req.url} - Status ${statusCode} - ${message}`);
    if (statusCode === 500 || err.stack) {
        console.error(err.stack || err);
    }

    res.status(statusCode).json({
        success: false,
        message: statusCode === 500 ? "An unexpected server error occurred." : message,
        ...(process.env.NODE_ENV === "development" && { stack: err.stack })
    });
};

module.exports = errorHandler;
