import { z } from "zod";
import { MEDIA_ENTITY_TYPE } from "../constants/enums.constants";

export const uploadSchema = z.object({
  entityType: z.enum(MEDIA_ENTITY_TYPE),
  entityId: z.union([
    z.string().uuid(),            // user
    z.coerce.number().int().positive(), // resto
  ]),
  uploadMode: z.enum(["direct", "storage_only"]).optional().default("direct"),
}).strict().superRefine((data, ctx) => {
  if (data.entityType === "user") {
    if (typeof data.entityId !== "string") {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "User entityId must be UUID",
        path: ["entityId"],
      });
    }
  } else {
    if (typeof data.entityId !== "number") {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "EntityId must be numeric",
        path: ["entityId"],
      });
    }
  }
});

export const deleteMediaSchema = z.object({
  mediaId: z.number().int().positive(),
}).strict();

export const deleteEntityMediaSchema = z.discriminatedUnion("entityType", [
  z.object({
    entityType: z.literal("user"),
    entityId: z.string().uuid(),
  }),
  z.object({
    entityType: z.enum(
      MEDIA_ENTITY_TYPE.filter((t) => t !== "user") as [
        Exclude<(typeof MEDIA_ENTITY_TYPE)[number], "user">,
        ...Exclude<(typeof MEDIA_ENTITY_TYPE)[number], "user">[]
      ]
    ),
    entityId: z.coerce.number().int().positive(),
  }),
]);

export type UploadDTO = z.infer<typeof uploadSchema>;
export type DeleteMediaDTO = z.infer<typeof deleteMediaSchema>;
export type DeleteEntityMediaDTO = z.infer<typeof deleteEntityMediaSchema>;