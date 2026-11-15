export const MIN_EVENT_DURATION_MS = 30 * 60 * 1000;

export type EventDateIssue = {
  field: "end_date";
  message: string;
};

export function getEventDateIssue(
  startDate: Date,
  endDate: Date,
  now = new Date()
): EventDateIssue | null {
  if (
    Number.isNaN(startDate.getTime()) ||
    Number.isNaN(endDate.getTime())
  ) {
    return {
      field: "end_date",
      message: "Las fechas del evento no son válidas",
    };
  }

  if (endDate.getTime() < now.getTime()) {
    return {
      field: "end_date",
      message: "La fecha y hora de fin no puede estar en el pasado",
    };
  }

  if (endDate <= startDate) {
    return {
      field: "end_date",
      message: "La fecha de fin debe ser posterior al inicio",
    };
  }

  if (endDate.getTime() - startDate.getTime() < MIN_EVENT_DURATION_MS) {
    return {
      field: "end_date",
      message: "El evento debe durar al menos 30 minutos",
    };
  }

  return null;
}

export function assertValidEventDates(
  startDate: Date,
  endDate: Date,
  now = new Date()
): void {
  const issue = getEventDateIssue(startDate, endDate, now);
  if (issue) throw new Error(issue.message);
}
