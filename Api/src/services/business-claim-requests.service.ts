import { BusinessClaimRequestsDAO } from "../dao/business-claim-requests.dao";
import { BusinessesDAO } from "../dao/businesses.dao";
import { AuditLogsDAO } from "../dao/audit-logs.dao";
import { BusinessClaimRequest } from "../dto/business-claim-request.dto";
import { CreateBusinessClaimRequestInput, ReviewBusinessClaimRequestInput,
} from "../validation/business-claim-requests.validation";
import { NotificationsService } from "./notifications.service";
import { buildStatusNotification } from "../helper/notification.helper";
import { StorageService } from "./storage.service";
import {
  Actor,
  assertOwnershipAccess,
  isPrivileged,
} from "../helper/role.helper";

export class BusinessClaimRequestsService {
  constructor(
    private dao: BusinessClaimRequestsDAO,
    private businessDao: BusinessesDAO,
    private auditDao?: AuditLogsDAO,
    private notificationsService?: NotificationsService
  ) { }

  async create(
    userId: string,
    data: CreateBusinessClaimRequestInput
  ): Promise<BusinessClaimRequest> {
    for (const document of data.documents) {
      StorageService.assertEntityFile(document, "business_claim_requests", userId);
    }
    // evitar duplicados
    const exists = await this.dao.existsPending(
      userId,
      data.business_id
    );

    if (exists) {
      throw new Error(
        "You already have a pending request for this business"
      );
    }

    const business = await this.businessDao.findById({
      id: data.business_id,
    });

    if (!business) {
      throw new Error("Business not found");
    }

    if (business.owner_id) {
      throw new Error("Business already has an owner");
    }

    // evitar reclamar tu propio negocio
    if (business.owner_id === userId) {
      throw new Error("You already own this business");
    }

    const request = await this.dao.create(userId, data);

    await this.auditDao?.create({
      user_id: userId,
      action: "business_claim_created",
      entity_type: "business_claim_request",
      entity_id: request.id,
      details: {
        business_id: request.business_id,
        requested_owner_id: request.user_id,
      },
    });

    await this.notificationsService?.broadcastToAdmins({
      sender_id: userId,
      message: `Nuevo reclamo pendiente para "${business.name}".`,
      type: "business_claim",
      entity_type: "business_claim_request",
      entity_id: request.id,
      route: "/adminBusinessClaims",
    });

    return this.signDocuments(request);
  }

  async review(
    id: number,
    reviewerId: string,
    data: ReviewBusinessClaimRequestInput
  ): Promise<BusinessClaimRequest> {
    const existing = await this.dao.findById(id);

    if (!existing) {
      throw new Error("Request not found");
    }

    if (existing.status !== "pending") {
      throw new Error("Request already reviewed");
    }

    const wasApproved = data.status === "approved";

    const reviewed = await this.dao.reviewAtomically(id, reviewerId, data);

    await this.auditDao?.create({
      user_id: reviewerId,
      action: wasApproved
        ? "business_claim_approved"
        : "business_claim_rejected",
      entity_type: "business_claim_request",
      entity_id: reviewed.id,
      details: {
        business_id: reviewed.business_id,
        requested_owner_id: reviewed.user_id,
        status: reviewed.status,
        comment: data.comment ?? null,
        rejected_competing_claims: wasApproved,
      },
    });

    const businessName =
      reviewed.business?.name ?? existing.business?.name ?? `Negocio ${reviewed.business_id}`;
    const notif = buildStatusNotification({
      entityLabel: "Reclamo de negocio",
      entityName: businessName,
      status: wasApproved ? "approved" : "rejected",
      ...(data.comment?.trim()
        ? { adminMessage: data.comment.trim() }
        : {}),
    });

    await this.notificationsService?.createSafely({
      user_id: reviewed.user_id,
      sender_id: reviewerId,
      title: notif.title,
      message: notif.message,
      type: "business_claim",
      entity_type: "business_claim_request",
      entity_id: reviewed.id,
      route: "/claimBusiness",
      read: false,
    });

    return this.signDocuments(reviewed);
  }

  async getAll(limit = 50, offset = 0): Promise<BusinessClaimRequest[]> {
    const safeLimit = Math.min(limit, 100);
    return Promise.all((await this.dao.findAll(safeLimit, offset)).map(row => this.signDocuments(row)));
  }

  async getById(
    id: number,
    actor?: Actor
  ): Promise<BusinessClaimRequest> {
    const req = await this.dao.findById(id);

    if (!req) {
      throw new Error("Request not found");
    }

    if (actor) {
      assertOwnershipAccess(req.user_id, actor, "Request not found");
    }

    return this.signDocuments(req);
  }

  async getByUser(
    userId: string,
    limit = 50,
    offset = 0
  ): Promise<BusinessClaimRequest[]> {
    const safeLimit = Math.min(limit, 100);
    return Promise.all((await this.dao.findByUser(userId, safeLimit, offset)).map(row => this.signDocuments(row)));
  }

  async getByBusiness(
    businessId: number,
    limit = 50,
    offset = 0,
    actor?: Actor
  ): Promise<BusinessClaimRequest[]> {
    const safeLimit = Math.min(limit, 100);
    const rows = await this.dao.findByBusiness(
      businessId,
      safeLimit,
      offset,
      actor && !this.isAdmin(actor) ? actor.id : undefined
    );
    return Promise.all(rows.map(row => this.signDocuments(row)));
  }

  async getPending(): Promise<BusinessClaimRequest[]> {
    return Promise.all((await this.dao.findPending()).map(row => this.signDocuments(row)));
  }

  private async signDocuments(row: BusinessClaimRequest): Promise<BusinessClaimRequest> {
    return { ...row, documents: await Promise.all(row.documents.map(url => {
      StorageService.assertEntityFile(url, "business_claim_requests", row.user_id);
      return StorageService.signedReadUrl(url);
    })) };
  }

  private isAdmin(actor: Actor): boolean {
    return isPrivileged(actor.role);
  }
}
