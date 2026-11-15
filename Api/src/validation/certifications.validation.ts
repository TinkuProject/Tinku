import { z } from "zod";
import { BASIC_STATUS } from "../constants/enums.constants";

const optionalLicenseNumber = z.preprocess(
  (value) => value === "" ? null : value,
  z.string().trim().min(1).max(100).nullable().optional()
);

export const createCertificationSchema = z.object({
  business_id: z.number().int().positive(),
  name: z.string().min(1).max(255),
  license_number: optionalLicenseNumber,
});

export const updateCertificationSchema = z.object({
  name: z.string().min(1).max(255).optional(),
  license_number: optionalLicenseNumber,
  status: z.enum(BASIC_STATUS).optional(),
});

export const certificationIdParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export const certificationByBusinessSchema = z.object({
  businessId: z.coerce.number().int().positive(),
});

export const certificationFilterSchema = z.object({
  business_id: z.coerce.number().int().positive().optional(),
  status: z.enum(BASIC_STATUS).optional(),
});

export const certificationBusinessesQuerySchema = z.object({
  business_ids: z.string().transform((value, ctx) => {
    const ids = [
      ...new Set(
        value
          .split(",")
          .map((item) => Number(item.trim()))
          .filter((item) => Number.isInteger(item) && item > 0)
      ),
    ];

    if (ids.length === 0) {
      ctx.addIssue({
        code: "custom",
        message: "business_ids query param must contain positive integers",
      });
    }

    return ids;
  }),
});

export type CertificationCreateInput = z.infer<typeof createCertificationSchema>;
export type CertificationUpdateInput = z.infer<typeof updateCertificationSchema>;
export type CertificationIdParam = z.infer<typeof certificationIdParamSchema>;
export type CertificationByBusiness = z.infer<typeof certificationByBusinessSchema>;
export type CertificationFilter = z.infer<typeof certificationFilterSchema>;
export type CertificationBusinessesQuery = z.infer<typeof certificationBusinessesQuerySchema>;
