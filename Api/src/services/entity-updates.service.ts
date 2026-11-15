import { DbClient } from "../types/db-client";
import { EntityUpdatesDAO, EntityUpdate } from "../dao/entity-updates.dao";
import {
  CreateEntityUpdateInput,
  ReviewEntityUpdateInput,
} from "../validation/entity-updates.validation";
import { ApprovalStatus, UpdateEntityType, VisitEntity, OpeningEntity, VISIT_ENTITY } from "../constants/enums.constants";
import { StorageService } from "./storage.service";
import { OwnershipService } from "./ownership.service";
import { SocialLinksService } from "./social-links.service";
import { OpeningHoursService } from "./opening-hours.service";
import { EntityTransportRelationsService } from "./entity-transport-relations.service";
import { assertValidEventDates } from "../helper/event-dates.helper";
import { isPrivileged } from "../helper/role.helper";

type MediaType = "image" | "file" | "video";

type MediaAddItem = {
  url: string;
  type: MediaType;
  is_primary?: boolean;
};

type MediaUpdatePayload = {
  add?: Array<string | MediaAddItem>;
  remove?: number[];
};

type SocialUpdateItem = {
  platform: string;
  url: string;
};

type OpeningUpdateItem = {
  week_day: string;
  start_time: string;
  end_time: string;
};

export class EntityUpdatesService {
  constructor(
    private readonly dao: EntityUpdatesDAO,
    private readonly ownershipService: OwnershipService,
    private readonly db: DbClient,
    private readonly socialLinksService: SocialLinksService,
    private readonly openingHoursService: OpeningHoursService,
    private readonly transportRelationsService: EntityTransportRelationsService
  ) {}

  async create(
    input: CreateEntityUpdateInput,
    user: { id: string; role: string }
  ): Promise<EntityUpdate> {
    this.assertNotAdmin(user.role);

    const { entity_type, entity_id } = input;

    await this.ownershipService.validate(entity_type, entity_id, user);
    this.validateAddedMedia(entity_type, entity_id, input.data);

    if (entity_type === "event") {
      await this.validateEventDates(entity_id, input.data);
    }

    const existing = await this.dao.findByEntity(entity_type, entity_id);
    const hasPending = existing.some((u) => u.status === "pending");

    if (hasPending) {
      throw new Error("There is already a pending update");
    }

    return this.dao.create({
      ...input,
      creator_id: user.id,
    });
  }

  async approve(
    input: ReviewEntityUpdateInput,
    reviewer: { id: string; role: string }
  ): Promise<void> {
    this.assertAdmin(reviewer.role);

    const update = await this.getRequiredUpdate(input.update_id);

    if (update.entity_type === "event") {
      await this.validateEventDates(update.entity_id, update.data);
    }

    await this.callApproveRPC(update, reviewer.id, input.comment);
    await this.syncApprovedMedia(update);
    await this.syncApprovedRelations(update);
  }

  async reject(
    input: ReviewEntityUpdateInput,
    reviewer: { id: string; role: string }
  ): Promise<void> {
    this.assertAdmin(reviewer.role);

    const update = await this.getRequiredUpdate(input.update_id);

    await this.callRejectRPC(update, reviewer.id, input.comment);
    await this.cleanupAddedMediaFiles(update);
  }

  private assertAdmin(role: string): void {
    if (!isPrivileged(role)) {
      throw new Error("Unauthorized");
    }
  }

  private assertNotAdmin(role: string): void {
    if (isPrivileged(role)) {
      throw new Error("Admins must edit entities directly");
    }
  }

  private async getRequiredUpdate(id: number): Promise<EntityUpdate> {
    const update = await this.dao.findById(id);

    if (!update) {
      throw new Error("Update not found");
    }
    if (update.status !== "pending") throw new Error("Request already reviewed");

    return update;
  }

  private validateAddedMedia(type: string, id: number, data: Record<string, any>): void {
    const media = data.media;
    if (media === undefined) return;
    if (!media || typeof media !== "object" ||
        (media.add !== undefined && (!Array.isArray(media.add) || media.add.length > 6)) ||
        (media.remove !== undefined && (!Array.isArray(media.remove) ||
          media.remove.length > 50 || media.remove.some((value: unknown) => !Number.isInteger(value))))) {
      throw new Error("Invalid media update");
    }
    for (const item of media.add ?? []) {
      const url = typeof item === "string" ? item : item?.url;
      if (typeof url !== "string") throw new Error("Invalid media update");
      StorageService.assertEntityFile(url, type, id);
    }
  }

  private async validateEventDates(
    eventId: number,
    data: Record<string, any>
  ): Promise<void> {
    if (data.start_date === undefined && data.end_date === undefined) return;

    const { data: event, error } = await this.db
      .from("events")
      .select("start_date, end_date")
      .eq("id", eventId)
      .maybeSingle();

    if (error) throw error;
    if (!event) throw new Error("Event not found");

    const startDate = new Date(data.start_date ?? event.start_date);
    const endDate = new Date(data.end_date ?? event.end_date);
    assertValidEventDates(startDate, endDate);
  }

  private getMediaPayload(update: EntityUpdate): MediaUpdatePayload {
    const media = update.data?.media;

    if (!media || typeof media !== "object") {
      return {};
    }

    return media as MediaUpdatePayload;
  }

  private normalizeAddItems(
    addItems: Array<string | MediaAddItem>
  ): MediaAddItem[] {
    return addItems.map((item, index) => {
      if (typeof item === "string") {
        return {
          url: item,
          type: this.inferMediaTypeFromUrl(item),
          is_primary: index === 0,
        };
      }

      return {
        url: item.url,
        type: item.type ?? this.inferMediaTypeFromUrl(item.url),
        is_primary: item.is_primary ?? index === 0,
      };
    });
  }

  private inferMediaTypeFromUrl(url: string): MediaType {
    const cleanUrl = url.split("?")[0]!.split("#")[0]!.toLowerCase();

    if (cleanUrl.endsWith(".pdf")) return "file";

    if (
      cleanUrl.endsWith(".jpg") ||
      cleanUrl.endsWith(".jpeg") ||
      cleanUrl.endsWith(".png") ||
      cleanUrl.endsWith(".webp") ||
      cleanUrl.endsWith(".gif")
    ) {
      return "image";
    }

    if (
      cleanUrl.endsWith(".mp4") ||
      cleanUrl.endsWith(".webm") ||
      cleanUrl.endsWith(".mov")
    ) {
      return "video";
    }

    return "file";
  }

  private async cleanupAddedMediaFiles(update: EntityUpdate): Promise<void> {
    this.validateAddedMedia(update.entity_type, update.entity_id, update.data);
    const media = this.getMediaPayload(update);
    const addItems = this.normalizeAddItems(media.add ?? []);

    if (addItems.length === 0) return;

    const urls = addItems.map((item) => item.url);
    const { data: existing, error } = await this.db.from("media").select("url").in("url", urls);
    if (error) throw error;
    const stored = new Set((existing ?? []).map(row => row.url));
    await this.deleteStorageFiles(urls.filter(url => !stored.has(url)));
  }

  private async syncApprovedMedia(update: EntityUpdate): Promise<void> {
    this.validateAddedMedia(update.entity_type, update.entity_id, update.data);
    const media = this.getMediaPayload(update);

    const addItems = this.normalizeAddItems(media.add ?? []);
    const removeIds = Array.isArray(media.remove) ? media.remove : [];

    if (removeIds.length > 0) {
      await this.removeExistingMedia(update, removeIds);
    }

    if (addItems.length > 0) {
      await this.insertAddedMedia(update, addItems);
    }
  }

  private async syncApprovedRelations(update: EntityUpdate): Promise<void> {
    const data = update.data ?? {};

    if (update.entity_type === "business") {
      await this.syncBusinessSocials(update.entity_id, data.socials);
      await this.syncBusinessHours(update.entity_id, data.hours);
      await this.syncBusinessTransport(update.entity_id, data.transport, data);
      return;
    }

    if (update.entity_type === "event") {
      await this.syncEventTransport(update.entity_id, data.transport, data);
      return;
    }
  }

  private async syncBusinessSocials(
    businessId: number,
    socials: unknown
  ): Promise<void> {
    if (!Array.isArray(socials)) {
      return;
    }

    const items = socials
      .map((item) => {
        if (!item || typeof item !== "object") return null;

        const raw = item as Partial<SocialUpdateItem>;
        const platform = typeof raw.platform === "string" ? raw.platform.trim().toLowerCase() : "";
        const url = typeof raw.url === "string" ? raw.url.trim() : "";

        if (!platform || !url) return null;

        return { platform, url };
      })
      .filter((item): item is SocialUpdateItem => Boolean(item));

    await this.socialLinksService.replaceAllByBusiness(businessId, items);
  }

  private async syncBusinessHours(
    businessId: number,
    hours: unknown
  ): Promise<void> {
    if (!Array.isArray(hours)) {
      return;
    }

    const items = hours
      .map((item) => {
        if (!item || typeof item !== "object") return null;

        const raw = item as Partial<OpeningUpdateItem>;
        const week_day = typeof raw.week_day === "string" ? raw.week_day : "";
        const start_time = typeof raw.start_time === "string" ? raw.start_time : "";
        const end_time = typeof raw.end_time === "string" ? raw.end_time : "";

        if (!week_day || !start_time || !end_time) return null;

        return {
          entity_type: "business",
          entity_id: businessId,
          week_day,
          start_time,
          end_time,
        };
      })
      .filter(
        (item): item is {
          entity_type: OpeningEntity;
          entity_id: number;
          week_day: string;
          start_time: string;
          end_time: string;
        } => Boolean(item)
      );

    await this.openingHoursService.replaceAll(
      "business",
      businessId,
      items as any
    );
  }

  private async syncBusinessTransport(
    businessId: number,
    transport: unknown,
    data?: Record<string, any>
  ): Promise<void> {
    const latitude = Number(data?.latitude);
    const longitude = Number(data?.longitude);

    if (Number.isFinite(latitude) && Number.isFinite(longitude)) {
      await this.transportRelationsService.refreshNearby({
        entityType: "business",
        entityId: businessId,
        latitude,
        longitude,
      });
      return;
    }

    if (!Array.isArray(transport)) {
      return;
    }

    const lineIds = transport
      .map((item) => {
        const n = typeof item === "string" ? Number(item) : item;
        return Number.isFinite(n) ? Number(n) : null;
      })
      .filter((id): id is number => id !== null);

    await this.transportRelationsService.replaceLines(
      "business",
      businessId,
      lineIds
    );
  }

  private async syncEventTransport(
    eventId: number,
    transport: unknown,
    data?: Record<string, any>
  ): Promise<void> {
    const latitude = Number(data?.latitude);
    const longitude = Number(data?.longitude);

    if (Number.isFinite(latitude) && Number.isFinite(longitude)) {
      await this.transportRelationsService.refreshNearby({
        entityType: "event",
        entityId: eventId,
        latitude,
        longitude,
      });
      return;
    }

    if (!Array.isArray(transport)) {
      return;
    }

    const lineIds = transport
      .map((item) => {
        const n = typeof item === "string" ? Number(item) : item;
        return Number.isFinite(n) ? Number(n) : null;
      })
      .filter((id): id is number => id !== null);

    await this.transportRelationsService.replaceLines(
      "event",
      eventId,
      lineIds
    );
  }

  private async removeExistingMedia(
    update: EntityUpdate,
    removeIds: number[]
  ): Promise<void> {
    const { data, error } = await this.db
      .from("media")
      .select("id, url")
      .eq("entity_type", update.entity_type)
      .eq("entity_id", update.entity_id)
      .in("id", removeIds);

    if (error) throw error;

    const urls = (data ?? [])
      .map((row) => row.url)
      .filter((url): url is string => typeof url === "string" && url.length > 0);

    const deleteRes = await this.db
      .from("media")
      .delete()
      .eq("entity_type", update.entity_type)
      .eq("entity_id", update.entity_id)
      .in("id", removeIds);

    if (deleteRes.error) throw deleteRes.error;

    await this.deleteStorageFiles(urls);
  }

  private async insertAddedMedia(
    update: EntityUpdate,
    addItems: MediaAddItem[]
  ): Promise<void> {
    if (addItems.length === 0) return;

    const rows = addItems.map((item, index) => ({
      entity_type: update.entity_type,
      entity_id: update.entity_id,
      url: item.url,
      type: item.type,
      is_primary: item.is_primary ?? index === 0,
    }));

    const { error } = await this.db.from("media").insert(rows);

    if (error) throw error;
  }

  private async deleteStorageFiles(urls: string[]): Promise<void> {
    if (urls.length === 0) return;

    const uniquePaths = [...new Set(urls)]
      .map((url) => {
        try {
          return StorageService.extractFilePath(url);
        } catch {
          return null;
        }
      })
      .filter((path): path is string => Boolean(path));

    await Promise.all(
      uniquePaths.map((path) => StorageService.deleteFile(path))
    );
  }

  private async callApproveRPC(
    update: EntityUpdate,
    adminId: string,
    comment?: string
  ): Promise<void> {
    const rpcMap: Record<UpdateEntityType, string> = {
      business: "approve_business_update",
      event: "approve_event_update",
      product: "approve_product_update",
      certification: "approve_certification_update",
    };

    const rpc = rpcMap[update.entity_type];

    if (!rpc) {
      throw new Error("Unsupported entity type");
    }

    const { error } = await this.db.rpc(rpc, {
      p_update_id: update.id,
      p_admin_id: adminId,
      p_comment: comment ?? null,
    });

    if (error) throw error;
  }

  private async callRejectRPC(
    update: EntityUpdate,
    adminId: string,
    comment?: string
  ): Promise<void> {
    const { error } = await this.db.rpc("reject_entity_update", {
      p_update_id: update.id,
      p_admin_id: adminId,
      p_comment: comment ?? null,
    });

    if (error) throw error;
  }

  async getAll(): Promise<EntityUpdate[]> {
    return this.dao.findAll();
  }

  async getById(id: number): Promise<EntityUpdate | null> {
    return this.dao.findById(id);
  }

  async getByStatus(status: ApprovalStatus) {
    return this.dao.findByStatus(status);
  }

  async getByEntity(
    type: UpdateEntityType,
    id: number,
    actor?: { id: string; role: string }
  ) {
    if (actor) {
      await this.ownershipService.validate(type, id, actor);
    }

    return this.dao.findByEntity(type, id);
  }

  async getByCreator(user_id: string) {
    return this.dao.findByCreator(user_id);
  }
}
