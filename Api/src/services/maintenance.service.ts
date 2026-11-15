import { MarketplaceDAO } from "../dao/marketplace.dao";
import { NotificationsDAO } from "../dao/notifications.dao";
import { NotificationsService } from "./notifications.service";
import { supabaseAdmin } from "../config/supabase-client.config";

export function startMaintenance(): () => Promise<void> {
  const marketplace = new MarketplaceDAO();
  const notifications = new NotificationsService(new NotificationsDAO(supabaseAdmin));
  let stopped = false;
  let lastExpiration = 0;
  let running: Promise<void> | null = null;
  let timer: NodeJS.Timeout;
  const run = async () => {
    try {
      if (Date.now() - lastExpiration > 60_000) {
        await marketplace.expirePickups();
        lastExpiration = Date.now();
      }
      await notifications.flushPushQueue();
    } catch (error) {
      console.error("Maintenance task failed", error);
    }
  };
  const tick = () => {
    running = run().finally(() => {
      running = null;
      if (!stopped) { timer = setTimeout(tick, 5_000); timer.unref(); }
    });
  };
  timer = setTimeout(tick, 100);
  timer.unref();
  return async () => { stopped = true; clearTimeout(timer); await running; };
}
