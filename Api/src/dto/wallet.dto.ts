export interface Wallet {
  user_id: string;
  balance: number;

  created_at: Date;
  updated_at?: Date | null;
}