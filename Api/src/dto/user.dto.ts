import { UserRole, UserStatus } from "../constants/enums.constants";

export interface User {
  id: string;
  first_name?: string | null;
  last_name?: string | null;
  username: string;
  email: string;
  phone?: string | null;
  ci?: string | null;
  address?: string | null;

  location?: {
    latitude: number;
    longitude: number;
  } | null;

  role: UserRole;
  status: UserStatus;

  created_at: Date;
  updated_at?: Date | null;
}