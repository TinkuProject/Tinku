import { ReviewEntityType, ReviewStatus } from "../constants/enums.constants";

export interface Review {
    id: number;
    user_id: string;
    entity_type: ReviewEntityType;
    entity_id: number;
    rating: number;
    comment?: string | null;
    owner_reply?: string | null;
    owner_reply_user_id?: string | null;
    owner_reply_at?: Date | null;
    entity_name?: string | null;
    entity_kind?: string | null;
    entity_business_id?: number | null;
    reviewer_username?: string | null;
    reviewer_first_name?: string | null;
    reviewer_last_name?: string | null;
    status: ReviewStatus;

    created_at: Date;
    updated_at?: Date | null;
}
