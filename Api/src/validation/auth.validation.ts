import { z } from "zod";
import { USER_ROLES, USER_STATUS } from "../constants/enums.constants";

const passwordSchema = z
  .string()
  .min(8, "Password too short")
  .regex(/[A-Z]/, "Must include uppercase")
  .regex(/[0-9]/, "Must include number");

const emailSchema = z
  .string()
  .trim()
  .email("Invalid email");

export const registerSchema = z.object({
  email: emailSchema,
  password: passwordSchema,
  first_name: z.string().trim().min(1).optional(),
  last_name: z.string().trim().min(1).optional(),
  username: z.string()
    .trim()
    .min(3)
    .max(20)
    .regex(/^[a-zA-Z0-9_]+$/, "Invalid username")
    .optional(),
  location: z
    .object({
      coordinates: z.tuple([
        z.number().min(-180).max(180),
        z.number().min(-90).max(90),
      ]),
    })
    .optional(),
}).strict();

export const loginSchema = z.object({
  email: emailSchema.optional(),
  username: z.string().trim().optional(),
  password: passwordSchema,
})
  .refine(
    (data) => !!(data.email || data.username),
    { message: "Email or username is required" }
  )
  .refine(
    (data) => !(data.email && data.username),
    { message: "Provide either email or username, not both" }
  )
  .strict();

export const refreshSchema = z.object({
  refresh_token: z.string().min(1, "Refresh token required"),
}).strict();

export const changePasswordSchema = z.object({
  current_password: z.string().min(1, "Current password required"),
  new_password: passwordSchema,
}).strict();

export const adminCreateUserSchema = registerSchema.extend({
  role: z.enum(USER_ROLES),
  status: z.enum(USER_STATUS).optional(),
  email_verified: z.boolean().optional(),
});

export const requestAuthCodeSchema = z.object({
  email: emailSchema,
}).strict();

export const verifyEmailCodeSchema = z.object({
  email: emailSchema,
  code: z.string().trim().regex(/^\d{6}$/, "Code must have 6 digits"),
}).strict();

export const resetPasswordWithCodeSchema = z.object({
  email: emailSchema,
  code: z.string().trim().regex(/^\d{6}$/, "Code must have 6 digits"),
  new_password: passwordSchema,
}).strict();

export const googleSchema = z.object({
  id_token: z.string().min(1, "ID token required"),
  email: emailSchema,
}).strict();


export type RegisterDTO = z.infer<typeof registerSchema>;
export type AdminCreateUserDTO = z.infer<typeof adminCreateUserSchema>;
export type LoginDTO = z.infer<typeof loginSchema>;
export type RefreshTokenDTO = z.infer<typeof refreshSchema>;
export type ChangePasswordDTO = z.infer<typeof changePasswordSchema>;
export type RequestAuthCodeDTO = z.infer<typeof requestAuthCodeSchema>;
export type VerifyEmailCodeDTO = z.infer<typeof verifyEmailCodeSchema>;
export type ResetPasswordWithCodeDTO = z.infer<typeof resetPasswordWithCodeSchema>;
export type GoogleLoginDTO = z.infer<typeof googleSchema>;
