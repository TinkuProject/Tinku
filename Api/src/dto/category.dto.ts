import { BasicStatus, CategoryEntityType, BusinessType } from "../constants/enums.constants";

export interface Category {
  id: number;
  name: string;
  entity_type: CategoryEntityType;
  business_type?: BusinessType | null; // solo cuando entity_type = 'business'
  status: BasicStatus;

  created_at: Date;
  updated_at?: Date | null;
}