import { z } from "zod";

export const notificationCreateSchema = z.object({
  user_id: z.string().uuid(),
  sender_id: z.string().uuid().optional(),
  title: z.string().max(150).optional(),
  message: z.string().min(1),
  type: z.string().trim().max(50).optional().nullable(),
  entity_type: z.string().trim().max(50).optional().nullable(),
  entity_id: z.number().int().positive().optional().nullable(),
  route: z.string().trim().startsWith("/").max(180).optional().nullable(),
  read: z.boolean().optional(),
});

export const notificationUpdateSchema = z.object({
  read: z.boolean(),
});

export const notificationIdParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export const notificationQuerySchema = z.object({
  limit: z.coerce.number().int().positive().max(100).optional(),
});

export const notificationPaginationSchema = z.object({
  limit: z.coerce.number().int().positive().max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});

export const deviceTokenSchema = z.object({
  token: z.string().trim().min(20),
  platform: z.string().trim().max(20).optional(),
});

export const broadcastSchema = z.object({
  message: z.string().min(1),
  sender_id: z.string().uuid().optional(),
});

export type NotificationCreateInput = z.infer<typeof notificationCreateSchema>;
export type NotificationUpdateInput = z.infer<typeof notificationUpdateSchema>;
export type DeviceTokenInput = z.infer<typeof deviceTokenSchema>;
