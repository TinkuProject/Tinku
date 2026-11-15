import { ReservationStatus } from "../constants/enums.constants";

export interface Reservation {
  id: number;
  user_id: string;
  event_id: number;
  quantity: number;
  tinku_amount: number;
  status: ReservationStatus;

  created_at: Date;
  updated_at?: Date | null;
}