import { DbClient } from "../types/db-client";
import { Reservation } from "../dto/reservation.dto";
import { ReservationUpdateInput, ReservationIdInput } from "../validation/reservations.validation";

export class ReservationsDAO {
  private table = "reservations";
  constructor(private readonly db: DbClient) {}

  private mapToEntity(data: any): Reservation {
    return {
      id: data.id,
      user_id: data.user_id,
      event_id: data.event_id,
      quantity: data.quantity,
      tinku_amount: data.tinku_amount,
      status: data.status,
      created_at: new Date(data.created_at),
      updated_at: data.updated_at
        ? new Date(data.updated_at)
        : null,
    };
  }

  async createWithPayment(input: {
    user_id: string;
    event_id: number;
    quantity: number;
  }): Promise<Reservation> {
    const { data, error } = await this.db.rpc(
      "create_reservation_with_payment",
      {
        p_user_id: input.user_id,
        p_event_id: input.event_id,
        p_quantity: input.quantity,
      }
    );

    if (error) throw error;

    const reservation = this.mapToEntity(data);

    return reservation;
  }

  async ensureTicketsForReservation(reservationId: number): Promise<void> {
    const { data: existing, error: existingError } = await this.db
      .from("event_tickets")
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

  async findAll(): Promise<Reservation[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .order("created_at", { ascending: false });

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findById(
    input: ReservationIdInput
  ): Promise<Reservation | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToEntity(data) : null;
  }

  async findByUser(user_id: string): Promise<Reservation[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("user_id", user_id)
      .order("created_at", { ascending: false });

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findByEvent(event_id: number): Promise<Reservation[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("event_id", event_id);

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findByUserAndEvent(
    user_id: string,
    event_id: number
  ): Promise<Reservation[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("user_id", user_id)
      .eq("event_id", event_id);

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async getConfirmedQuantityByEvent(event_id: number): Promise<number> {
    const { data, error } = await this.db
      .from(this.table)
      .select("quantity")
      .eq("event_id", event_id)
      .eq("status", "confirmed");

    if (error) throw error;

    return (data ?? []).reduce((acc, r) => acc + r.quantity, 0);
  }

  async update(
    input: ReservationUpdateInput & ReservationIdInput
  ): Promise<Reservation> {
    const { id, ...rest } = input;

    const { data, error } = await this.db
      .from(this.table)
      .update(rest)
      .eq("id", id)
      .select()
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async cancelWithRefund(id: number, actorId: string): Promise<Reservation> {
    const { data, error } = await this.db.rpc("cancel_reservation_with_refund", { p_id: id, p_actor_id: actorId });
    if (error) throw error;
    return this.mapToEntity(data);
  }

  async delete(input: ReservationIdInput): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("id", input.id);

    if (error) throw error;
  }

  async exists(input: ReservationIdInput): Promise<boolean> {
    const { data, error } = await this.db
      .from(this.table)
      .select("id")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return !!data;
  }
}
