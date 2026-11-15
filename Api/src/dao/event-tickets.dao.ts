import { DbClient } from "../types/db-client";
import { createHash, randomBytes } from "crypto";
import {
  EventTicket,
  EventTicketCheckInResult,
  EventTicketDay,
  EventTicketQr,
} from "../dto/event-ticket.dto";

export class EventTicketsDAO {
  private table = "event_tickets";

  constructor(private readonly db: DbClient) {}

  private mapDay(row: any): EventTicketDay {
    return {
      id: row.id,
      ticket_id: row.ticket_id,
      event_id: row.event_id,
      event_date: row.event_date,
      status: row.status,
      valid_from: new Date(row.valid_from),
      valid_until: new Date(row.valid_until),
      used_at: row.used_at ? new Date(row.used_at) : null,
      used_by: row.used_by ?? null,
      created_at: new Date(row.created_at),
      updated_at: row.updated_at ? new Date(row.updated_at) : null,
    };
  }

  private mapTicket(row: any): EventTicket {
    const nestedDays = row.event_ticket_days ?? row.days ?? [];
    const attendee = row.users ?? row.attendee ?? null;

    return {
      id: row.id,
      reservation_id: row.reservation_id,
      event_id: row.event_id,
      user_id: row.user_id,
      attendee_index: row.attendee_index,
      status: row.status,
      created_at: new Date(row.created_at),
      updated_at: row.updated_at ? new Date(row.updated_at) : null,
      days: Array.isArray(nestedDays)
        ? nestedDays
            .map((day: any) => this.mapDay(day))
            .sort(
              (a: EventTicketDay, b: EventTicketDay) =>
                a.valid_from.getTime() - b.valid_from.getTime()
            )
        : [],
      attendee: attendee
        ? {
            id: attendee.id,
            username: attendee.username,
            first_name: attendee.first_name ?? null,
            last_name: attendee.last_name ?? null,
            ci: attendee.ci ?? null,
          }
        : null,
    };
  }

  private mapQr(row: any): EventTicketQr {
    return {
      ticket_day_id: row.ticket_day_id,
      ticket_id: row.ticket_id,
      reservation_id: row.reservation_id,
      event_id: row.event_id,
      event_name: row.event_name,
      event_date: row.event_date,
      valid_from: new Date(row.valid_from),
      valid_until: new Date(row.valid_until),
      qr_token: row.qr_token,
      qr_payload: row.qr_payload,
    };
  }

  async findMine(userId: string): Promise<EventTicket[]> {
    await this.ensureTicketsForUser(userId);

    const { data, error } = await this.db
      .from(this.table)
      .select("*, event_ticket_days(*)")
      .eq("user_id", userId)
      .order("created_at", { ascending: false });

    if (error) throw error;

    return (data ?? []).map((row) => this.mapTicket(row));
  }

  async findByReservation(reservationId: number): Promise<EventTicket[]> {
    await this.ensureTicketsForReservation(reservationId);

    const { data, error } = await this.db
      .from(this.table)
      .select("*, event_ticket_days(*)")
      .eq("reservation_id", reservationId)
      .order("attendee_index", { ascending: true });

    if (error) throw error;

    return (data ?? []).map((row) => this.mapTicket(row));
  }

  async findByEvent(eventId: number): Promise<EventTicket[]> {
    await this.ensureTicketsForEvent(eventId);

    const { data, error } = await this.db
      .from(this.table)
      .select("*, event_ticket_days(*), users:user_id(id, username, first_name, last_name, ci)")
      .eq("event_id", eventId)
      .order("created_at", { ascending: false });

    if (error) throw error;

    return (data ?? []).map((row) => this.mapTicket(row));
  }

  async findById(id: string): Promise<EventTicket | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*, event_ticket_days(*)")
      .eq("id", id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapTicket(data) : null;
  }

  private async ensureTicketsForReservation(
    reservationId: number
  ): Promise<void> {
    const { data: reservation, error: reservationError } = await this.db
      .from("reservations")
      .select("id, status")
      .eq("id", reservationId)
      .maybeSingle();

    if (reservationError) throw reservationError;
    if (!reservation || reservation.status !== "confirmed") return;

    await this.generateTicketsIfMissing(reservation.id);
  }

  private async ensureTicketsForUser(userId: string): Promise<void> {
    const { data, error } = await this.db
      .from("reservations")
      .select("id")
      .eq("user_id", userId)
      .eq("status", "confirmed");

    if (error) throw error;

    for (const reservation of data ?? []) {
      await this.generateTicketsIfMissing(reservation.id);
    }
  }

  private async ensureTicketsForEvent(eventId: number): Promise<void> {
    const { data, error } = await this.db
      .from("reservations")
      .select("id")
      .eq("event_id", eventId)
      .eq("status", "confirmed");

    if (error) throw error;

    for (const reservation of data ?? []) {
      await this.generateTicketsIfMissing(reservation.id);
    }
  }

  private async generateTicketsIfMissing(reservationId: number): Promise<void> {
    const { data: existing, error: existingError } = await this.db
      .from(this.table)
      .select("id")
      .eq("reservation_id", reservationId)
      .limit(1);

    if (existingError) throw existingError;
    if ((existing ?? []).length > 0) return;

    const { error } = await this.db.rpc(
      "generate_event_tickets_for_reservation",
      {
        p_reservation_id: reservationId,
      }
    );

    if (error) throw error;
  }

  async issueQr(ticketDayId: string, userId: string): Promise<EventTicketQr> {
    const ticketDay = await this.getTicketDayWithTicketAndEvent(ticketDayId);

    if (!ticketDay) {
      throw new Error("Ticket day not found");
    }

    const ticket = this.getNestedOne(ticketDay.event_tickets);
    const event = this.getNestedOne(ticketDay.events);

    if (!ticket) {
      throw new Error("Ticket not found");
    }

    if (ticket.user_id !== userId) {
      throw new Error("Unauthorized");
    }

    if (ticket.status !== "active") {
      throw new Error("Ticket is not active");
    }

    if (ticketDay.status === "used") {
      throw new Error("Ticket day already used");
    }

    if (ticketDay.status === "cancelled") {
      throw new Error("Ticket day cancelled");
    }

    if (!event) {
      throw new Error("Event not found");
    }

    if (new Date(ticketDay.valid_until) <= new Date()) {
      const refreshed = await this.refreshTicketDayWindowIfEventActive(
        ticketDayId,
        userId
      );

      if (!refreshed) {
        throw new Error("Ticket day expired");
      }

      return this.issueQr(ticketDayId, userId);
    }

    const token = randomBytes(32).toString("hex");
    const tokenHash = this.hashToken(token);

    const { error } = await this.db
      .from("event_ticket_days")
      .update({
        qr_token_hash: tokenHash,
        updated_at: new Date().toISOString(),
      })
      .eq("id", ticketDay.id);

    if (error) throw error;

    return this.mapQr({
      ticket_day_id: ticketDay.id,
      ticket_id: ticket.id,
      reservation_id: ticket.reservation_id,
      event_id: ticket.event_id,
      event_name: event.name,
      event_date: ticketDay.event_date,
      valid_from: ticketDay.valid_from,
      valid_until: ticketDay.valid_until,
      qr_token: token,
      qr_payload: {
        type: "event_checkin",
        token,
        ticket_day_id: ticketDay.id,
        ticket_id: ticket.id,
        reservation_id: ticket.reservation_id,
        event_id: ticket.event_id,
        event_name: event.name,
        event_date: ticketDay.event_date,
        valid_from: ticketDay.valid_from,
        valid_until: ticketDay.valid_until,
      },
    });
  }

  private async refreshTicketDayWindowIfEventActive(
    ticketDayId: string,
    userId: string
  ): Promise<boolean> {
    const { data: day, error: dayError } = await this.db
      .from("event_ticket_days")
      .select("id, ticket_id, event_id, used_at, event_tickets:ticket_id(user_id), events:event_id(start_date, end_date)")
      .eq("id", ticketDayId)
      .maybeSingle();

    if (dayError) throw dayError;
    if (!day) return false;

    const ownerId =
      (day as any).event_tickets?.user_id ??
      (Array.isArray((day as any).event_tickets)
        ? (day as any).event_tickets[0]?.user_id
        : null);

    if (ownerId !== userId || day.used_at) {
      return false;
    }

    const event =
      (day as any).events ??
      (Array.isArray((day as any).events)
        ? (day as any).events[0]
        : null);

    if (!event?.end_date || new Date(event.end_date) <= new Date()) {
      return false;
    }

    const { error } = await this.db
      .from("event_ticket_days")
      .update({
        valid_from: event.start_date,
        valid_until: event.end_date,
        status: "active",
        updated_at: new Date().toISOString(),
      })
      .eq("id", ticketDayId);

    if (error) throw error;

    return true;
  }

  async checkIn(input: {
    token: string;
    event_id: number;
    scanner_id: string;
  }): Promise<EventTicketCheckInResult> {
    const token = input.token.trim();

    if (!token) {
      return { status: "invalid", reason: "empty_token" };
    }

    const { data, error } = await this.db.rpc("check_in_event_ticket", {
      p_token: token,
      p_event_id: input.event_id,
      p_scanner_id: input.scanner_id,
    });

    if (error) throw error;

    return data as EventTicketCheckInResult;
  }

  private async getTicketDayWithTicketAndEvent(ticketDayId: string) {
    const { data, error } = await this.db
      .from("event_ticket_days")
      .select("*, event_tickets:ticket_id(*), events:event_id(*)")
      .eq("id", ticketDayId)
      .maybeSingle();

    if (error) throw error;

    return data;
  }

  private getNestedOne(value: any) {
    if (Array.isArray(value)) return value[0] ?? null;
    return value ?? null;
  }

  private hashToken(token: string): string {
    return createHash("sha256").update(token).digest("hex");
  }
}
