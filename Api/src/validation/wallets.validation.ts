import { z } from "zod";

export const walletUserSchema = z.object({
  user_id: z.string().uuid(),
});
export type WalletUserInput = z.infer<typeof walletUserSchema>;
