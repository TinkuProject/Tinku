import { DbClient } from "../types/db-client";
import { PaymentRequestDAO } from "../dao/payment-requests.dao";
import { PaymentsDAO } from "../dao/payments.dao";
import { MediaDAO } from "../dao/media.dao";
import { CreatePaymentRequestInput, ApprovePaymentRequestInput, RejectPaymentRequestInput,
} from "../validation/payment-requests.validation";
import { NotificationsService } from "./notifications.service";
import { buildStatusNotification } from "../helper/notification.helper";
import { PaymentMethod } from "../constants/enums.constants";

export class PaymentRequestService {
  constructor(
    private readonly dao: PaymentRequestDAO,
    private readonly paymentsDao: PaymentsDAO,
    private readonly mediaDao: MediaDAO,
    private readonly db: DbClient,
    private readonly notificationsService: NotificationsService
  ) {}

  // =========================
  // GET ALL
  // =========================
  async getAll(
    status?: "pending" | "approved" | "rejected",
    paymentMethod?: PaymentMethod
  ) {
    if (status || paymentMethod) {
      return this.dao.findAllByFilters({
        ...(status ? { status } : {}),
        ...(paymentMethod ? { paymentMethod } : {}),
      });
    }

    return this.dao.findAll();
  }

  async getById(id: number) {
    const request = await this.dao.findById(id);

    if (!request) {
      throw new Error("Request not found");
    }

    return request;
  }

  async getMine(userId: string) {
    return this.dao.findByUser(userId);
  }

  async hasPendingPartnerUpgrade(userId: string) {
    return this.dao.hasPendingPartnerUpgrade(userId);
  }

  // =========================
  // CREATE
  // =========================
  async create(userId: string, input: CreatePaymentRequestInput) {
    const payment = await this.paymentsDao.findById({
      id: input.paymentId,
    });

    if (!payment) {
      throw new Error("Payment not found");
    }

    if (payment.method === "gateway") {
      throw new Error("Gateway payments must be processed by Stripe");
    }

    if (payment.user_id !== userId) {
      throw new Error("Payment does not belong to user");
    }

    if (payment.status !== "pending") {
      throw new Error("Payment must be pending");
    }

    if (payment.type !== input.type) {
      throw new Error("Invalid payment type");
    }

    const mediaList = await this.mediaDao.getByEntity(
      payment.id,
      "payment"
    );

    if (!mediaList || mediaList.length === 0) {
      throw new Error("Payment proof is required");
    }

    const request = await this.dao.create(userId, {
      paymentId: input.paymentId,
      type: input.type,
      ...(input.targetId !== undefined && { targetId: input.targetId }),
    });

    const notif = buildStatusNotification({
      entityLabel: "Solicitud de pago",
      entityName: `Pago #${payment.id}`,
      status: "pending",
    });

    await this.notificationsService.createSafely({
      user_id: userId,
      title: notif.title,
      message: notif.message,
      type: "payment",
      entity_type: "payment_request",
      entity_id: request.id,
      route: "/walletBalance",
      read: false,
    });

    await this.notificationsService.broadcastToAdmins({
      sender_id: userId,
      message: `Nueva solicitud de pago pendiente: Pago #${payment.id}.`,
    });

    return request;
  }

  // =========================
  // APPROVE
  // =========================
  async approve(adminId: string, input: ApprovePaymentRequestInput) {
    const request = await this.dao.findById(input.requestId);

    if (!request) {
      throw new Error("Request not found");
    }

    const { error } = await this.db.rpc("approve_payment_request", {
      p_request_id: request.id,
      p_admin_id: adminId,
      p_comment: input.comment ?? null,
    });

    if (error) throw error;

    const updated = await this.dao.findById(request.id);
    if (!updated) {
      throw new Error("Request not found");
    }

    const notif = buildStatusNotification({
      entityLabel: "Solicitud de pago",
      entityName: `Pago #${updated.paymentId}`,
      status: "approved",
      ...(updated.comment?.trim()
        ? { adminMessage: updated.comment.trim() }
        : {}),
    });

    await this.notificationsService.createSafely({
      user_id: updated.userId,
      sender_id: adminId,
      title: notif.title,
      message: notif.message,
      type: "payment",
      entity_type: "payment_request",
      entity_id: updated.id,
      route: "/walletBalance",
      read: false,
    });

    return updated;
  }

  // =========================
  // REJECT
  // =========================
  async reject(adminId: string, input: RejectPaymentRequestInput) {
    const request = await this.dao.findById(input.requestId);

    if (!request) {
      throw new Error("Request not found");
    }

    const { error } = await this.db.rpc("reject_payment_request", {
      p_request_id: request.id,
      p_admin_id: adminId,
      p_comment: input.comment ?? null,
    });

    if (error) throw error;

    const updated = await this.dao.findById(request.id);
    if (!updated) {
      throw new Error("Request not found");
    }

    const notif = buildStatusNotification({
      entityLabel: "Solicitud de pago",
      entityName: `Pago #${updated.paymentId}`,
      status: "rejected",
      ...(updated.comment?.trim()
        ? { adminMessage: updated.comment.trim() }
        : {}),
    });

    await this.notificationsService.createSafely({
      user_id: updated.userId,
      sender_id: adminId,
      title: notif.title,
      message: notif.message,
      type: "payment",
      entity_type: "payment_request",
      entity_id: updated.id,
      route: "/walletBalance",
      read: false,
    });

    return updated;
  }
}
