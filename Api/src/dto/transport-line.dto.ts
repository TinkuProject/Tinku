import { BasicStatus } from "../constants/enums.constants";

export interface TransportLine {
  id: number;
  vehicle_type_id: number;
  name: string;
  status: BasicStatus;

  created_at: Date;
  updated_at?: Date | null;
}