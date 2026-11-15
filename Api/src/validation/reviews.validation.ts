import { z } from "zod";
import { REVIEW_ENTITY_TYPE, REVIEW_STATUS } from "../constants/enums.constants";
import { hasBlockedReviewLanguage, REVIEW_LANGUAGE_MESSAGE } from "../helper/review-language.helper";

const reviewText = z.string().trim().max(1200).nullable().optional().refine(
  (value) => !hasBlockedReviewLanguage(value),
  REVIEW_LANGUAGE_MESSAGE
);

export const reviewCreateSchema = z.object({
  entity_type: z.enum(REVIEW_ENTITY_TYPE),
  entity_id: z.number().int().positive(),
  rating: z.number().min(1).max(5),
  comment: reviewText,
});

export const reviewUpdateSchema = z.object({
  rating: z.number().min(1).max(5).optional(),
  comment: reviewText,
});

export const reviewReplySchema = z.object({
  reply: z.string().trim().min(1).max(1200).refine(
    (value) => !hasBlockedReviewLanguage(value),
    REVIEW_LANGUAGE_MESSAGE
  ),
});

export const reviewIdParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export const reviewStatusUpdateSchema = z.object({
  status: z.enum(REVIEW_STATUS),
});

export const reviewEntitiesQuerySchema = z.object({
  entity_type: z.enum(REVIEW_ENTITY_TYPE),
  entity_ids: z
    .string()
    .min(1)
    .transform((val) => val.split(",").map((id) => Number(id))),
});

export type ReviewStatusUpdateInput = z.infer<
  typeof reviewStatusUpdateSchema
>;

export const reviewEntityParamSchema = z.object({
  entityType: z.enum(REVIEW_ENTITY_TYPE),
  entityId: z.coerce.number().int().positive(),
});

export type ReviewCreateInput = z.infer<typeof reviewCreateSchema>;
export type ReviewUpdateInput = z.infer<typeof reviewUpdateSchema>;
export type ReviewReplyInput = z.infer<typeof reviewReplySchema>;
export type ReviewEntitiesQuery = z.infer<typeof reviewEntitiesQuerySchema>;
