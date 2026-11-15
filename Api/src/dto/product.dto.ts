import { ProductStatus } from "../constants/enums.constants";

export interface Product {
  id: number;
  business_id: number;
  category_id: number;
  name: string;
  description?: string | null;
  price?: number | null;
  tinku_price?: number | null;
  stock?: number | null;
  volume_tier?: "small" | "medium" | "large" | null;
  status: ProductStatus;

  created_at: Date;
  updated_at?: Date | null;
}
