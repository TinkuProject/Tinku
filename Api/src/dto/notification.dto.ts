export interface Notification {
  id: number;
  user_id: string;
  sender_id?: string | null;
  title?: string | null;
  message: string;
  type?: string | null;
  entity_type?: string | null;
  entity_id?: number | null;
  route?: string | null;
  read: boolean;

  created_at: Date;
}
