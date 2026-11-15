import { TransactionType, TransactionStatus } from "../constants/enums.constants";

export interface FinancialTransaction {
    id: number;
    user_id: string;
    type: TransactionType;
    status: TransactionStatus;
    amount: number;
    currency: string;
    purpose?: string | null;
    reference_id?: number | null;
    payment_id?: number | null;
    description?: string | null;

    created_at: Date;
    updated_at?: Date | null;
}