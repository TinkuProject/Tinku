import { EventTicketsDAO } from "../dao/event-tickets.dao";
import {
  EventTicket,
  EventTicketCheckInResult,
  EventTicketQr,
} from "../dto/event-ticket.dto";

export class EventTicketsService {
  constructor(private readonly dao: EventTicketsDAO) {}

  getMine(userId: string): Promise<EventTicket[]> {
    return this.dao.findMine(userId);
  }

  getByReservation(reservationId: number): Promise<EventTicket[]> {
    return this.dao.findByReservation(reservationId);
  }

  getByEvent(eventId: number): Promise<EventTicket[]> {
    return this.dao.findByEvent(eventId);
  }

  async getById(id: string): Promise<EventTicket> {
    const ticket = await this.dao.findById(id);

    if (!ticket) {
      throw new Error("Ticket not found");
    }

    return ticket;
  }

  issueQr(ticketDayId: string, userId: string): Promise<EventTicketQr> {
    return this.dao.issueQr(ticketDayId, userId);
  }

  checkIn(input: {
    token: string;
    event_id: number;
    scanner_id: string;
  }): Promise<EventTicketCheckInResult> {
    return this.dao.checkIn(input);
  }
}
