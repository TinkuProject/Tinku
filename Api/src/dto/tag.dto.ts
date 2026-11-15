import { BasicStatus } from "../constants/enums.constants";

export interface Tag {
  id: number;
  name: string;
  description?: string | null;
  status: BasicStatus;

  created_at: Date;
  updated_at?: Date | null;
}