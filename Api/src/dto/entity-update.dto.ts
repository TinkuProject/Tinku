import { ApprovalStatus, UpdateEntityType } from "../constants/enums.constants";

export interface EntityUpdate {
  id: number;
  entityType: UpdateEntityType;
  entityId: number;
  creatorId: string;
  data: Record<string, any>;

  status: ApprovalStatus;
  comment?: string | null;
  reviewedBy?: string | null;
  reviewedAt?: Date | null;

  createdAt: Date;
}