import { z } from "zod";

export const createAuditLogSchema = z.object({
  user_id: z.string().uuid(),
  action: z.string().min(1),
  entity_type: z.string().min(1),
  entity_id: z.number().int().optional().nullable(),
  details: z.record(z.string(), z.unknown()).optional().nullable(),
});

export const auditLogFilterSchema = z.object({
  user_id: z.string().uuid().optional(),
  entity_type: z.string().min(1).optional(),
  entity_id: z.coerce.number().int().positive().optional(),
  action: z.string().min(1).optional(),
  limit: z.coerce.number().int().positive().optional(),
  offset: z.coerce.number().int().min(0).optional(),
});

export const auditLogByUserSchema = z.object({
  user_id: z.string().uuid(),
  limit: z.coerce.number().int().positive().optional(),
  offset: z.coerce.number().int().min(0).optional(),
});

export const auditLogByEntitySchema = z.object({
  entity_type: z.string().min(1),
  entity_id: z.coerce.number().int().positive(),
});

export const auditLogIdParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export const paginationSchema = z.object({
  limit: z.coerce.number().int().positive().optional(),
  offset: z.coerce.number().int().min(0).optional(),
});

export type AuditLogFilterInput = z.infer<typeof auditLogFilterSchema>;
export type AuditLogCreateInput = z.infer<typeof createAuditLogSchema>;
export type AuditLogByUserInput = z.infer<typeof auditLogByUserSchema>;
export type AuditLogByEntityInput = z.infer<typeof auditLogByEntitySchema>;