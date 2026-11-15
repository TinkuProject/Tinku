import { CashoutRequestsDAO } from "../dao/cashout-requests.dao";
import { CashoutRequest } from "../dto/cashout-request.dto";
import {
  CreateCashoutRequestInput,
  ReviewCashoutRequestInput,
} from "../validation/cashout-requests.validation";
import { NotificationsService } from "./notifications.service";
import { buildStatusNotification } from "../helper/notification.helper";

export class CashoutRequestsService {
  constructor(
    private readonly dao: CashoutRequestsDAO,
    private readonly notificationsService?: NotificationsService
  ) {}

  async create(
    userId: string,
    input: CreateCashoutRequestInput
  ): Promise<CashoutRequest> {
    const request = await this.dao.create({
      user_id: userId,
      cashout_package_id: input.cashout_package_id,
      comment: input.comment ?? null,
    });

    const notif = buildStatusNotification({
      entityLabel: "Solicitud de retiro",
      entityName: `Retiro #${request.id}`,
      status: "pending",
    });

    await this.notificationsService?.createSafely({
      user_id: userId,
      title: notif.title,
      message: notif.message,
      type: "cashout",
      entity_type: "cashout_request",
      entity_id: request.id,
      route: "/walletBalance",
      read: false,
    });

    await this.notificationsService?.broadcastToAdmins({
      sender_id: userId,
      message: `Nueva solicitud de retiro pendiente: Retiro #${request.id}.`,
      type: "cashout",
      entity_type: "cashout_request",
      entity_id: request.id,
      route: "/adminCashoutRequests",
    });

    return request;
  }

  async approve(
    id: number,
    adminId: string,
    input: ReviewCashoutRequestInput
  ): Promise<CashoutRequest> {
    const request = await this.dao.approve({
      id,
      admin_id: adminId,
      comment: input.comment ?? null,
    });

    const notif = buildStatusNotification({
      entityLabel: "Solicitud de retiro",
      entityName: `Retiro #${request.id}`,
      status: "approved",
      ...(request.comment?.trim()
        ? { adminMessage: request.comment.trim() }
        : {}),
    });

    await this.notificationsService?.createSafely({
      user_id: request.user_id,
      sender_id: adminId,
      title: notif.title,
      message: notif.message,
      type: "cashout",
      entity_type: "cashout_request",
      entity_id: request.id,
      route: "/walletBalance",
      read: false,
    });

    return request;
  }

  async reject(
    id: number,
    adminId: string,
    input: ReviewCashoutRequestInput
  ): Promise<CashoutRequest> {
    const request = await this.dao.reject({
      id,
      admin_id: adminId,
      comment: input.comment ?? null,
    });

    const notif = buildStatusNotification({
      entityLabel: "Solicitud de retiro",
      entityName: `Retiro #${request.id}`,
      status: "rejected",
      ...(request.comment?.trim()
        ? { adminMessage: request.comment.trim() }
        : {}),
    });

    await this.notificationsService?.createSafely({
      user_id: request.user_id,
      sender_id: adminId,
      title: notif.title,
      message: notif.message,
      type: "cashout",
      entity_type: "cashout_request",
      entity_id: request.id,
      route: "/walletBalance",
      read: false,
    });

    return request;
  }

  getMine(userId: string): Promise<CashoutRequest[]> {
    return this.dao.findMine(userId);
  }

  getAll(limit = 50, offset = 0): Promise<CashoutRequest[]> {
    return this.dao.findAll(Math.min(limit, 100), offset);
  }

  getPending(): Promise<CashoutRequest[]> {
    return this.dao.findPending();
  }

  async getById(id: number): Promise<CashoutRequest> {
    const request = await this.dao.findById(id);

    if (!request) {
      throw new Error("Request not found");
    }

    return request;
  }
}
