import { z } from "zod";
import { USER_ROLES, USER_STATUS } from "../constants/enums.constants";
import { locationSchema } from "../types/location.type";

export const userCreateSchema = z.object({
  username: z.string().min(3).max(50).toLowerCase(),
  email: z.string().email().toLowerCase(),

  first_name: z.string().max(100).optional().nullable(),
  last_name: z.string().max(100).optional().nullable(),
  phone: z.string().max(20).optional().nullable(),
  ci: z.string().max(20).optional().nullable(),
  address: z.string().max(255).optional().nullable(),
  location: locationSchema.optional().nullable(),

  role: z.enum(USER_ROLES).default("user"),
  status: z.enum(USER_STATUS).default("active"),
});

export const userUpdateSchema = z.object({
  id: z.string().uuid(),

  username: z.string().min(3).max(50).toLowerCase().optional(),
  email: z.string().email().toLowerCase().optional(),

  first_name: z.string().max(100).optional().nullable(),
  last_name: z.string().max(100).optional().nullable(),
  phone: z.string().max(20).optional().nullable(),
  ci: z.string().max(20).optional().nullable(),
  address: z.string().max(255).optional().nullable(),
  location: locationSchema.optional().nullable(),

  role: z.enum(USER_ROLES).optional(),
  status: z.enum(USER_STATUS).optional(),
}).strict();

export const userSelfUpdateSchema = userUpdateSchema
  .omit({
    id: true,
    role: true,
    status: true,
  })
  .strict();

export const userIdSchema = z.object({
  id: z.string().uuid(),
});

export const userBatchSchema = z.object({
  ids: z
    .string()
    .min(1)
    .transform((val) => val.split(",").map((id) => id.trim()))
    .pipe(z.array(z.string().uuid()).min(1).max(100)),
});

export type UserCreateInput = z.infer<typeof userCreateSchema>;
export type UserUpdateInput = z.infer<typeof userUpdateSchema>;
export type UserSelfUpdateInput = z.infer<typeof userSelfUpdateSchema>;
export type UserIdInput = z.infer<typeof userIdSchema>;
export type UserBatchInput = z.infer<typeof userBatchSchema>;
