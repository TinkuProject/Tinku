import express from "express";
import fs from "node:fs";
import path from "node:path";
import dotenv from "dotenv";
import helmet from "helmet";
import { requestTiming } from "./middlewares/request-timing.middleware";
import {
  apiRateLimiter,
  authRateLimiter,
  corsMiddleware,
} from "./middlewares/security.middleware";
import { dbPool, query } from "./config/database.config";
import { handleError } from "./utils/handleError";
import { startMaintenance } from "./services/maintenance.service";
import { getActiveApkDirectory, getApkLatestPath, getApkReleasesPath } from "./config/domains";

//Auth and Storage related routes
import authRoutes from "./routes/auth.routes";
import storageRoutes from "./routes/storage.routes";

//Access Control related routes
import usersRoutes from "./routes/users.routes";
import permissionsRoutes from "./routes/permissions.routes";
import rolePermissionsRoutes from "./routes/role-permissions.routes";
import labelsRoutes from "./routes/labels.routes";
import labelPermissionsRoutes from "./routes/label-permissions.routes";
import userLabelsRoutes from "./routes/user-labels.routes";

//Economy related routes
import walletsRoutes from "./routes/wallets.routes";
import paymentsRoutes from "./routes/payments.routes";
import financialTransactionsRoutes from "./routes/financial-transactions.routes";
import coinPackagesRoutes from "./routes/coin-packages.routes";
import cashoutPackagesRoutes from "./routes/cashout-packages.routes";
import cashoutRequestsRoutes from "./routes/cashout-requests.routes";
import systemConfigRoutes from "./routes/system-config.routes";
import auditLogsRoutes from "./routes/audit-logs.routes";
import paymentActivityRoutes from "./routes/payment-activity.routes";
import stripeRoutes from "./routes/stripe.routes";
import stripeWebhookRoutes from "./routes/stripe-webhook.routes";

// Business related routes
import categoriesRoutes from "./routes/categories.routes";
import businessesRoutes from "./routes/businesses.routes";
import businessClaimRequestsRoutes from "./routes/business-claim-requests.routes";
import warehousesRoutes from "./routes/warehouses.routes";

// Content related routes
import productsRoutes from "./routes/products.routes";
import eventsRoutes from "./routes/events.routes";
import entityUpdatesRoutes from "./routes/entity-updates.routes";
import discountsRoutes from "./routes/discounts.routes";
import boostsRoutes from "./routes/boosts.routes";
import marketplaceRoutes from "./routes/marketplace.routes";

// User interactions related routes
import userVisitsRoutes from "./routes/user-visits.routes";
import reviewsRoutes from "./routes/reviews.routes";
import reservationsRoutes from "./routes/reservations.routes";
import eventTicketsRoutes from "./routes/event-tickets.routes";
import notificationsRoutes from "./routes/notifications.routes";

// Transport related routes
import vehiclesTypesRoutes from "./routes/vehicle-types.routes";
import transportLinesRoutes from "./routes/transport-lines.routes";
import transportRoutesRoutes from "./routes/transport-routes.routes";
import entityTransportRelationsRoutes from "./routes/entity-transport-relations.routes";

// Tourist places and tags related routes
import touristPlacesRoutes from "./routes/tourist-places.routes";
import tagsRoutes from "./routes/tags.routes";
import touristPlaceTagsRoutes from "./routes/tourist-place-tags.routes";

// Subscription related routes
import subscriptionPlansRoutes from "./routes/subscription-plans.routes";
import userSubscriptionsRoutes from "./routes/user-subscriptions.routes";
import paymentRequestsRoutes from "./routes/payment-requests.routes";

// Metadata related routes
import socialLinksRoutes from "./routes/social-links.routes";
import openingHoursRoutes from "./routes/opening-hours.routes";
import chargingPointsRoutes from "./routes/charging-points.routes";
import certificationsRoutes from "./routes/certifications.routes";
import mediaRoutes from "./routes/media.routes";

// Nearby search related routes
import nearbyRoutes from "./routes/nearby.routes";
import exploreRoutes from "./routes/explore.routes";
import homeDashboardRoutes from "./routes/home-dashboard.routes";

dotenv.config();
const app = express();

const trustProxy = process.env.TRUST_PROXY?.trim() || "loopback";
app.set(
  "trust proxy",
  /^\d+$/.test(trustProxy) ? Number(trustProxy) : trustProxy
);

app.use(requestTiming);
app.disable("x-powered-by");
app.use(helmet());
app.use(corsMiddleware);
app.use(apiRateLimiter);
app.use(
  "/stripe/webhook",
  express.raw({ type: "application/json", limit: "256kb" }),
  stripeWebhookRoutes
);
app.use(express.json({ limit: "1mb" }));

// Routes
app.use("/auth", authRateLimiter, authRoutes);
app.use("/storage", storageRoutes);

app.use("/users", usersRoutes);
app.use("/permissions", permissionsRoutes);
app.use("/role-permissions", rolePermissionsRoutes);
app.use("/labels", labelsRoutes);
app.use("/label-permissions", labelPermissionsRoutes);
app.use("/user-labels", userLabelsRoutes);

app.use("/wallets", walletsRoutes);
app.use("/payments", paymentsRoutes);
app.use("/financial-transactions", financialTransactionsRoutes);
app.use("/coin-packages", coinPackagesRoutes);
app.use("/cashout-packages", cashoutPackagesRoutes);
app.use("/cashout-requests", cashoutRequestsRoutes);
app.use("/system-config", systemConfigRoutes);
app.use("/audit-logs", auditLogsRoutes);
app.use("/finance", paymentActivityRoutes);
app.use("/stripe", stripeRoutes);

app.use("/categories", categoriesRoutes);
app.use("/businesses", businessesRoutes);
app.use("/business-claim-requests", businessClaimRequestsRoutes);
app.use("/warehouses", warehousesRoutes);

app.use("/products", productsRoutes);
app.use("/events", eventsRoutes);
app.use("/entity-updates", entityUpdatesRoutes);
app.use("/discounts", discountsRoutes);
app.use("/boosts", boostsRoutes);
app.use("/marketplace", marketplaceRoutes);

app.use("/user-visits", userVisitsRoutes);
app.use("/reviews", reviewsRoutes);
app.use("/reservations", reservationsRoutes);
app.use("/event-tickets", eventTicketsRoutes);
app.use("/notifications", notificationsRoutes);

app.use("/vehicle-types", vehiclesTypesRoutes);
app.use("/transport-lines", transportLinesRoutes);
app.use("/transport-routes", transportRoutesRoutes);
app.use("/entity-transport-relations", entityTransportRelationsRoutes);

app.use("/tourist-places", touristPlacesRoutes);
app.use("/tags", tagsRoutes);
app.use("/tourist-place-tags", touristPlaceTagsRoutes);

app.use("/subscription-plans", subscriptionPlansRoutes);
app.use("/user-subscriptions", userSubscriptionsRoutes);
app.use("/payment-requests", paymentRequestsRoutes);

app.use("/social-links", socialLinksRoutes);
app.use("/opening-hours", openingHoursRoutes);
app.use("/charging-points", chargingPointsRoutes);
app.use("/certifications", certificationsRoutes);
app.use("/media", mediaRoutes);

app.use("/nearby", nearbyRoutes);
app.use("/explore", exploreRoutes);
app.use("/home-dashboard", homeDashboardRoutes);

// Healthchecks para balanceador/PM2. Readiness comprueba PostgreSQL.
app.get(["/", "/health/live"], (_, res) => {
  res.json({ status: "ok" });
});

app.get(getApkLatestPath(), (_req, res) => {
  try {
    const releaseFile = path.join(getActiveApkDirectory(), "release.json");
    const release = JSON.parse(fs.readFileSync(releaseFile, "utf8")) as {
      releaseId?: string;
      applicationId?: string;
      sha256?: string;
    };
    if (
      !/^[0-9a-f]{40}-\d+$/.test(release.releaseId || "") ||
      release.applicationId !== "com.tinku.tinkuapp" ||
      !/^[0-9a-f]{64}$/.test(release.sha256 || "")
    ) {
      throw new Error("Invalid active Android release metadata.");
    }
    res.redirect(302, `${getApkReleasesPath()}/${release.releaseId}/Tinku.apk`);
  } catch (error) {
    console.error("Active Android release is unavailable", error);
    res.status(503).json({ error: "La descarga de Tinku no está disponible temporalmente." });
  }
});

app.get("/health/ready", async (req, res) => {
  try {
    await query("SELECT 1");
    res.json({ status: "ready", database: "up" });
  } catch (error) {
    console.error("Readiness check failed", error);
    res.status(503).json({ status: "not_ready", database: "down" });
  }
});

app.use((err: unknown, req: express.Request, res: express.Response, _next: express.NextFunction) => {
  handleError(res, err, req);
});

const PORT = process.env.PORT || 3000;
const stopMaintenance = startMaintenance();
const server = app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});

server.headersTimeout = 15_000;
server.requestTimeout = 120_000;
server.keepAliveTimeout = 5_000;

let shuttingDown = false;

function shutdown(signal: NodeJS.Signals): void {
  if (shuttingDown) return;
  shuttingDown = true;
  console.log(`${signal} received. Closing HTTP server and database pool...`);

  const forceTimer = setTimeout(() => {
    console.error("Graceful shutdown timed out");
    process.exit(1);
  }, 10_000);
  forceTimer.unref();

  server.close((serverError) => {
    void closeDatabaseAndExit(serverError, forceTimer);
  });
}

async function closeDatabaseAndExit(
  serverError: Error | undefined,
  forceTimer: NodeJS.Timeout
): Promise<void> {
  try {
    await stopMaintenance();
    await dbPool.end();
    clearTimeout(forceTimer);
    if (serverError) {
      console.error("HTTP server shutdown failed", serverError);
      process.exit(1);
    }
    process.exit(0);
  } catch (error) {
    console.error("Database pool shutdown failed", error);
    process.exit(1);
  }
}

process.once("SIGTERM", shutdown);
process.once("SIGINT", shutdown);
