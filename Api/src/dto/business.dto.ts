import { BusinessType, BusinessStatus } from "../constants/enums.constants";

export interface Business {
  id: number;
  category_id: number;
  owner_id?: string | null;
  name: string;
  nit?: string | null;
  description?: string | null;
  phone?: string | null;
  email?: string | null;
  business_type: BusinessType;
  address: string;

  location: {
    latitude: number;
    longitude: number;
  };

  website?: string | null;
  validated: boolean;
  status: BusinessStatus;

  created_at: Date;
  updated_at?: Date | null;
}