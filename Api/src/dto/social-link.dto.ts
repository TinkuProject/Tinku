export interface SocialLink {
  id: number;
  business_id: number;
  platform: string;
  url: string;

  created_at: Date;
  updated_at?: Date | null;
}