import { ReviewEntityType } from "../constants/enums.constants";
import { ReviewsDAO } from "../dao/reviews.dao";
import { Review } from "../dto/review.dto";
import { ReviewCreateInput, ReviewUpdateInput } from "../validation/reviews.validation";
import { NotificationsService } from "./notifications.service";
import {
  Actor,
  assertDirectOwner,
  assertOwnershipAccess,
} from "../helper/role.helper";

export class ReviewsService {
  constructor(
    private dao: ReviewsDAO,
    private notificationsService?: NotificationsService
  ) {}

  async create(
    userId: string,
    data: ReviewCreateInput
  ): Promise<Review> {
    const existing = await this.dao.findExisting(
      userId,
      data.entity_type,
      data.entity_id
    );

    if (existing) {
      throw new Error("User already reviewed this entity");
    }

    await this.validateEventReviewPermission(
      userId,
      data.entity_type,
      data.entity_id
    );

    const review = await this.dao.create(userId, data);
    await this.notifyOwnerAboutReview(userId, review);

    return review;
  }

  getAll(): Promise<Review[]> {
    return this.dao.getAll();
  }

  async getById(id: number): Promise<Review> {
    const review = await this.dao.getById(id);

    if (!review) {
      throw new Error("Review not found");
    }

    return review;
  }

  getByEntity(
    entityType: ReviewEntityType,
    entityId: number
  ): Promise<Review[]> {
    return this.dao.getByEntity(entityType, entityId);
  }

  async getByEntities(
    entityType: ReviewEntityType,
    entityIds: number[]
  ): Promise<Record<number, Review[]>> {
    return this.dao.getByEntities(entityType, entityIds);
  }

  getByUser(userId: string): Promise<Review[]> {
    return this.dao.getByUser(userId);
  }

  getManagedByOwner(actor: Actor): Promise<Review[]> {
    return this.dao.getManagedByOwner(actor.id, actor.role);
  }

  async reply(id: number, actor: Actor, reply: string): Promise<Review> {
    const existing = await this.dao.getById(id);

    if (!existing) {
      throw new Error("Review not found");
    }

    const ownerId = await this.dao.getOwnerIdForReview(id);
    assertOwnershipAccess(ownerId, actor, "Review target not found");

    if (existing.user_id === actor.id) {
      throw new Error("Cannot reply to your own review");
    }

    const updated = await this.dao.reply(id, actor.id, reply);
    await this.notifyReviewerAboutReply(actor.id, updated);

    return updated;
  }

  private async notifyOwnerAboutReview(
    reviewerId: string,
    review: Review
  ): Promise<void> {
    if (!this.notificationsService) return;

    try {
      const target = await this.dao.getNotificationTargetForEntity(
        review.entity_type,
        review.entity_id
      );

      if (!target?.owner_id || target.owner_id === reviewerId) return;

      const entityName = target.entity_name ?? "tu publicación";
      const targetLabel = this.labelForTarget(target.entity_kind);

      await this.notificationsService.create({
        user_id: target.owner_id,
        sender_id: reviewerId,
        title: `Nueva reseña en tu ${targetLabel}`,
        message: `Recibiste una nueva reseña en "${entityName}".`,
        type: "review",
        entity_type: target.entity_kind,
        entity_id: target.entity_id,
        route: "/manageReviews",
        read: false,
      });
    } catch (err) {
      console.warn("Could not notify review owner", err);
    }
  }

  private async notifyReviewerAboutReply(
    actorId: string,
    review: Review
  ): Promise<void> {
    if (!this.notificationsService) return;

    try {
      const target = await this.dao.getNotificationTargetForReview(review.id);
      const reviewerId = target?.reviewer_user_id ?? review.user_id;

      if (!reviewerId || reviewerId === actorId) return;

      const entityName = target?.entity_name ?? "tu reseña";

      await this.notificationsService.create({
        user_id: reviewerId,
        sender_id: actorId,
        title: "Respondieron tu reseña",
        message: `Recibiste una respuesta a tu reseña en "${entityName}".`,
        type: "review",
        entity_type: target?.entity_kind ?? null,
        entity_id: target?.entity_id ?? null,
        route: "/notifications",
        read: false,
      });
    } catch (err) {
      console.warn("Could not notify review reply", err);
    }
  }

  private labelForTarget(kind?: string | null): string {
    switch (kind) {
      case "event":
        return "evento";
      case "product":
        return "producto";
      case "tourist_place":
        return "lugar turístico";
      case "service":
        return "servicio";
      default:
        return "negocio";
    }
  }

  async update(
    id: number,
    userId: string,
    data: ReviewUpdateInput
  ): Promise<Review> {
    const existing = await this.dao.getById(id);

    if (!existing) {
      throw new Error("Review not found");
    }

    assertDirectOwner(existing.user_id, userId, "Review not found");

    await this.validateEventReviewPermission(
      userId,
      existing.entity_type,
      existing.entity_id
    );

    return this.dao.update(id, data);
  }

  private async validateEventReviewPermission(
    userId: string,
    entityType: ReviewEntityType,
    entityId: number
  ): Promise<void> {
    if (entityType !== "event") return;

    const hasReservation = await this.dao.hasConfirmedEventReservation(
      userId,
      entityId
    );

    if (!hasReservation) {
      throw new Error("Only confirmed event attendees can review this event");
    }
  }

  async softDelete(id: number, actor: Actor): Promise<Review> {
    const existing = await this.dao.getById(id);

    if (!existing) {
      throw new Error("Review not found");
    }

    assertOwnershipAccess(existing.user_id, actor, "Review not found");

    return this.dao.softDelete(id);
  }
}
