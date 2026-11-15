import { DbClient } from "../types/db-client";
import { MediaEntityType } from "../constants/enums.constants";
import {
  Actor,
  assertOwnershipAccess,
  assertPrivileged,
} from "../helper/role.helper";

type OwnershipEntityType =
  | MediaEntityType
  | "social_link"
  | "opening_hour"
  | "boost"
  | "notification"
  | "financial_transaction"
  | "reservation"
  | "event_ticket";

export class OwnershipService {
  constructor(private readonly db: DbClient) { }

  private assertOwnership(
    ownerId: string | null | undefined,
    actor: Actor,
    notFoundMessage: string
  ) {
    assertOwnershipAccess(ownerId, actor, notFoundMessage);
  }

  private assertAdmin(actor: Actor): void {
    assertPrivileged(actor);
  }

  async validate(
    entityType: OwnershipEntityType,
    entityId: string | number,
    actor: Actor
  ): Promise<void> {

    if (
      entityType !== "user" &&
      entityType !== "event_ticket" &&
      typeof entityId !== "number"
    ) {
      throw new Error("Invalid entityId type");
    }

    switch (entityType) {

      // =========================
      // DIRECT OWNERSHIP
      // =========================

      case "business": {
        const { data, error } = await this.db
          .from("businesses")
          .select("owner_id")
          .eq("id", entityId)
          .maybeSingle();

        if (error) {
          throw new Error(`Business query failed: ${error.message}`);
        }

        this.assertOwnership(data?.owner_id,
          actor,
          "Business not found"
        );

        return;
      }

      case "certification": {
        const { data, error } = await this.db
          .from("certifications")
          .select("business:business_id(owner_id)")
          .eq("id", entityId)
          .maybeSingle();

        if (error) {
          throw new Error(`Certification query failed: ${error.message}`);
        }

        const ownerId =
          (data as any)?.business?.[0]?.owner_id ??
          (data as any)?.business?.owner_id;

        this.assertOwnership(ownerId,
          actor,
          "Certification not found"
        );

        return;
      }

      case "discount": {
        const { data: discount, error: discountError } = await this.db
          .from("discounts")
          .select("business_id")
          .eq("id", entityId)
          .maybeSingle();

        if (discountError) {
          throw new Error(`Discount query failed: ${discountError.message}`);
        }

        if (!discount) {
          throw new Error("Discount not found");
        }

        const { data: business, error: businessError } = await this.db
          .from("businesses")
          .select("owner_id")
          .eq("id", discount.business_id)
          .maybeSingle();

        if (businessError) {
          throw new Error(`Business query failed: ${businessError.message}`);
        }

        this.assertOwnership(business?.owner_id,
          actor,
          "Discount not found"
        );

        return;
      }

      case "event": {
        const { data, error } = await this.db
          .from("events")
          .select("creator_id")
          .eq("id", entityId)
          .maybeSingle();

        if (error) {
          throw new Error(`Event query failed: ${error.message}`);
        }

        this.assertOwnership(data?.creator_id,
          actor,
          "Event not found"
        );

        return;
      }

      // =========================
      // INDIRECT OWNERSHIP
      // =========================

      case "product": {
        const { data, error } = await this.db
          .from("products")
          .select("business:business_id(owner_id)")
          .eq("id", entityId)
          .maybeSingle();

        if (error) {
          throw new Error(`Product query failed: ${error.message}`);
        }

        const ownerId =
          (data as any)?.business?.[0]?.owner_id ??
          (data as any)?.business?.owner_id;

        this.assertOwnership(ownerId,
          actor,
          "Product not found"
        );

        return;
      }

      case "payment": {
        const { data, error } = await this.db
          .from("payments")
          .select("user_id")
          .eq("id", entityId)
          .maybeSingle();

        if (error) {
          throw new Error(`Payment query failed: ${error.message}`);
        }

        this.assertOwnership(data?.user_id,
          actor,
          "Payment not found"
        );

        return;
      }

      case "review": {
        const { data, error } = await this.db
          .from("reviews")
          .select("user_id")
          .eq("id", entityId)
          .maybeSingle();

        if (error) {
          throw new Error(`Review query failed: ${error.message}`);
        }

        this.assertOwnership(data?.user_id,
          actor,
          "Review not found"
        );

        return;
      }

      case "tourist_place": {
        const { data, error } = await this.db
          .from("tourist_places")
          .select("created_by")
          .eq("id", entityId)
          .maybeSingle();

        if (error) {
          throw new Error(`Tourist place query failed: ${error.message}`);
        }

        this.assertOwnership(
          data?.created_by,
          actor,
          "Tourist place not found"
        );

        return;
      }

      case "category": {
        const { data, error } = await this.db
          .from("categories")
          .select("id")
          .eq("id", entityId)
          .maybeSingle();

        if (error) throw error;

        if (!data) {
          throw new Error("Category not found");
        }

        this.assertAdmin(actor);

        return;
      }

      case "transport_line": {
        const { data, error } = await this.db
          .from("transport_lines")
          .select("id")
          .eq("id", entityId)
          .maybeSingle();

        if (error) {
          throw new Error(
            `Transport line query failed: ${error.message}`
          );
        }

        if (!data) {
          throw new Error(
            "Transport line not found"
          );
        }

        this.assertAdmin(actor);

        return;
      }

      case "subscription": {
        const { data, error } = await this.db
          .from("subscription_plans")
          .select("id")
          .eq("id", entityId)
          .maybeSingle();

        if (error) {
          throw new Error(
            `Subscription plan query failed: ${error.message}`
          );
        }

        if (!data) {
          throw new Error("Subscription plan not found");
        }

        this.assertAdmin(actor);

        return;
      }

      case "user": {
        if (typeof entityId !== "string") {
          throw new Error("Invalid user entityId");
        }

        this.assertOwnership(entityId, actor, "Unauthorized");
        return;
      }

      case "coin_package": {
        const { data, error } = await this.db
          .from("coin_packages")
          .select("id")
          .eq("id", entityId)
          .maybeSingle();

        if (error) {
          throw new Error(
            `Coin package query failed: ${error.message}`
          );
        }

        if (!data) {
          throw new Error("Coin package not found");
        }

        this.assertAdmin(actor);

        return;
      }

      case "charging_point": {
        const { data, error } = await this.db
          .from("charging_points")
          .select("id")
          .eq("id", entityId)
          .maybeSingle();

        if (error) {
          throw new Error(
            `Charging point query failed: ${error.message}`
          );
        }

        if (!data) {
          throw new Error("Charging point not found");
        }

        this.assertAdmin(actor);

        return;
      }

      case "warehouse": {
        const { data, error } = await this.db
          .from("warehouses")
          .select("owner_id")
          .eq("id", entityId)
          .maybeSingle();

        if (error) {
          throw new Error(
            `Warehouse query failed: ${error.message}`
          );
        }

        this.assertOwnership(
          data?.owner_id,
          actor,
          "Warehouse not found"
        );

        return;
      }

      case "product_publication": {
        const { data, error } = await this.db
          .from("product_publications")
          .select("business:business_id(owner_id)")
          .eq("id", entityId)
          .maybeSingle();

        if (error) {
          throw new Error(
            `Product publication query failed: ${error.message}`
          );
        }

        const ownerId =
          (data as any)?.business?.[0]?.owner_id ??
          (data as any)?.business?.owner_id;

        this.assertOwnership(
          ownerId,
          actor,
          "Product publication not found"
        );

        return;
      }

      case "social_link": {
        const { data, error } = await this.db
          .from("social_links")
          .select("business:business_id(owner_id)")
          .eq("id", entityId)
          .maybeSingle();

        if (error) {
          throw new Error(`Social link query failed: ${error.message}`);
        }

        const ownerId =
          (data as any)?.business?.[0]?.owner_id ??
          (data as any)?.business?.owner_id;

        this.assertOwnership(ownerId, actor, "Social link not found");
        return;
      }

      case "opening_hour": {
        const { data, error } = await this.db
          .from("opening_hours")
          .select("entity_type, entity_id")
          .eq("id", entityId)
          .maybeSingle();

        if (error) {
          throw new Error(`Opening hour query failed: ${error.message}`);
        }
        if (!data) throw new Error("Opening hour not found");

        await this.validate(
          data.entity_type as OwnershipEntityType,
          Number(data.entity_id),
          actor
        );
        return;
      }

      case "boost": {
        const { data, error } = await this.db
          .from("boosts")
          .select("entity_type, entity_id")
          .eq("id", entityId)
          .maybeSingle();

        if (error) throw new Error(`Boost query failed: ${error.message}`);
        if (!data) throw new Error("Boost not found");

        await this.validate(
          data.entity_type as OwnershipEntityType,
          Number(data.entity_id),
          actor
        );
        return;
      }

      case "notification":
      case "financial_transaction":
      case "reservation": {
        const table = entityType === "notification"
          ? "notifications"
          : entityType === "financial_transaction"
            ? "financial_transactions"
            : "reservations";
        const { data, error } = await this.db
          .from(table)
          .select("user_id")
          .eq("id", entityId)
          .maybeSingle();

        if (error) {
          throw new Error(`${entityType} query failed: ${error.message}`);
        }

        this.assertOwnership(
          data?.user_id,
          actor,
          `${entityType} not found`
        );
        return;
      }

      case "event_ticket": {
        const { data, error } = await this.db
          .from("event_tickets")
          .select("reservation:reservation_id(user_id)")
          .eq("id", entityId)
          .maybeSingle();

        if (error) {
          throw new Error(`Event ticket query failed: ${error.message}`);
        }

        const ownerId =
          (data as any)?.reservation?.[0]?.user_id ??
          (data as any)?.reservation?.user_id;

        this.assertOwnership(ownerId, actor, "Event ticket not found");
        return;
      }


      // =========================
      // FALLBACK
      // =========================

      default:
        throw new Error(
          `Ownership validation not implemented for ${entityType}`
        );
    }
  }
}
