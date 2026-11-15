import { z } from "zod";
import {
  DELIVERY_STATUS,
  FULFILLMENT_METHOD,
  MARKETPLACE_ORDER_STATUS,
  MARKETPLACE_PUBLICATION_STATUS,
} from "../constants/enums.constants";

const locationSchema = z.object({
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
});

export const idParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export const businessParamSchema = z.object({
  businessId: z.coerce.number().int().positive(),
});

export const businessViewBatchQuerySchema = z.object({
  ids: z.string().transform((value, ctx) => {
    const ids = [...new Set(
      value
        .split(",")
        .map((item) => Number(item.trim()))
        .filter((item) => Number.isInteger(item) && item > 0)
    )].slice(0, 100);

    if (ids.length === 0) {
      ctx.addIssue({
        code: "custom",
        message: "ids query param must contain positive integers",
      });
    }

    return ids;
  }),
});

const marketplaceListQueryBaseSchema = z.object({
  q: z.string().optional(),
  business_id: z.coerce.number().int().positive().optional(),
  availability: z.enum(['all', 'available', 'sold_out']).optional(),
  volume: z.enum(['small', 'medium', 'large']).optional(),
  min_tinkus: z.coerce.number().int().min(0).optional(),
  max_tinkus: z.coerce.number().int().min(0).optional(),
  sort: z.enum(['newest', 'price_asc', 'price_desc', 'name']).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});

export const marketplaceListQuerySchema = marketplaceListQueryBaseSchema.refine((data) => data.min_tinkus == null || data.max_tinkus == null || data.min_tinkus <= data.max_tinkus, {
  path: ['max_tinkus'],
  message: 'Maximum price must be greater than or equal to minimum price',
});

export const marketplaceAdminListQuerySchema = marketplaceListQueryBaseSchema.extend({
  status: z.enum(MARKETPLACE_PUBLICATION_STATUS).optional(),
});

export const marketplaceOrderListQuerySchema = z.object({
  status: z.enum(MARKETPLACE_ORDER_STATUS).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});

export const publicationCreateSchema = z.object({
  product_id: z.number().int().positive(),
  published_stock: z.number().int().min(0),
  unit_price: z.never().optional(),
  unit_tinku_price: z.number().int().positive().optional().nullable(),
  payment_mode: z.literal("tinkus").default("tinkus"),
}).refine((data) => data.unit_tinku_price != null, {
  path: ["unit_tinku_price"],
  message: "Marketplace products must have a Tinku price",
});

export const publicationStockUpdateSchema = z.object({
  published_stock: z.number().int().min(0),
  unit_price: z.never().optional(),
  unit_tinku_price: z.number().int().positive().optional().nullable(),
  payment_mode: z.literal("tinkus").optional(),
}).refine((data) => data.unit_tinku_price != null, {
  path: ["unit_tinku_price"],
  message: "Marketplace products must have a Tinku price",
});

export const publicationStatusUpdateSchema = z.object({
  status: z.enum(MARKETPLACE_PUBLICATION_STATUS),
});

export const marketplaceOrderCreateSchema = z.object({
  client_request_id: z.string().uuid(),
  items: z
    .array(
      z.object({
        publication_id: z.number().int().positive(),
        quantity: z.number().int().positive(),
      })
    )
    .min(1).max(50),
  payment_method: z.literal("tinkus").default("tinkus"),
  fulfillment: z.enum(FULFILLMENT_METHOD),
  pickup_business_id: z.number().int().positive().optional().nullable(),
  warehouse_id: z.number().int().positive().optional().nullable(),
  delivery_address: z.string().optional().nullable(),
  delivery_location: locationSchema.optional().nullable(),
});

export const marketplaceOrderStatusSchema = z.object({
  status: z.enum(MARKETPLACE_ORDER_STATUS),
});

export const marketplaceOrderRejectionSchema = z.object({
  reason: z.string().trim().min(10).max(500),
});

export const marketplacePickupValidationSchema = z.object({
  code: z.string().trim().min(4).max(20),
});

export const deliveryStatusSchema = z.object({
  status: z.enum(DELIVERY_STATUS),
});

export type MarketplaceListQuery = z.infer<typeof marketplaceListQuerySchema>;
export type MarketplaceAdminListQuery = z.infer<
  typeof marketplaceAdminListQuerySchema
>;
export type PublicationCreateInput = z.infer<typeof publicationCreateSchema>;
export type MarketplaceOrderCreateInput = z.infer<
  typeof marketplaceOrderCreateSchema
>;
export type MarketplacePickupValidationInput = z.infer<
  typeof marketplacePickupValidationSchema
>;
