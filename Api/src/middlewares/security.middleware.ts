import cors, { CorsOptions } from "cors";
import dotenv from "dotenv";
import rateLimit from "express-rate-limit";
import { AppError } from "../utils/AppError";
import { getCanonicalWebOrigin } from "../config/domains";

dotenv.config();

const isDevelopment = process.env.NODE_ENV === "development";

function readPositiveInt(name: string, fallback: number): number {
  const parsed = Number(process.env[name]);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : fallback;
}

function allowedOrigins(): Set<string> {
  const configured = (process.env.CORS_ALLOWED_ORIGINS ?? "")
    .split(",")
    .map((origin) => origin.trim().replace(/\/$/, ""))
    .filter(Boolean);

  const canonicalWebOrigin = getCanonicalWebOrigin();
  if (canonicalWebOrigin) configured.push(canonicalWebOrigin);

  if (isDevelopment) {
    configured.push(
      "http://localhost:3000",
      "http://localhost:5173",
      "http://127.0.0.1:3000",
      "http://127.0.0.1:5173"
    );
  }

  return new Set(configured);
}

const origins = allowedOrigins();

export const corsOptions: CorsOptions = {
  origin(origin, callback) {
    // Apps nativas, Postman y llamadas server-to-server no envían Origin.
    if (!origin || origins.has(origin.replace(/\/$/, ""))) {
      callback(null, true);
      return;
    }

    callback(new AppError("Origin not allowed", 403));
  },
  methods: ["GET", "HEAD", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: ["Authorization", "Content-Type", "Accept"],
  maxAge: 86400,
};

const windowMs = readPositiveInt("RATE_LIMIT_WINDOW_MS", 15 * 60 * 1000);

export const apiRateLimiter = rateLimit({
  windowMs,
  limit: readPositiveInt("RATE_LIMIT_MAX", 300),
  standardHeaders: "draft-8",
  legacyHeaders: false,
  skip: (req) => req.path === "/health/live",
  message: { error: "Demasiadas solicitudes. Intenta nuevamente más tarde." },
});

export const authRateLimiter = rateLimit({
  windowMs,
  limit: readPositiveInt("AUTH_RATE_LIMIT_MAX", 40),
  standardHeaders: "draft-8",
  legacyHeaders: false,
  message: {
    error: "Demasiados intentos de acceso. Intenta nuevamente más tarde.",
  },
});

export const corsMiddleware = cors(corsOptions);
export const pickupRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, limit: 30,
  keyGenerator: req => req.user!.id,
  standardHeaders: "draft-8", legacyHeaders: false,
  message: { error: "Demasiados intentos de validacion. Intenta mas tarde." },
});
