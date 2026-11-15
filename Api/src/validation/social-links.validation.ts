import { z } from "zod";

export const createSocialLinkSchema = z.object({
  business_id: z.number().int().positive(),
  platform: z.string().min(1).max(100),
  url: z.preprocess(
  (value) =>
    typeof value === "string" &&
            !/^https?:\/\//i.test(value.trim())
        ? `https://${value.trim()}`
        : value,
  z.string().url()
),
});

export const updateSocialLinkSchema = z.object({
  id: z.number().int().positive(),
  business_id: z.number().int().positive().optional(),
  platform: z.string().min(1).max(100).optional(),
  url: z.preprocess(
  (value) =>
    typeof value === "string" &&
            !/^https?:\/\//i.test(value.trim())
        ? `https://${value.trim()}`
        : value,
  z.string().url().optional()
),
});

export const socialLinkIdSchema = z.object({
  id: z.number().int().positive(),
});

export const socialLinksByBusinessSchema = z.object({
  business_id: z.number().int().positive(),
});

export const socialLinksByBusinessesSchema = z.object({
  business_ids: z
    .string()
    .min(1)
    .transform((value) => value.split(",").map((id) => Number(id.trim())))
    .pipe(z.array(z.number().int().positive()).min(1).max(100)),
});

export type CreateSocialLinkInput = z.infer<typeof createSocialLinkSchema>;
export type UpdateSocialLinkInput = z.infer<typeof updateSocialLinkSchema>;
export type SocialLinkIdInput = z.infer<typeof socialLinkIdSchema>;
export type SocialLinksByBusinessInput = z.infer<typeof socialLinksByBusinessSchema>;
export type SocialLinksByBusinessesInput = z.infer<typeof socialLinksByBusinessesSchema>;
