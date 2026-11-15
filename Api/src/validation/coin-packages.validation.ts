import { z } from "zod";
import { BASIC_STATUS } from "../constants/enums.constants";

export const createCoinPackageSchema = z.object({
  name: z.string().min(2).max(50),
  tinkus_amount: z.number().int().positive(),
  cash_amount: z.number().positive(),
});

export const updateCoinPackageSchema = z
  .object({
    name: z.string().min(2).max(50).optional(),
    tinkus_amount: z.number().int().positive().optional(),
    cash_amount: z.number().positive().optional(),
    status: z.enum(BASIC_STATUS).optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: "At least one field must be provided",
  });

export const coinPackageIdParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export const coinPackageFilterSchema = z.object({
  status: z.enum(BASIC_STATUS).optional(),
});

export type CoinPackageCreateInput = z.infer<typeof createCoinPackageSchema>;
export type CoinPackageUpdateInput = z.infer<typeof updateCoinPackageSchema>;
export type CoinPackageIdParam = z.infer<typeof coinPackageIdParamSchema>;
export type CoinPackageFilter = z.infer<typeof coinPackageFilterSchema>;