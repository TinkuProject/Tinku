import { MediaEntityType, MediaType } from "../constants/enums.constants";

export interface Media {
    id: number;
    entity_id: string;
    entity_type: MediaEntityType;
    url: string;
    type: MediaType;
    description?: string | null;
    is_primary: boolean;
    display_order: number;

    created_at: Date;
    updated_at?: Date | null;
}