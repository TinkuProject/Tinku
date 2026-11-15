// =========================
// USERS
// =========================
export const USER_ROLES = ["user", "partner", "admin", "master"] as const;
export type UserRole = typeof USER_ROLES[number];

export const USER_STATUS = ["active", "inactive", "suspended", "deleted"] as const;
export type UserStatus = typeof USER_STATUS[number];

// =========================
// TRANSACTIONS
// =========================
export const TRANSACTION_TYPES = [
  "purchase",
  "spend",
  "reward",
  "refund",
  "cashout",
  "admin_adjustment",
] as const;
export type TransactionType = typeof TRANSACTION_TYPES[number];

export const TRANSACTION_STATUS = [
  "pending",
  "approved",
  "rejected",
  "failed",
  "cancelled",
  "reversed",
] as const;
export type TransactionStatus = typeof TRANSACTION_STATUS[number];

// =========================
// PAYMENTS
// =========================
export const PAYMENT_METHODS = ["qr", "gateway", "cash_point"] as const;
export type PaymentMethod = typeof PAYMENT_METHODS[number];

export const PAYMENT_STATUS = [
  "pending",
  "approved",
  "rejected",
  "failed",
  "cancelled",
  "expired",
] as const;
export type PaymentStatus = typeof PAYMENT_STATUS[number];

// =========================
// PACKAGES / SUBSCRIPTIONS
// =========================
export const SUBSCRIPTION_STATUS = [
  "active",
  "paused",
  "cancelled",
  "expired",
] as const;
export type SubscriptionStatus = typeof SUBSCRIPTION_STATUS[number];

// =========================
// APPROVAL
// =========================
export const APPROVAL_STATUS = ["pending", "approved", "rejected"] as const;
export type ApprovalStatus = typeof APPROVAL_STATUS[number];

export const PAYMENT_TYPE = [
  "partner_upgrade",
  "coin_purchase",
  "subscription",
  "product_publication",
  "marketplace_order",
] as const;
export type PaymentType = typeof PAYMENT_TYPE[number];
// =========================
// BUSINESS / CONTENT
// =========================
export const BUSINESS_TYPE = ["business", "service"] as const;
export type BusinessType = typeof BUSINESS_TYPE[number];

export const BUSINESS_STATUS = ["active", "inactive", "suspended", "pending"] as const;
export type BusinessStatus = typeof BUSINESS_STATUS[number];

export const PRODUCT_STATUS = ["active", "inactive", "out_of_stock"] as const;
export type ProductStatus = typeof PRODUCT_STATUS[number];

export const WAREHOUSE_STATUS = [
  "pending",
  "active",
  "inactive",
  "archived",
] as const;
export type WarehouseStatus = typeof WAREHOUSE_STATUS[number];

export const WAREHOUSE_INVENTORY_STATUS = [
  "available",
  "reserved",
  "delivered",
  "returned",
  "cancelled",
] as const;
export type WarehouseInventoryStatus =
  typeof WAREHOUSE_INVENTORY_STATUS[number];

export const WAREHOUSE_STOCK_REQUEST_STATUS = [
  "pending",
  "approved",
  "sent",
  "received",
  "rejected",
  "cancelled",
] as const;
export type WarehouseStockRequestStatus =
  typeof WAREHOUSE_STOCK_REQUEST_STATUS[number];

export const MARKETPLACE_PUBLICATION_STATUS = [
  "draft",
  "active",
  "paused",
  "sold_out",
  "archived",
] as const;
export type MarketplacePublicationStatus =
  typeof MARKETPLACE_PUBLICATION_STATUS[number];

export const MARKETPLACE_ORDER_STATUS = [
  "pending",
  "paid",
  "preparing",
  "ready_for_pickup",
  "in_delivery",
  "delivered",
  "cancelled",
] as const;
export type MarketplaceOrderStatus = typeof MARKETPLACE_ORDER_STATUS[number];

export const DELIVERY_STATUS = [
  "pending",
  "assigned",
  "picked_up",
  "delivered",
  "cancelled",
] as const;
export type DeliveryStatus = typeof DELIVERY_STATUS[number];

export const FULFILLMENT_METHOD = ["pickup", "warehouse_delivery"] as const;
export type FulfillmentMethod = typeof FULFILLMENT_METHOD[number];

export const EVENT_STATUS = [
  "pending",
  "active",
  "finished",
  "cancelled",
] as const;
export type EventStatus = typeof EVENT_STATUS[number];

export const PROMOTION_STATUS = ["active", "inactive", "cancelled"] as const;
export type PromotionStatus = typeof PROMOTION_STATUS[number];

// =========================
// INTERACTION
// =========================
export const VISIT_TYPE = ["visited", "favorited"] as const;
export type VisitType = typeof VISIT_TYPE[number];

export const RESERVATION_STATUS = [
  "pending",
  "confirmed",
  "cancelled",
] as const;
export type ReservationStatus = typeof RESERVATION_STATUS[number];

export const EVENT_TICKET_STATUS = [
  "active",
  "used",
  "expired",
  "cancelled",
] as const;
export type EventTicketStatus = typeof EVENT_TICKET_STATUS[number];

export const REVIEW_STATUS = ["visible", "hidden", "reported"] as const;
export type ReviewStatus = typeof REVIEW_STATUS[number];

export const REVIEW_ENTITY_TYPE = ["tourist_place", "business", "event", "product"] as const;
export type ReviewEntityType = typeof REVIEW_ENTITY_TYPE[number];
// =========================
// MEDIA
// =========================
export const MEDIA_TYPE = ["image", "video", "file"] as const;
export type MediaType = typeof MEDIA_TYPE[number];

export const MEDIA_ENTITY_TYPE = [
  "business",
  "event",
  "tourist_place",
  "product",
  "user",
  "review",
  "certification",
  "category",
  "payment",
  "coin_package",
  "subscription",
  "discount",
  "transport_line",
  "charging_point",
  "warehouse",
  "product_publication",
] as const;
export type MediaEntityType = typeof MEDIA_ENTITY_TYPE[number];

// =========================
// TRANSPORT / ROUTES
// =========================
export const ROUTE_DIRECTION = ["outbound", "return"] as const;
export type RouteDirection = typeof ROUTE_DIRECTION[number];

// =========================
// GENERIC / SYSTEM
// =========================
export const BASIC_STATUS = ["active", "inactive", "archived"] as const;
export type BasicStatus = typeof BASIC_STATUS[number];

// =========================
// GEO / VISITS
// =========================
export const VISIT_ENTITY = ["tourist_place", "business", "event"] as const;
export type VisitEntity = typeof VISIT_ENTITY[number];

export const OPENING_ENTITY = [
  "business",
  "event",
  "tourist_place",
  "charging_point",
] as const;
export type OpeningEntity = typeof OPENING_ENTITY[number];

// =========================
// TIME
// =========================
export const WEEK_DAY = [
  "monday",
  "tuesday",
  "wednesday",
  "thursday",
  "friday",
  "saturday",
  "sunday",
] as const;
export type WeekDay = typeof WEEK_DAY[number];

// =========================
// INFRASTRUCTURE
// =========================
export const CHARGING_POINT_STATUS = [
  "active",
  "inactive",
  "maintenance",
] as const;
export type ChargingPointStatus = typeof CHARGING_POINT_STATUS[number];

// =========================
// CATEGORY
// =========================
export const CATEGORY_ENTITY_TYPE = [
  "business",
  "event",
  "tourist_place",
  "product",
] as const;

export type CategoryEntityType = typeof CATEGORY_ENTITY_TYPE[number];

// =========================
// UPDATES
// =========================
export const UPDATE_ENTITY_TYPE = [
  "business",
  "event",
  "product",
  "certification",
] as const;

export type UpdateEntityType = typeof UPDATE_ENTITY_TYPE[number];
