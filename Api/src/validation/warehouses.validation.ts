import { z } from "zod";
import {
  BASIC_STATUS,
  WAREHOUSE_STATUS,
  WAREHOUSE_STOCK_REQUEST_STATUS,
} from "../constants/enums.constants";

const locationSchema = z.object({
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
});

const nullableText = z.preprocess(
  (value) => (typeof value === "string" && value.trim() === "" ? null : value),
  z.string().optional().nullable()
);

const nullableEmail = z.preprocess(
  (value) => (typeof value === "string" && value.trim() === "" ? null : value),
  z.string().email().optional().nullable()
);

export const warehouseIdParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export const warehouseListQuerySchema = z.object({
  status: z.enum(WAREHOUSE_STATUS).optional(),
});

export const warehouseCreateSchema = z.object({
  owner_id: z.string().uuid().optional().nullable(),
  name: z.string().min(1),
  description: nullableText,
  phone: nullableText,
  email: nullableEmail,
  address: nullableText,
  location: locationSchema.optional().nullable(),
  validated: z.boolean().optional(),
  status: z.enum(WAREHOUSE_STATUS).optional(),
});

export const warehouseUpdateSchema = warehouseCreateSchema.partial();

export const warehouseStatusSchema = z.object({
  status: z.enum(WAREHOUSE_STATUS),
  validated: z.boolean().optional(),
});

export const warehouseModerationSchema = z.object({
  message: z.preprocess(
    (value) =>
      typeof value === "string" && value.trim() === "" ? undefined : value,
    z.string().trim().max(500).optional()
  ),
});

export const warehouseRejectSchema = z.object({
  message: z.string().trim().min(1).max(500),
});

export const warehouseInventoryUpsertSchema = z.object({
  product_id: z.number().int().positive(),
  location_id: z.number().int().positive().optional().nullable(),
  quantity: z.number().int().min(0),
  reserved_quantity: z.number().int().min(0).optional(),
  status: z.enum([
    "available",
    "reserved",
    "delivered",
    "returned",
    "cancelled",
  ]),
  reason: z.string().optional().nullable(),
});

export const warehouseInventoryIdParamSchema = z.object({
  inventoryId: z.coerce.number().int().positive(),
});

export const warehouseInventoryLocationSchema = z.object({
  location_id: z.number().int().positive().optional().nullable(),
});

export const warehouseLocationIdParamSchema = z.object({
  locationId: z.coerce.number().int().positive(),
});

export const warehouseLocationCreateSchema = z.object({
  parent_id: z.number().int().positive().optional().nullable(),
  name: z.string().trim().min(1).max(120),
  code: z.string().trim().min(1).max(40),
  description: nullableText,
  status: z.enum(BASIC_STATUS).optional(),
  sort_order: z.number().int().min(0).optional(),
});

export const warehouseLocationUpdateSchema =
  warehouseLocationCreateSchema.partial();

export const warehouseStockRequestIdParamSchema = z.object({
  requestId: z.coerce.number().int().positive(),
});

export const warehouseStockRequestQuerySchema = z.object({
  status: z.enum(WAREHOUSE_STOCK_REQUEST_STATUS).optional(),
});

export const warehouseStockRequestCreateSchema = z.object({
  business_id: z.number().int().positive(),
  warehouse_id: z.number().int().positive(),
  product_id: z.number().int().positive(),
  quantity: z.number().int().positive(),
  notes: nullableText,
});

export const warehouseStockRequestRejectSchema = z.object({
  message: z.string().trim().min(1).max(500),
});

export const warehouseStockRequestApproveSchema = z.object({
  location_id: z.number().int().positive().optional().nullable(),
});

export const warehouseStockRequestReceiveSchema = z.object({
  location_id: z.number().int().positive().optional().nullable(),
});

export const businessFulfillmentParamSchema = z.object({
  businessId: z.coerce.number().int().positive(),
});

export const businessFulfillmentSchema = z.object({
  pickup_in_store: z.boolean().optional(),
  warehouse_delivery: z.boolean().optional(),
  notes: z.string().optional().nullable(),
  warehouse_ids: z.array(z.number().int().positive()).optional(),
});

export const relationStatusSchema = z.object({
  status: z.enum(BASIC_STATUS).optional(),
});

export type WarehouseCreateInput = z.infer<typeof warehouseCreateSchema>;
export type WarehouseUpdateInput = z.infer<typeof warehouseUpdateSchema>;
export type WarehouseInventoryUpsertInput = z.infer<
  typeof warehouseInventoryUpsertSchema
>;
export type WarehouseInventoryLocationInput = z.infer<
  typeof warehouseInventoryLocationSchema
>;
export type WarehouseLocationCreateInput = z.infer<
  typeof warehouseLocationCreateSchema
>;
export type WarehouseLocationUpdateInput = z.infer<
  typeof warehouseLocationUpdateSchema
>;
export type WarehouseStockRequestCreateInput = z.infer<
  typeof warehouseStockRequestCreateSchema
>;
export type WarehouseStockRequestApproveInput = z.infer<
  typeof warehouseStockRequestApproveSchema
>;
export type WarehouseStockRequestReceiveInput = z.infer<
  typeof warehouseStockRequestReceiveSchema
>;
export type BusinessFulfillmentInput = z.infer<typeof businessFulfillmentSchema>;
