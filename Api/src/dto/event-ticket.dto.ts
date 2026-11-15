import { EventTicketStatus } from "../constants/enums.constants";

export interface EventTicketDay {
  id: string;
  ticket_id: string;
  event_id: number;
  event_date: string;
  status: EventTicketStatus;
  valid_from: Date;
  valid_until: Date;
  used_at?: Date | null;
  used_by?: string | null;
  created_at: Date;
  updated_at?: Date | null;
}

export interface EventTicket {
  id: string;
  reservation_id: number;
  event_id: number;
  user_id: string;
  attendee_index: number;
  status: EventTicketStatus;
  created_at: Date;
  updated_at?: Date | null;
  days?: EventTicketDay[];
  attendee?: {
    id: string;
    username: string;
    first_name?: string | null;
    last_name?: string | null;
    ci?: string | null;
  } | null;
}

export interface EventTicketQr {
  ticket_day_id: string;
  ticket_id: string;
  reservation_id: number;
  event_id: number;
  event_name: string;
  event_date: string;
  valid_from: Date;
  valid_until: Date;
  qr_token: string;
  qr_payload: Record<string, unknown>;
}

export interface EventTicketCheckInResult {
  status: "valid" | "duplicate" | "expired" | "invalid" | "not_yet_valid";
  reason?: string;
  ticket_day_id?: string;
  ticket_id?: string;
  reservation_id?: number;
  event_id?: number;
  event_name?: string;
  event_date?: string;
  used_at?: string;
  valid_from?: string;
  valid_until?: string;
}
