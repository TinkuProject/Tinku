import { BasicStatus } from "../constants/enums.constants";

export interface TouristPlace {
  id: number;
  category_id: number;
  name: string;
  description?: string | null;
  address?: string | null;
  created_by?: string | null;
  location: {
    latitude: number;
    longitude: number;
  };
  status: BasicStatus;

  created_at: Date;
  updated_at?: Date | null;
}
