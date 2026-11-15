import { BasicStatus } from "../constants/enums.constants";

export interface Certification {
  id: number;
  business_id: number;
  name: string;
  license_number?: string | null;
  status: BasicStatus;

  created_at: Date;
  updated_at?: Date | null;
}
