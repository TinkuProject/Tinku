import { ApprovalStatus } from "../constants/enums.constants";
import { Business } from "./business.dto";

export interface BusinessClaimRequest {
    id: number;
    business_id: number;
    user_id: string;
    status: ApprovalStatus;
    comment?: string | null;
    documents: string[];
    reviewed_by?: string | null;
    reviewed_at?: Date | null;
    business?: Business | null;

    created_at: Date;
}
