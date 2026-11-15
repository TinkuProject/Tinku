import { NotificationsDAO } from "../dao/notifications.dao";
import { Notification } from "../dto/notification.dto";
import { firebaseMessaging } from "../config/firebase-client.config";
import { query } from "../config/database.config";
import { NotificationCreateInput, NotificationUpdateInput,
  DeviceTokenInput,
} from "../validation/notifications.validation";

export class NotificationsService {
  constructor(private dao: NotificationsDAO) { }

  async createSafely(data: NotificationCreateInput): Promise<Notification | null> {
    try { return await this.create(data); }
    catch (error) { console.warn("Notification deferred or unavailable", error); return null; }
  }

  async create(data: NotificationCreateInput): Promise<Notification> {
    const notification = await this.dao.create({
      user_id: data.user_id,
      message: data.message,
      sender_id: data.sender_id ?? null,
      title: data.title ?? null,
      type: data.type ?? null,
      entity_type: data.entity_type ?? null,
      entity_id: data.entity_id ?? null,
      route: data.route ?? null,
      read: data.read ?? false,
    });

    return notification;
  }

  async flushPushQueue(): Promise<void> {
    const claimed = await query<{ notification_id: number }>(
      `WITH due AS (
         SELECT notification_id FROM notification_push_queue
         WHERE available_at <= now() AND (lease_until IS NULL OR lease_until < now())
         ORDER BY available_at LIMIT 20 FOR UPDATE SKIP LOCKED
       ) UPDATE notification_push_queue q SET lease_until = now() + INTERVAL '2 minutes'
         FROM due WHERE q.notification_id = due.notification_id RETURNING q.notification_id`
    );
    await Promise.all(claimed.rows.map(async row => {
      try {
        const notification = await this.dao.getById(row.notification_id);
        if (notification) await this.sendPush(notification);
        await query("DELETE FROM notification_push_queue WHERE notification_id = $1", [row.notification_id]);
      } catch (error) {
        await query(
          `UPDATE notification_push_queue SET attempts = attempts + 1, lease_until = NULL,
             available_at = now() + LEAST(3600, 30 * power(2, LEAST(attempts, 7))) * INTERVAL '1 second'
           WHERE notification_id = $1`, [row.notification_id]
        );
        console.warn("Push delivery will be retried", { notificationId: row.notification_id, error });
      }
    }));
  }

  async getById(id: number): Promise<Notification> {
    const notif = await this.dao.getById(id);

    if (!notif) {
      throw new Error("Notification not found");
    }

    return notif;
  }

  getByUser(userId: string, limit?: number) {
    return this.dao.getByUser(userId, limit);
  }

  getByUserPage(userId: string, limit: number, offset: number) {
    return this.dao.getByUserPage(userId, limit, offset);
  }

  update(
    id: number,
    data: NotificationUpdateInput
  ): Promise<Notification> {
    return this.dao.update(id, data);
  }

  delete(id: number): Promise<void> {
    return this.dao.delete(id);
  }

  deleteAllByUser(userId: string): Promise<void> {
    return this.dao.deleteAllByUser(userId);
  }

  markAsRead(id: number): Promise<Notification> {
    return this.dao.markAsRead(id);
  }

  markAllAsRead(userId: string): Promise<void> {
    return this.dao.markAllAsRead(userId);
  }

  getUnreadCount(userId: string): Promise<number> {
    return this.dao.countUnread(userId);
  }

  async registerDeviceToken(
    userId: string,
    input: DeviceTokenInput
  ): Promise<void> {
    await this.dao.upsertDeviceToken({
      user_id: userId,
      token: input.token,
      platform: input.platform ?? null,
    });
  }

  async unregisterDeviceToken(
    userId: string,
    input: DeviceTokenInput
  ): Promise<void> {
    await this.dao.deleteDeviceToken(userId, input.token);
  }

  async broadcastToAdmins(data: {
    message: string;
    sender_id?: string;
    type?: string;
    entity_type?: string;
    entity_id?: number;
    route?: string;
  }): Promise<Notification[]> {

    const admins = await this.dao.getAdmins();

    if (admins.length === 0) return [];

    const payload = admins.map((userId) => ({
      user_id: userId,
      ...(data.sender_id ? { sender_id: data.sender_id } : {}),
      message: data.message,
      title: "Aviso administrativo",
      ...(data.type ? { type: data.type } : {}),
      ...(data.entity_type ? { entity_type: data.entity_type } : {}),
      ...(data.entity_id ? { entity_id: data.entity_id } : {}),
      ...(data.route ? { route: data.route } : {}),
      read: false,
    }));

    const results = await Promise.all(payload.map((n) => this.create(n)));

    return results;
  }

  private async sendPush(notification: Notification): Promise<void> {
    const tokens = await this.dao.getDeviceTokensByUser(notification.user_id);
    if (tokens.length === 0) return;

    const response = await firebaseMessaging.sendEachForMulticast({
      tokens,
      notification: {
        title: notification.title ?? "Tinku",
        body: notification.message,
      },
      data: {
        notification_id: String(notification.id),
        screen: notification.route ?? "notifications",
        route: notification.route ?? "/notifications",
        type: notification.type ?? "general",
        entity_type: notification.entity_type ?? "",
        entity_id: notification.entity_id == null
          ? ""
          : String(notification.entity_id),
      },
      android: {
        priority: "high",
        notification: {
          channelId: "tinku_notifications",
          sound: "default",
        },
      },
    });

    let transientFailure = false;
    await Promise.all(
      response.responses.map((result, index) => {
        if (result.success) return Promise.resolve();

        const code = result.error?.code ?? "";
        if (
          code.includes("registration-token-not-registered") ||
          code.includes("invalid-registration-token")
        ) {
          const token = tokens[index];
          return token
            ? this.dao.deleteDeviceTokenByValue(token)
            : Promise.resolve();
        }

        console.warn("Could not send push notification", result.error);
        transientFailure = true;
        return Promise.resolve();
      })
    );
    if (transientFailure) throw new Error("Push provider temporarily unavailable");
  }
}
