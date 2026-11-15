import { PaymentsDAO } from "../dao/payments.dao";
import { Payment } from "../dto/payment.dto";
import {
  PaymentCreateInput,
  PaymentUpdateInput,
  PaymentIdInput,
} from "../validation/payments.validation";
import { PaymentStatus } from "../constants/enums.constants";
import { assertDirectOwner } from "../helper/role.helper";

export class PaymentsService {
  constructor(private readonly dao: PaymentsDAO) { }

  async create(
    input: PaymentCreateInput,
    user_id: string
  ): Promise<Payment> {
    if (input.method === "gateway" || input.external_reference || input.stripe_client_request_id || input.gateway_target_id) {
      throw new Error("Gateway payments must be processed by Stripe");
    }
    if (input.amount <= 0) {
      throw new Error("Amount must be positive");
    }

    return this.dao.create({
      ...input,
      user_id,
    });
  }

  async getById(input: PaymentIdInput): Promise<Payment> {
    const payment = await this.dao.findById(input);
    if (!payment) throw new Error("Payment not found");

    return payment;
  }

  getByUser(user_id: string): Promise<Payment[]> {
    return this.dao.findByUser(user_id);
  }

  getByStatus(status: PaymentStatus): Promise<Payment[]> {
    return this.dao.findByStatus(status);
  }

  async getByExternalReference(
    external_reference: string
  ): Promise<Payment> {
    const payment =
      await this.dao.findByExternalReference(external_reference);

    if (!payment) throw new Error("Payment not found");

    return payment;
  }

  // UPDATE STATUS (INTERNAL)
  async updateStatus(
    input: PaymentUpdateInput & PaymentIdInput
  ): Promise<Payment> {
    const payment = await this.dao.findById(input);
    if (!payment) throw new Error("Payment not found");

    if (input.status) {
      const validTransitions: Record<PaymentStatus, PaymentStatus[]> = {
        pending: ["approved", "rejected", "cancelled", "failed", "expired"],
        approved: [],
        rejected: [],
        cancelled: [],
        failed: [],
        expired: [],
      };

      if (!validTransitions[payment.status]?.includes(input.status)) {
        throw new Error("Invalid payment status transition");
      }
    }

    return this.dao.update(input);
  }

  // =========================
  // SOFT DELETE
  // =========================
  async softDelete(
    input: PaymentIdInput,
    user_id: string
  ): Promise<Payment> {
    const payment = await this.dao.findById(input);
    if (!payment) throw new Error("Payment not found");

    assertDirectOwner(payment.user_id, user_id, "Payment not found");

    if (payment.status === "approved") {
      throw new Error("Cannot delete approved payment");
    }

    if (payment.status === "cancelled") {
      throw new Error("Payment already cancelled");
    }

    return this.dao.update({
      id: payment.id,
      status: "cancelled",
    });
  }

  // =========================
  // EXISTS
  // =========================
  exists(input: PaymentIdInput): Promise<boolean> {
    return this.dao.exists(input);
  }
}
