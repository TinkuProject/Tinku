import { Request, Response } from "express";
import { AuthService } from "../services/auth.service";
import {
  registerSchema,
  loginSchema,
  googleSchema,
  refreshSchema,
  changePasswordSchema,
  requestAuthCodeSchema,
  verifyEmailCodeSchema,
  resetPasswordWithCodeSchema,
} from "../validation/auth.validation";
import { handleError } from "../utils/handleError";

export class AuthController {
  static async register(req: Request, res: Response) {
    try {
      const data = registerSchema.parse(req.body);
      const result = await AuthService.register(data, req.ip);
      return res.status(201).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  }

  static async login(req: Request, res: Response) {
    try {
      const data = loginSchema.parse(req.body);
      const result = await AuthService.login(data);
      return res.status(200).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  }

  static async loginWithGoogle(req: Request, res: Response) {
    try {
      const data = googleSchema.parse(req.body);
      const result = await AuthService.loginWithGoogle(data);
      return res.status(200).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  }

  static async refreshToken(req: Request, res: Response) {
    try {
      const data = refreshSchema.parse(req.body);
      const result = await AuthService.refreshToken(data);
      return res.status(200).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  }

  static async changePassword(req: Request, res: Response) {
    try {
      if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const data = changePasswordSchema.parse(req.body);

      const result = await AuthService.changePassword(req.user.id, data);

      return res.status(200).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  }

  static async requestEmailVerificationCode(req: Request, res: Response) {
    try {
      const data = requestAuthCodeSchema.parse(req.body);
      const result = await AuthService.requestEmailVerificationCode(
        data,
        req.ip
      );
      return res.status(200).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  }

  static async requestEmailChange(req: Request, res: Response) {
    try {
      const data = requestAuthCodeSchema.parse(req.body);
      res.json(await AuthService.requestEmailChange(req.user!.id, data, req.ip));
    } catch (error) { handleError(res, error, req); }
  }

  static async confirmEmailChange(req: Request, res: Response) {
    try {
      const data = verifyEmailCodeSchema.parse(req.body);
      res.json(await AuthService.confirmEmailChange(req.user!.id, data));
    } catch (error) { handleError(res, error, req); }
  }

  static async verifyEmailCode(req: Request, res: Response) {
    try {
      const data = verifyEmailCodeSchema.parse(req.body);
      const result = await AuthService.verifyEmailCode(data);
      return res.status(200).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  }

  static async requestPasswordRecoveryCode(req: Request, res: Response) {
    try {
      const data = requestAuthCodeSchema.parse(req.body);
      const result = await AuthService.requestPasswordRecoveryCode(
        data,
        req.ip
      );
      return res.status(200).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  }

  static async resetPasswordWithCode(req: Request, res: Response) {
    try {
      const data = resetPasswordWithCodeSchema.parse(req.body);
      const result = await AuthService.resetPasswordWithCode(data);
      return res.status(200).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  }

  static async getCurrentUser(req: Request, res: Response) {
    try {
      if (!req.user) {
        return res.status(401).json({ message: "Unauthorized" });
      }

      const result = await AuthService.getCurrentUser(req.user.id);

      return res.status(200).json({
        ...req.user,
        profile: result,
      });
    } catch (err) {
      return handleError(res, err);
    }
  }

  static async logout(req: Request, res: Response) {
    try {
      const refreshToken =
        typeof req.body?.refresh_token === "string"
          ? req.body.refresh_token
          : undefined;

      const result = await AuthService.logout(refreshToken);
      return res.status(200).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  }
}
