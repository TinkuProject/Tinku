import { DbClient } from "../types/db-client";
import { Notification } from "../dto/notification.dto";

export class NotificationsDAO {
  private table = "notifications";
  constructor(private db: DbClient) {}

  private mapToDomain(row: any): Notification {
    if (!row) return row;

    return {
      ...row,
      created_at: new Date(row.created_at),
    };
  }

  async create(data: Partial<Notification>): Promise<Notification> {
    const { data: result, error } = await this.db
      .from(this.table)
      .insert(data)
      .select()
      .single();

    if (error) throw error;
    return this.mapToDomain(result);
  }

  async getById(id: number): Promise<Notification | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", id)
      .maybeSingle();

    if (error) throw error;
    return data ? this.mapToDomain(data) : null;
  }

  async getByUser(
    userId: string,
    limit = 50
  ): Promise<Notification[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("user_id", userId)
      .order("created_at", { ascending: false })
      .limit(limit);

    if (error) throw error;
    return (data || []).map((row) => this.mapToDomain(row));
  }

  async getByUserPage(
    userId: string,
    limit = 20,
    offset = 0
  ): Promise<{ items: Notification[]; total: number }> {
    const [itemsResult, countResult] = await Promise.all([
      this.db
        .from(this.table)
        .select("*")
        .eq("user_id", userId)
        .order("created_at", { ascending: false })
        .range(offset, offset + limit - 1),
      this.db
        .from(this.table)
        .select("*", { count: "exact", head: true })
        .eq("user_id", userId),
    ]);

    if (itemsResult.error) throw itemsResult.error;
    if (countResult.error) throw countResult.error;

    return {
      items: (itemsResult.data || []).map((row) => this.mapToDomain(row)),
      total: countResult.count ?? 0,
    };
  }

  async update(
    id: number,
    updates: Partial<Notification>
  ): Promise<Notification> {
    const { data, error } = await this.db
      .from(this.table)
      .update(updates)
      .eq("id", id)
      .select()
      .single();

    if (error) throw error;
    return this.mapToDomain(data);
  }

  async delete(id: number): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("id", id);

    if (error) throw error;
  }

  async markAsRead(id: number): Promise<Notification> {
    return this.update(id, { read: true });
  }

  async markAllAsRead(userId: string): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .update({ read: true })
      .eq("user_id", userId)
      .eq("read", false);

    if (error) throw error;
  }

  async countUnread(userId: string): Promise<number> {
    const { count, error } = await this.db
      .from(this.table)
      .select("*", { count: "exact", head: true })
      .eq("user_id", userId)
      .eq("read", false);

    if (error) throw error;
    return count ?? 0;
  }

  async deleteAllByUser(userId: string): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("user_id", userId);

    if (error) throw error;
  }

  async upsertDeviceToken(data: {
    user_id: string;
    token: string;
    platform?: string | null;
  }): Promise<void> {
    const { error } = await this.db
      .from("user_device_tokens")
      .upsert(
        {
          user_id: data.user_id,
          token: data.token,
          platform: data.platform ?? null,
          last_seen_at: new Date().toISOString(),
        },
        { onConflict: "token" }
      );

    if (error) throw error;
  }

  async deleteDeviceToken(userId: string, token: string): Promise<void> {
    const { error } = await this.db
      .from("user_device_tokens")
      .delete()
      .eq("user_id", userId)
      .eq("token", token);

    if (error) throw error;
  }

  async deleteDeviceTokenByValue(token: string): Promise<void> {
    const { error } = await this.db
      .from("user_device_tokens")
      .delete()
      .eq("token", token);

    if (error) throw error;
  }

  async getDeviceTokensByUser(userId: string): Promise<string[]> {
    const { data, error } = await this.db
      .from("user_device_tokens")
      .select("token")
      .eq("user_id", userId);

    if (error) throw error;

    return (data || [])
      .map((row) => row.token)
      .filter((token): token is string => typeof token === "string");
  }

  async getAdmins(): Promise<string[]> {
    const { data, error } = await this.db
      .from("users")
      .select("id")
      .in("role", ["admin", "master"]);

    if (error) throw error;

    return (data || []).map((u) => u.id);
  }
}
