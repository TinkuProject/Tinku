import { z } from "zod";

export const createPermissionSchema = z.object({
  code: z.string().min(2).max(100),
  description: z.string().optional().nullable(),
});

export const updatePermissionSchema = z.object({
  description: z.string().optional().nullable(),
});

export const idParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export const codeParamSchema = z.object({
  code: z.string().min(1),
});

export type PermissionCreateInput = z.infer<typeof createPermissionSchema>;
export type PermissionUpdateInput = z.infer<typeof updatePermissionSchema>;