import { z } from "zod";
import { ROUTE_DIRECTION } from "../constants/enums.constants";
import { locationSchema } from "../types/location.type";

export const transportRouteCreateSchema = z.object({
  transport_line_id: z.number().int().positive(),
  direction: z.enum(ROUTE_DIRECTION),
  stop_order: z.number().int().min(0),
  location: locationSchema,
});

export const transportRouteUpdateSchema = z.object({
  id: z.number().int().positive(),
  transport_line_id: z.number().int().positive().optional(),
  direction: z.enum(ROUTE_DIRECTION).optional(),
  stop_order: z.number().int().min(0).optional(),
  location: locationSchema.optional(),
});

export const transportRouteIdSchema = z.object({
  id: z.number().int().positive(),
});

export const transportRouteByLineSchema = z.object({
  transport_line_id: z.number().int().positive(),
});

export const transportRouteByLineAndDirectionSchema = z.object({
  transport_line_id: z.number().int().positive(),
  direction: z.enum(ROUTE_DIRECTION),
});

export const transportRoutesByLinesSchema = z.object({
  line_ids: z
    .string()
    .min(1)
    .transform((value) => value.split(",").map((id) => Number(id.trim())))
    .pipe(z.array(z.number().int().positive()).min(1).max(100)),
  direction: z.enum(ROUTE_DIRECTION).optional(),
});

export const transportRouteCreateBulkSchema = z.array(transportRouteCreateSchema);

export type TransportRouteByLineAndDirectionInput = z.infer<typeof transportRouteByLineAndDirectionSchema>;
export type TransportRoutesByLinesInput = z.infer<typeof transportRoutesByLinesSchema>;
export type TransportRouteCreateInput = z.infer<typeof transportRouteCreateSchema>;
export type TransportRouteUpdateInput = z.infer<typeof transportRouteUpdateSchema>;
export type TransportRouteIdInput = z.infer<typeof transportRouteIdSchema>;
export type TransportRouteByLineInput = z.infer<typeof transportRouteByLineSchema>;
