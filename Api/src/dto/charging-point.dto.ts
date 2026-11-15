import { ChargingPointStatus } from "../constants/enums.constants";

export interface ChargingPoint {
  id: number;
  name: string;
  address: string;
  location: {
    latitude: number;
    longitude: number;
  };
  status: ChargingPointStatus;

  created_at: Date;
  updated_at?: Date | null;
}