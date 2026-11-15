import { ApprovalStatus, PaymentType } from "../constants/enums.constants";

export interface PaymentRequest {
  id: number;
  userId: string;
  paymentId: number;

  type: PaymentType;
  status: ApprovalStatus;
  targetId?: number | null; //coinPackageId - subscriptionId - null por partner request

  comment?: string | null;
  reviewedBy?: string | null;
  reviewedAt?: string | null;

  createdAt: string;
  updatedAt?: string | null;
}