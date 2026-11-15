import { Router } from "express";
import { AuthController } from "../controllers/auth.controller";
import { authMiddleware } from "../middlewares/auth.middleware";

const router = Router();

/**
 * =========================
 * REGISTER
 * =========================
 * POST /auth/register
 *
 * Body (JSON):
 * {
 *   "email": "test@example.com",
 *   "password": "Secret123!",
 *   "first_name": "John",
 *   "last_name": "Doe",
 *   "username": "johndoe",
 *   "location": {
 *     "coordinates": [-66.1653, -17.4139]
 *   }
 * }
 */
router.post("/register", AuthController.register);

/**
 * =========================
 * LOGIN
 * =========================
 * POST /auth/login
 *
 * Body (JSON):
 * {
 *   "email": "test@example.com", // también acepta username
 *   "password": "Secret123!"
 * }
 */
router.post("/login", AuthController.login);

/**
 * =========================
 * GOOGLE LOGIN
 * =========================
 * POST /auth/google
 *
 * Body (JSON):
 * {
 *   "id_token": "<google_id_token>",
 *   "email": "user@gmail.com"
 * }
 */
router.post("/google", AuthController.loginWithGoogle);

/**
 * =========================
 * REFRESH TOKEN
 * =========================
 * POST /auth/refresh
 *
 * Body (JSON):
 * {
 *   "refresh_token": "<refresh_token>"
 * }
 */
router.post("/refresh", AuthController.refreshToken);

/**
 * =========================
 * EMAIL VERIFICATION CODE
 * =========================
 */
router.post(
  "/email/verification-code",
  AuthController.requestEmailVerificationCode
);

router.post(
  "/email/verify-code",
  AuthController.verifyEmailCode
);

/**
 * =========================
 * PASSWORD RECOVERY CODE
 * =========================
 */
router.post(
  "/password/recovery-code",
  AuthController.requestPasswordRecoveryCode
);

router.post(
  "/password/reset-with-code",
  AuthController.resetPasswordWithCode
);

/**
 * =========================
 * LOGOUT
 * =========================
 * POST /auth/logout
 *
 * Nota:
 * Logout invalida el refresh token cuando el cliente lo envia.
 */
router.post("/logout", AuthController.logout);

/**
 * =========================
 * CHANGE PASSWORD
 * =========================
 * POST /auth/change-password
 *
 * Headers:
 * Authorization: Bearer <access_token>
 *
 * Body (JSON):
 * {
 *   "current_password": "OldPass123!",
 *   "new_password": "NewPass123!"
 * }
 */
router.post("/change-password", authMiddleware, AuthController.changePassword);
router.post("/email/change-code", authMiddleware, AuthController.requestEmailChange);
router.post("/email/change", authMiddleware, AuthController.confirmEmailChange);

/**
 * =========================
 * CURRENT USER
 * =========================
 * GET /auth/me
 *
 * Headers:
 * Authorization: Bearer <access_token>
 */
router.get("/me", authMiddleware, AuthController.getCurrentUser);

export default router;
