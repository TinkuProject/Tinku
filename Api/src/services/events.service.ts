import { DbClient } from "../types/db-client";
import { EventsDAO } from "../dao/events.dao";
import { Event } from "../dto/event.dto";
import { isPrivileged } from "../helper/role.helper";
import { EventCreateInput, EventUpdateInput, EventIdInput,
} from "../validation/events.validation";
import { EventStatus } from "../constants/enums.constants";
import { NotificationsService } from "./notifications.service";
import { buildStatusNotification } from "../helper/notification.helper";
import { EntityTransportRelationsService } from "./entity-transport-relations.service";
import { AuditLogsDAO } from "../dao/audit-logs.dao";
import { assertValidEventDates } from "../helper/event-dates.helper";
import { assertDirectOwner, assertPrivileged } from "../helper/role.helper";

export class EventsService {
  constructor(
    private readonly dao: EventsDAO,
    private readonly db: DbClient,
    private readonly notificationsService: NotificationsService,
    private readonly transportRelationsService: EntityTransportRelationsService,
    private readonly auditDao?: AuditLogsDAO
  ) { }

  private async refreshTransportRelations(event: Event, radiusMeters = 1000) {
    await this.transportRelationsService.refreshNearby({
      entityType: "event",
      entityId: event.id,
      latitude: event.location.latitude,
      longitude: event.location.longitude,
      radiusMeters,
    });
  }

  // =========================
  // CREATE
  // =========================
  async create(
    input: EventCreateInput,
    user: { id: string; role: string }
  ): Promise<Event> {
    const privileged = isPrivileged(user.role);

    // ADMIN / MASTER
    if (privileged) {
      const event = await this.dao.create({
        ...input,
        creator_id: user.id,
        status: "active",
      });

      await this.refreshTransportRelations(event);

      return event;
    }

    // PARTNER FLOW
    const { data, error } = await this.db.rpc("create_event_with_charge", {
      p_user_id: user.id,
      p_business_id: input.business_id,
      p_category_id: input.category_id,
      p_name: input.name,
      p_description: input.description ?? null,
      p_start_date: input.start_date,
      p_end_date: input.end_date,
      p_capacity: input.capacity ?? null,
      p_tinku_price: input.tinku_price ?? 0,
      p_address: input.address,
      p_lat: input.location.latitude,
      p_lng: input.location.longitude,
    });

    if (error) throw error;

    const notif = buildStatusNotification({
      entityLabel: "Evento",
      entityName: input.name,
      status: "pending",
    });

    await this.notificationsService.create({
      user_id: user.id,
      title: notif.title,
      message: notif.message,
      type: "event",
      entity_type: "event",
      entity_id: Number(data?.id ?? data?.[0]?.id),
      route: "/myEvents",
      read: false,
    });

    await this.notificationsService.broadcastToAdmins({
      sender_id: user.id,
      message: `Nuevo evento pendiente de aprobación: "${input.name}".`,
      type: "event",
      entity_type: "event",
      entity_id: Number(data?.id ?? data?.[0]?.id),
      route: "/adminPendingEvents",
    });

    const created = Array.isArray(data) ? data[0] : data;

    await this.transportRelationsService.refreshNearby({
      entityType: "event",
      entityId: Number(created.id),
      latitude: input.location.latitude,
      longitude: input.location.longitude,
    });

    return data;
  }

  // =========================
  // APPROVE
  // =========================
  async approve(
    input: EventIdInput,
    admin: { id: string; role: string },
    message?: string
  ): Promise<Event> {
    assertPrivileged(admin);

    const event = await this.dao.findById(input);

    if (!event) {
      throw new Error("Event not found");
    }

    if (event.status !== "pending") {
      throw new Error("Event already processed");
    }

    const updated = await this.dao.update({
      id: input.id,
      status: "active",
    });

    if (!event.creator_id) {
      throw new Error("Event creator not found");
    }

    const notif = buildStatusNotification({
      entityLabel: "Evento",
      entityName: event.name,
      status: "approved",
      ...(message?.trim()
        ? { adminMessage: message.trim() }
        : {}),
    });

    await this.notificationsService.create({
      user_id: event.creator_id,
      sender_id: admin.id,
      title: notif.title,
      message: notif.message,
      type: "event",
      entity_type: "event",
      entity_id: event.id,
      route: "/myEvents",
      read: false,
    });

    await this.refreshTransportRelations(updated);

    return updated;
  }

  // =========================
  // REJECT
  // =========================
  async reject(
    input: EventIdInput,
    admin: { id: string; role: string },
    message?: string
  ): Promise<Event> {
    assertPrivileged(admin);

    const event = await this.dao.findById(input);

    if (!event) {
      throw new Error("Event not found");
    }

    if (event.status !== "pending") {
      throw new Error("Event already processed");
    }

    const updated = await this.dao.update({
      id: input.id,
      status: "cancelled",
    });

    if (!event.creator_id) {
      throw new Error("Event creator not found");
    }

    const notif = buildStatusNotification({
      entityLabel: "Evento",
      entityName: event.name,
      status: "rejected",
      ...(message?.trim()
        ? { adminMessage: message.trim() }
        : {}),
    });

    await this.notificationsService.create({
      user_id: event.creator_id,
      sender_id: admin.id,
      title: notif.title,
      message: notif.message,
      type: "event",
      entity_type: "event",
      entity_id: event.id,
      route: "/myEvents",
      read: false,
    });

    return updated;
  }

  // =========================
  // GETTERS
  // =========================
  getAll(includeNonPublic = false): Promise<Event[]> {
    return this.dao.findAll(undefined, 0, !includeNonPublic);
  }

  async getPage(limit: number, offset: number, includeNonPublic = false) {
    const [items, total] = await Promise.all([
      this.dao.findAll(limit, offset, !includeNonPublic),
      this.dao.countAll(!includeNonPublic),
    ]);
    return {
      items,
      total,
      limit,
      offset,
      has_more: offset + items.length < total,
    };
  }

  async getById(
    input: EventIdInput,
    includeNonPublic = false
  ): Promise<Event> {
    const event = includeNonPublic
      ? await this.dao.findById(input)
      : await this.dao.findPublicById(input);
    if (!event) throw new Error("Event not found");

    return event;
  }

  getByStatus(status: EventStatus): Promise<Event[]> {
    return this.dao.getByStatus(status);
  }

  async getByIds(ids: number[], includeNonPublic = false) {
    return this.dao.findByIds(ids, !includeNonPublic);
  }

  getByCategory(
    category_id: number,
    includeNonPublic = false
  ): Promise<Event[]> {
    return this.dao.findByCategory(category_id, !includeNonPublic);
  }

  getByBusiness(
    business_id: number,
    includeNonPublic = false
  ): Promise<Event[]> {
    return this.dao.findByBusiness(business_id, !includeNonPublic);
  }

  getByCreator(user_id: string): Promise<Event[]> {
    return this.dao.findByCreator(user_id);
  }

  // =========================
  // UPDATE
  // =========================
  async update(
    input: EventUpdateInput & EventIdInput,
    user_id: string
  ): Promise<Event> {
    const event = await this.dao.findById({ id: input.id });
    if (!event) throw new Error("Event not found");

    assertDirectOwner(event.creator_id, user_id, "Event not found");

    if (input.start_date !== undefined || input.end_date !== undefined) {
      assertValidEventDates(
        input.start_date ?? event.start_date,
        input.end_date ?? event.end_date
      );
    }

    const updated = await this.dao.update(input);

    if (input.location) {
      await this.refreshTransportRelations(updated);
    }

    return updated;
  }

  // =========================
  // DELETE
  // =========================
  async softDelete(
    input: EventIdInput,
    user_id: string
  ): Promise<{ id: number; status: string }> {
    const event = await this.dao.findById(input);

    if (!event) {
      throw new Error("Event not found");
    }

    assertDirectOwner(event.creator_id, user_id, "Event not found");

    const deleted = await this.dao.softDelete(input);

    await this.auditDao?.create({
      user_id,
      action: "event_soft_deleted",
      entity_type: "event",
      entity_id: event.id,
      details: {
        name: event.name,
        status_before: event.status,
        status_after: deleted.status,
        start_date: event.start_date,
        end_date: event.end_date,
      },
    });

    return deleted;
  }

  async delete(input: EventIdInput, user_id: string): Promise<void> {
    const event = await this.dao.findById(input);
    if (!event) throw new Error("Event not found");

    assertDirectOwner(event.creator_id, user_id, "Event not found");

    await this.dao.delete(input);

    await this.auditDao?.create({
      user_id,
      action: "event_deleted",
      entity_type: "event",
      entity_id: event.id,
      details: {
        name: event.name,
        status_before: event.status,
        start_date: event.start_date,
        end_date: event.end_date,
      },
    });
  }

  // =========================
  // AVAILABILITY
  // =========================
  async getAvailability(input: EventIdInput, includeNonPublic = false) {
    const event = await this.getById(input, includeNonPublic);
    if (!event) throw new Error("Event not found");

    const { data, error } = await this.db
      .from("reservations")
      .select("quantity")
      .eq("event_id", input.id)
      .eq("status", "confirmed");

    if (error) throw error;

    const confirmed = (data ?? []).reduce(
      (total, reservation) => total + (reservation.quantity ?? 0),
      0
    );
    const limit = event.capacity ?? 0;
    const remaining = limit === 0 ? null : Math.max(limit - confirmed, 0);
    const isFull = limit !== 0 && confirmed >= limit;

    return {
      confirmed,
      limit,
      remaining,
      is_full: isFull,
    };
  }
}
