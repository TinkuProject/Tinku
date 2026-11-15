import { Request, Response } from "express";
import { randomUUID } from "node:crypto";
import { ZodError, ZodIssue } from "zod";
import { AppError } from "./AppError";

type ErrorWithCode = Error & {
  code?: unknown;
};

export function handleError(
  res: Response,
  err: unknown,
  req?: Request,
): void {
  const errorId = randomUUID();
  logError(errorId, err, req);

  // =========================
  // ZOD
  // =========================
  if (err instanceof ZodError) {
    const formatted = err.issues.map((e: ZodIssue) => ({
      field: e.path.join("."),
      message: e.message,
    }));

    res.status(400).json({
      error: "Validation error",
      details: formatted,
    });
    return;
  }

  // =========================
  // DB ERRORS
  // =========================
  if (isErrorWithCode(err)) {
    const statusCode = statusFromMessage(err.message) ?? 500;
    sendErrorResponse(res, statusCode, err.message, errorId);
    return;
  }

  // =========================
  // GENERIC ERROR
  // =========================
  if (err instanceof Error) {
    if (err instanceof AppError) {
      sendErrorResponse(res, err.statusCode, err.message, errorId);
      return;
    }

    const statusCode = statusFromMessage(err.message) ?? 500;
    sendErrorResponse(res, statusCode, err.message, errorId);
    return;
  }

  // =========================
  // FALLBACK
  // =========================
  sendErrorResponse(res, 500, undefined, errorId);
}

function sendErrorResponse(
  res: Response,
  statusCode: number,
  message: string | undefined,
  errorId: string,
): void {
  if (statusCode >= 500) {
    res.status(statusCode).json({
      error: "Internal server error",
      error_id: errorId,
    });
    return;
  }

  res.status(statusCode).json({
    error: message ?? "Request could not be processed",
  });
}

function logError(errorId: string, err: unknown, req?: Request): void {
  const route = req?.route?.path;
  const user = req?.user;
  const file = req?.file;

  const logEntry = {
    errorId,
    request: req
      ? {
          method: req.method,
          route:
            typeof route === "string"
              ? `${req.baseUrl}${route}`
              : req.baseUrl || "unmatched",
          paramKeys: Object.keys(req.params ?? {}),
          queryKeys: Object.keys(req.query ?? {}),
          bodyKeys: getObjectKeys(req.body),
          userId: user?.id,
          role: user?.role,
          file: file
            ? {
                mimetype: file.mimetype,
                size: file.size,
              }
            : undefined,
        }
      : undefined,
    error: serializeError(err),
  };

  console.error("REQUEST ERROR:", logEntry);
}

function serializeError(err: unknown): Record<string, unknown> {
  if (err instanceof ZodError) {
    return {
      name: err.name,
      issues: err.issues.map((issue) => ({
        code: issue.code,
        field: issue.path.join("."),
      })),
    };
  }

  if (err instanceof Error) {
    const codedError = err as ErrorWithCode;
    return {
      name: err.name,
      message: err.message,
      code: typeof codedError.code === "string" ? codedError.code : undefined,
      stack: process.env.NODE_ENV === "development" ? err.stack : undefined,
    };
  }

  return {
    type: typeof err,
  };
}

function getObjectKeys(value: unknown): string[] | undefined {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    return undefined;
  }

  return Object.keys(value);
}

function isErrorWithCode(err: unknown): err is ErrorWithCode {
  return err instanceof Error && "code" in err;
}

function statusFromMessage(message?: string): number | undefined {
  if (!message) return undefined;

  const knownStatus: Record<string, number> = {
    "Stripe payment target mismatch": 409,
    "Invalid media update": 400,
    "Warehouse must accept a stock request first": 409,
    "Business must be approved before configuring fulfillment": 409,
    "Receive a stock request before adjusting inventory": 409,
    "Reserved stock cannot be changed manually": 409,
    "Used or finished reservations cannot be cancelled": 409,
    "Reservation refund requires review": 409,
    "Organizer balance is insufficient for refund": 409,
    "Gateway payments must be processed by Stripe": 403,
    "Email changes require verification": 409,
    "Marketplace order is not ready for pickup": 409,
    "Marketplace pickup expired": 409,
    "Idempotency key reused with different data": 409,
    "Event is not available for reservations": 409,
    "Invalid reservation transition": 409,
    Unauthorized: 401,
    Forbidden: 403,
    "Not authorized": 403,
    "Not authorized to check in this event": 403,
    "Only confirmed event attendees can review this event": 403,
    "Cannot reply to your own review": 403,
    "User not found": 404,
    "Business not found": 404,
    "Product not found": 404,
    "Certification not found": 404,
    "Media not found": 404,
    "Business must be approved before boosting": 403,
    "Warehouse not found": 404,
    "Warehouse is required": 400,
    "Invalid warehouse selection": 400,
    "Event not found": 404,
    "Las fechas del evento no son válidas": 400,
    "La fecha y hora de fin no puede estar en el pasado": 400,
    "La fecha de fin debe ser posterior al inicio": 400,
    "El evento debe durar al menos 30 minutos": 400,
    "Reservation not found": 404,
    "Payment not found": 404,
    "Request not found": 404,
    "Ticket not found": 404,
    "Ticket day not found": 404,
    "Ticket day expired": 409,
    "Ticket day not yet valid": 409,
    "Ticket already used": 409,
    "Invalid ticket token": 400,
    "Cashout package not found or inactive": 404,
    "Insufficient balance": 400,
    "Invalid quantity": 400,
    "Invalid status": 400,
    "Invalid marketplace publication": 400,
    "Cannot buy your own product": 403,
    "Marketplace publication not found": 404,
    "Marketplace order not found": 404,
    "Marketplace order already delivered": 409,
    "Marketplace order is not paid": 409,
    "Marketplace order cancelled": 409,
    "Marketplace order cannot be rejected": 409,
    "Marketplace order cannot transition to this status": 409,
    "Marketplace seller settlement is not configured": 409,
    "Delivery not found": 404,
    "Pickup business is required": 400,
    "Invalid pickup business": 400,
    "Pickup is not available for this business": 409,
    "Warehouse delivery is not available for this order": 409,
    "Published stock exceeds available stock": 400,
    "Insufficient published stock": 409,
    "Product already has an open publication": 409,
    "Invalid current password": 400,
    "Invalid verification code": 400,
    "Verification code expired": 409,
    "Email not verified": 403,
    "Email already verified": 409,
    "Please wait before requesting another code": 429,
    "Too many code requests": 429,
    "Too many verification attempts": 429,
    "Email service is not configured": 503,
    "Invalid payment type": 400,
    "Target ID required for coin purchase": 400,
    "Target ID required for subscription": 400,
    "Upgrade config not found": 500,
    "Invalid coin package": 400,
    "Invalid subscription plan": 400,
    "Unsupported request type": 400,
    "Not enough capacity": 409,
    "Request already reviewed": 409,
    "Request already processed": 409,
    "Request not found or already reviewed": 409,
    "Payment already processed": 409,
    "Payment is still initializing": 409,
    "Cashout request already processed": 409,
    "User already has a pending cashout request": 409,
  };

  return knownStatus[message];
}
