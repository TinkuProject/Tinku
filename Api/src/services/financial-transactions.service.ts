import { FinancialTransactionsDAO } from "../dao/financial-transactions.dao";
import { FinancialTransaction } from "../dto/financial-transaction.dto";
import {
  TransactionCreateInput, TransactionUpdateInput, TransactionIdInput,
} from "../validation/financial-transactions.validation";
import { TransactionType, TransactionStatus } from "../constants/enums.constants";

export class FinancialTransactionsService {
  constructor(private readonly dao: FinancialTransactionsDAO) { }

  async create(
    input: TransactionCreateInput,
    user_id: string
  ): Promise<FinancialTransaction> {
    // user siempre backend
    if (input.type !== "spend" && input.type !== "purchase") {
      throw new Error("Invalid transaction type for this operation");
    }

    return this.dao.create({
      ...input,
      user_id,
    });
  }

  async getById(
    input: TransactionIdInput
  ): Promise<FinancialTransaction> {
    const tx = await this.dao.findById(input);
    if (!tx) throw new Error("Transaction not found");

    return tx;
  }

  getByUser(
    user_id: string,
    filters?: {
      type?: TransactionType;
      status?: TransactionStatus;
    }
  ): Promise<FinancialTransaction[]> {
    return this.dao.findByUser(user_id, filters);
  }

  async getLatestByUser(userId: string) {
    return this.dao.findLatestByUser(userId, 5);
  }

  getByPayment(payment_id: number): Promise<FinancialTransaction[]> {
    return this.dao.findByPayment(payment_id);
  }

  getByType(type: TransactionType): Promise<FinancialTransaction[]> {
    return this.dao.findByType(type);
  }

  getByStatus(status: TransactionStatus): Promise<FinancialTransaction[]> {
    return this.dao.findByStatus(status);
  }

  getPendingByReferenceAndPurpose(referenceId: number, purpose: string) {
    return this.dao.findByReferenceAndPurpose({
      reference_id: referenceId,
      purpose,
      status: "pending",
    });
  }

  // =========================
  // UPDATE (MUY LIMITADO)
  // =========================
  async update(
    input: TransactionUpdateInput & TransactionIdInput
  ): Promise<FinancialTransaction> {
    const tx = await this.dao.findById(input);
    if (!tx) throw new Error("Transaction not found");

    return this.dao.update(input);
  }

  exists(input: TransactionIdInput): Promise<boolean> {
    return this.dao.exists(input);
  }
}