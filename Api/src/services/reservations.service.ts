import { ReservationsDAO } from "../dao/reservations.dao";
import { EventsDAO } from "../dao/events.dao";
import { Reservation } from "../dto/reservation.dto";
import { ReservationCreateInput, ReservationUpdateInput, ReservationIdInput,
} from "../validation/reservations.validation";
import { EventIdInput } from "../validation/events.validation";
import { NotificationsService } from "./notifications.service";
import { AuditLogsDAO } from "../dao/audit-logs.dao";
import {
  Actor,
  assertDirectOwner,
  assertOwnershipAccess,
  hasOwnershipAccess,
} from "../helper/role.helper";

export class ReservationsService {
  constructor(
    private readonly dao: ReservationsDAO,
    private readonly eventsDao: EventsDAO,
    private readonly notificationsService?: NotificationsService,
    private readonly auditDao?: AuditLogsDAO
  ) {}

  async create(
    input: ReservationCreateInput,
    user_id: string
  ): Promise<Reservation> {

    // solo validar que exista el evento
    const event = await this.eventsDao.findById({
      id: input.event_id,
    } as EventIdInput);

    if (!event) throw new Error("Event not found");

    const reservation = await this.dao.createWithPayment({
      user_id,
      event_id: input.event_id,
      quantity: input.quantity,
    });

    if (reservation.status === "confirmed") {
      await this.notificationsService?.createSafely({
        user_id,
        title: "Reserva confirmada",
        message: `Tu reserva para "${event.name}" fue confirmada.`,
        type: "reservation",
        entity_type: "event",
        entity_id: event.id,
        route: "/myCalendar",
        read: false,
      });

      if (event.creator_id && event.creator_id !== user_id) {
        await this.notificationsService?.createSafely({
          user_id: event.creator_id,
          sender_id: user_id,
          title: "Nueva reserva",
          message: `Recibiste una reserva para "${event.name}".`,
          type: "reservation",
          entity_type: "event",
          entity_id: event.id,
          route: "/myEvents",
          read: false,
        });
      }
    }

    return reservation;
  }

  getAll(): Promise<Reservation[]> {
    return this.dao.findAll();
  }

  async getById(
    input: ReservationIdInput,
    actor: Actor
  ): Promise<Reservation> {
    const reservation = await this.dao.findById(input);
    if (!reservation) throw new Error("Reservation not found");

    if (!hasOwnershipAccess(reservation.user_id, actor)) {
      const event = await this.eventsDao.findById({ id: reservation.event_id });
      assertDirectOwner(event?.creator_id, actor.id, "Event not found");
    }

    return reservation;
  }

  getByUser(user_id: string): Promise<Reservation[]> {
    return this.dao.findByUser(user_id);
  }

  async getByEvent(event_id: number, actor: Actor): Promise<Reservation[]> {
    const event = await this.eventsDao.findById({ id: event_id });
    if (!event) throw new Error("Event not found");

    assertOwnershipAccess(event.creator_id, actor, "Event not found");

    return this.dao.findByEvent(event_id);
  }

  getMineByEvent(
    user_id: string,
    event_id: number
  ): Promise<Reservation[]> {
    return this.dao.findByUserAndEvent(user_id, event_id);
  }

  async update(
    input: ReservationUpdateInput & ReservationIdInput,
    actor: Actor
  ): Promise<Reservation> {
    const reservation = await this.dao.findById({
      id: input.id,
    });

    if (!reservation)
      throw new Error("Reservation not found");

    assertOwnershipAccess(reservation.user_id, actor, "Reservation not found");

    if (input.status === reservation.status) return reservation;
    if (input.status !== "cancelled") throw new Error("Invalid reservation transition");
    return this.dao.cancelWithRefund(input.id, actor.id);
  }

  async delete(
    input: ReservationIdInput,
    actor: Actor
  ): Promise<void> {
    const reservation = await this.dao.findById(input);

    if (!reservation)
      throw new Error("Reservation not found");

    assertOwnershipAccess(reservation.user_id, actor, "Reservation not found");

    await this.dao.cancelWithRefund(input.id, actor.id);
  }
}
