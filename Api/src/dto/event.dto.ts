import { EventStatus } from "../constants/enums.constants";

export interface Event {
  id: number;
  business_id?: number | null;
  creator_id: string;
  category_id: number;
  name: string;
  description?: string | null;
  start_date: Date;
  end_date: Date;
  capacity?: number | null;
  attendees_count?: number;
  tinku_price?: number;
  address: string;
  location: {
    latitude: number;
    longitude: number;
  };

  status: EventStatus;
  created_at: Date;
  updated_at?: Date | null;
}