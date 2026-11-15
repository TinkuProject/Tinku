import { z } from "zod";
import { BASIC_STATUS } from "../constants/enums.constants";

export const createCashoutPackageSchema = z.object({
  name: z.string().min(2).max(50),
  tinkus_amount: z.number().int().positive(),
  cash_amount: z.number().positive(),
  status: z.enum(BASIC_STATUS).optional(),
});

export const updateCashoutPackageSchema = createCashoutPackageSchema.partial();

export const idParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export type CashoutPackageCreateInput = z.infer<typeof createCashoutPackageSchema>;
export type CashoutPackageUpdateInput = z.infer<typeof updateCashoutPackageSchema>;