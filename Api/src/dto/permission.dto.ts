export interface Permission {
  id: number;
  code: string;
  description?: string | null;

  created_at: Date;
}