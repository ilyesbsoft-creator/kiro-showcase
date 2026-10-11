const jwt = require("jsonwebtoken");
const { t } = require("../../core/i18n");

class AuthMiddleware {
  constructor(repo) {
    this.repo = repo;
  }

  // =========================================================
  // 🔐 AUTHENTICATE USER
  // =========================================================

  authenticate = async (req, res, next) => {
    try {
      const authHeader = req.headers.authorization;

      if (!authHeader) {
        return res.status(401).json({
          success: false,
          message: t(req.lang, "AUTH_HEADER_MISSING"),
        });
      }

      const parts = authHeader.split(" ");

      if (parts.length !== 2 || parts[0] !== "Bearer") {
        return res.status(401).json({
          success: false,
          message: t(req.lang, "INVALID_AUTH_FORMAT"),
        });
      }

      const token = parts[1];

      let decoded;

      try {
        decoded = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
      } catch (err) {
        return res.status(401).json({
          success: false,
          message: t(req.lang, "INVALID_OR_EXPIRED_TOKEN"),
        });
      }

      const user = await this.repo.findById(decoded.id);

      if (!user) {
        return res.status(401).json({
          success: false,
          message: t(req.lang, "USER_NOT_FOUND"),
        });
      }

      if (user.status !== "active") {
        return res.status(403).json({
          success: false,
          message: t(req.lang, "ACCOUNT_NOT_ACTIVE"),
        });
      }

      if (
        user.locked_until &&
        new Date(user.locked_until) > new Date()
      ) {
        return res.status(403).json({
          success: false,
          message: t(req.lang, "ACCOUNT_TEMPORARILY_LOCKED"),
        });
      }

      if (user.password_changed_at) {
        const passwordChangedAt = new Date(user.password_changed_at).getTime();
        const tokenIssuedAt = decoded.iat * 1000;

        if (tokenIssuedAt < passwordChangedAt) {
          return res.status(401).json({
            success: false,
            message: t(req.lang, "SESSION_EXPIRED_PASSWORD_CHANGED"),
          });
        }
      }

      if (decoded.sessionId) {
        const sessions = await this.repo.getActiveSessions(user.id);

        const sessionExists = sessions.some(
          (session) => session.session_id === decoded.sessionId
        );

        if (!sessionExists) {
          return res.status(401).json({
            success: false,
            message: t(req.lang, "SESSION_REVOKED_OR_EXPIRED"),
          });
        }
      }

      req.user = user;

      req.token = decoded;

      next();
    } catch (err) {
      return res.status(500).json({
        success: false,
        message: t(req.lang, "AUTH_MIDDLEWARE_ERROR"),
      });
    }
  };

  // =========================================================
  // 🛡️ OPTIONAL ROLE CHECK
  // =========================================================

  requireRole = (...roles) => {
    return (req, res, next) => {
      try {
        next();
      } catch (err) {
        return res.status(403).json({
          success: false,
          message: t(req.lang, "ACCESS_DENIED"),
        });
      }
    };
  };
}

module.exports = AuthMiddleware;