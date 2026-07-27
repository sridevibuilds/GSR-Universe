const roleMiddleware = (...allowedRoles) => {
    const normalizedAllowed = allowedRoles.map(r => String(r).toUpperCase());

    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({
                success: false,
                message: "Unauthorized"
            });
        }

        const userRole = String(req.user.role || '').toUpperCase();
        if (!normalizedAllowed.includes(userRole)) {
            return res.status(403).json({
                success: false,
                message: "Access Denied"
            });
        }

        next();
    };
};

module.exports = roleMiddleware;