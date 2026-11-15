import { DbClient } from "../types/db-client";
import { User } from "../dto/user.dto";
import { UserUpdateInput, UserIdInput } from "../validation/users.validation";
import { UserRole } from "../constants/enums.constants";
import { parseLocation, buildPoint } from "../utils/location";

export class UsersDAO {
  private table = "users";
  constructor(private readonly db: DbClient) {}

  private mapToEntity(data: any): User {
    return {
      id: data.id,
      username: data.username,
      email: data.email,
      first_name: data.first_name ?? null,
      last_name: data.last_name ?? null,
      phone: data.phone ?? null,
      ci: data.ci ?? null,
      address: data.address ?? null,
      location: parseLocation(data.location),

      role: data.role,
      status: data.status,

      created_at: new Date(data.created_at),
      updated_at: data.updated_at ? new Date(data.updated_at) : null,
    };
  }

  private mapToPublicProfile(data: any): User {
    return {
      id: data.id,
      username: data.username,
      email: "",
      first_name: data.first_name ?? null,
      last_name: data.last_name ?? null,
      phone: null,
      ci: null,
      address: null,
      location: null,
      role: "user",
      status: data.status ?? "active",
      created_at: new Date(data.created_at),
      updated_at: data.updated_at ? new Date(data.updated_at) : null,
    };
  }

  async findAll(): Promise<User[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*");

    if (error) throw error;

    return (data ?? []).map((u) => this.mapToEntity(u));
  }

  async findById(input: UserIdInput): Promise<User | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToEntity(data) : null;
  }

  async findPublicProfilesByIds(ids: string[]): Promise<User[]> {
    const uniqueIds = [...new Set(ids)];

    const { data, error } = await this.db
      .from(this.table)
      .select("id, username, first_name, last_name, status, created_at, updated_at")
      .in("id", uniqueIds);

    if (error) throw error;

    return (data ?? []).map((u) => this.mapToPublicProfile(u));
  }

  async update(input: UserUpdateInput): Promise<User> {
    const { id, location, ...rest } = input;

    const payload: any = {
      ...rest,
      updated_at: new Date().toISOString(),
    };

    if (location !== undefined) {
      payload.location = location
        ? buildPoint({
            coordinates: [location.longitude, location.latitude],
          })
        : null;
    }

    const { data, error } = await this.db
      .from(this.table)
      .update(payload)
      .eq("id", id)
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async delete(input: UserIdInput): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("id", input.id);

    if (error) throw error;
  }
}
