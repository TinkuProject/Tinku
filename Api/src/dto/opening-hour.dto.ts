import { OpeningEntity, WeekDay } from "../constants/enums.constants";

export interface OpeningHour {
  id: number;
  entity_type: OpeningEntity;
  entity_id: number;
  week_day: WeekDay;
  start_time: Date; // HH:mm:ss
  end_time: Date;

  created_at: Date;
  updated_at?: Date | null;
}