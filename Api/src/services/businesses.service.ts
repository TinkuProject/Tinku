import { DbClient } from "../types/db-client";
import { BusinessesDAO } from "../dao/businesses.dao";
import { Business } from "../dto/business.dto";
import {
  assertDirectOwner,
  assertPrivileged,
  isPrivileged,
} from "../helper/role.helper";
import { buildStatusNotification } from "../helper/notification.helper";
import { BusinessCreateInput, BusinessUpdateInput, BusinessIdInput,
  BusinessCategoryInput, AdminBusinessUpdateInput } from "../validation/businesses.validation";
import { BusinessStatus } from "../constants/enums.constants";
import { NotificationsService } from "./notifications.service";
import { EntityTransportRelationsService } from "./entity-transport-relations.service";

export class BusinessesService {
  constructor(
    private readonly dao: BusinessesDAO,
    private readonly db: DbClient,
    private readonly notificationsService: NotificationsService,
    private readonly transportRelationsService: EntityTransportRelationsService
  ) {}

  private async refreshTransportRelations(business: Business, radiusMeters = 1000) {
    await this.transportRelationsService.refreshNearby({
      entityType: "business",
      entityId: business.id,
      latitude: business.location.latitude,
      longitude: business.location.longitude,
      radiusMeters,
    });
  }

  // =========================
  // CREATE
  // =========================
  async createSystem(input: BusinessCreateInput): Promise<Business> {
    const business = await this.dao.create({
      ...input,
      owner_id: null,
      status: "active",
      validated: true,
    });

    await this.refreshTransportRelations(business);

    return business;
  }

  async createOwned(
    input: BusinessCreateInput,
    user: { id: string; role: string }
  ): Promise<Business> {
    const privileged = isPrivileged(user.role);

    // =========================
    // ADMIN / MASTER
    // =========================
    if (privileged) {
      const business = await this.dao.create({
        ...input,
        owner_id: user.id,
        status: "active",
        validated: true,
      });

      await this.refreshTransportRelations(business);

      return business;
    }

    // =========================
    // PARTNER → RPC + cobro
    // =========================
    const { data, error } = await this.db.rpc("create_business_with_charge", {
      p_user_id: user.id,
      p_category_id: input.category_id,
      p_name: input.name,
      p_nit: input.nit ?? null,
      p_description: input.description ?? null,
      p_phone: input.phone ?? null,
      p_email: input.email ?? null,
      p_business_type: input.business_type,
      p_address: input.address,
      p_lat: input.location.latitude,
      p_lng: input.location.longitude,
      p_website: input.website ?? null,
    });

    if (error) throw error;

    const notif = buildStatusNotification({
      entityLabel: "Negocio",
      entityName: input.name,
      status: "pending",
    });

    await this.notificationsService.createSafely({
      user_id: user.id,
      title: notif.title,
      message: notif.message,
      type: "business",
      entity_type: "business",
      entity_id: Number(data?.id ?? data?.[0]?.id),
      route: "/myBusinesses",
      read: false,
    });

    const created = Array.isArray(data) ? data[0] : data;

    await this.transportRelationsService.refreshNearby({
      entityType: "business",
      entityId: Number(created.id),
      latitude: input.location.latitude,
      longitude: input.location.longitude,
    });

    return data;
  }

  // =========================
  // GETTERS
  // =========================
  getAll(includeNonPublic = false): Promise<Business[]> {
    return includeNonPublic
      ? this.dao.findAll()
      : this.dao.findActiveValidated();
  }

  async getById(
    input: BusinessIdInput,
    includeNonPublic = false
  ): Promise<Business> {
    const business = includeNonPublic
      ? await this.dao.findById(input)
      : await this.dao.findPublicById(input);
    if (!business) throw new Error("Business not found");

    return business;
  }

  async getByIds(
    ids: number[],
    includeNonPublic = false
  ): Promise<Business[]> {
    return includeNonPublic
      ? this.dao.findByIds(ids)
      : this.dao.findPublicByIds(ids);
  }

  async getByOwner(user_id: string): Promise<Business[]> {
    return this.dao.findByOwner(user_id);
  }

  async getClaimable(): Promise<Business[]> {
    return this.dao.findClaimable();
  }

  async getByCategory(
    input: BusinessCategoryInput,
    includeNonPublic = false
  ): Promise<Business[]> {
    return this.dao.findByCategory(input.category_id, !includeNonPublic);
  }

  // =========================
  // UPDATE (IMPORTANTE)
  // =========================
  async update(
    input: BusinessUpdateInput & BusinessIdInput,
    user: { id: string; role: string }
  ): Promise<Business> {
    const business = await this.dao.findById({ id: input.id });
    if (!business) throw new Error("Business not found");

    // ADMIN / MASTER → update directo
    if (isPrivileged(user.role)) {
      const updated = await this.dao.update(input);

      if (input.location) {
        await this.refreshTransportRelations(updated);
      }

      return updated;
    }

    // PARTNER → solo si es owner
    assertDirectOwner(business.owner_id, user.id, "Business not found");

    // aquí no se actualiza directamente
    throw new Error("Partners must use business updates flow");
  }

  // =========================
  // DELETE
  // =========================
  async softDelete(input: BusinessIdInput, user_id: string): Promise<Business> {
    const business = await this.dao.findById(input);

    if (!business) throw new Error("Business not found");

    assertDirectOwner(business.owner_id, user_id, "Business not found");

    return this.dao.softDelete(input);
  }

  // =========================
  // ADMIN UPDATE
  // =========================
  async adminUpdate(
    input: AdminBusinessUpdateInput & BusinessIdInput
  ): Promise<Business> {
    const business = await this.dao.findById(input);
    if (!business) throw new Error("Business not found");

    return this.dao.adminUpdate(input);
  }

  // =========================
  // CLAIMABLE
  // =========================
  async isClaimable(input: BusinessIdInput): Promise<boolean> {
    const business = await this.dao.findById(input);
    if (!business) throw new Error("Business not found");

    return !business.owner_id && !business.validated;
  }

  async validate(
    input: BusinessIdInput,
    admin: { id: string; role: string },
    message?: string
  ): Promise<Business> {
    assertPrivileged(admin);

    const business = await this.dao.findById(input);

    if (!business) {
      throw new Error("Business not found");
    }

    if (business.status !== "pending") {
      throw new Error("Business already processed");
    }

    const updated = await this.dao.validate(input);

    if (!business.owner_id) {
      throw new Error("Business owner not found");
    }

    const notif = buildStatusNotification({
      entityLabel: "Negocio",
      entityName: business.name,
      status: "approved",
      ...(message?.trim() ? { adminMessage: message.trim() } : {}),
    });

    await this.notificationsService.createSafely({
      user_id: business.owner_id,
      sender_id: admin.id,
      title: notif.title,
      message: notif.message,
      type: "business",
      entity_type: "business",
      entity_id: business.id,
      route: "/myBusinesses",
      read: false,
    });

    await this.refreshTransportRelations(updated);

    return updated;
  }

  async reject(
    input: BusinessIdInput,
    admin: { id: string; role: string },
    message?: string
  ): Promise<Business> {
    assertPrivileged(admin);

    const business = await this.dao.findById(input);

    if (!business) {
      throw new Error("Business not found");
    }

    if (business.status !== "pending") {
      throw new Error("Business already processed");
    }

    const updated = await this.dao.reject(input);

    if (!business.owner_id) {
      throw new Error("Business owner not found");
    }

    const notif = buildStatusNotification({
      entityLabel: "Negocio",
      entityName: business.name,
      status: "rejected",
      ...(message?.trim() ? { adminMessage: message.trim() } : {}),
    });

    await this.notificationsService.createSafely({
      user_id: business.owner_id,
      sender_id: admin.id,
      title: notif.title,
      message: notif.message,
      type: "business",
      entity_type: "business",
      entity_id: business.id,
      route: "/myBusinesses",
      read: false,
    });

    return updated;
  }

  async getByStatus(status: BusinessStatus): Promise<Business[]> {
    return this.dao.findByStatus(status);
  }
}
