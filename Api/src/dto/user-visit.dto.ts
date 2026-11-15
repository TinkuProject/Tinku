import { VisitEntity, VisitType } from "../constants/enums.constants";

export interface UserVisit {
    id: number;
    user_id: string;
    entity_type: VisitEntity;
    entity_id: number;
    type: VisitType;

    created_at: Date;
}