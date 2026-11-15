import { DbClient } from "../types/db-client";
import { SystemConfig } from "../dto/system-config.dto";
import { KeyParamInput, UpdateConfigWithKeyInput } from "../validation/system-config.validation";

export class SystemConfigDAO {
  private table = "system_config";

  constructor(private readonly db: DbClient) {}

  private mapToEntity(data: any): SystemConfig {
    return {
      key: data.key,
      value: data.value,
      description: data.description ?? null,
      updated_at: new Date(data.updated_at),
    };
  }

  // =========================
  // BASIC
  // =========================

  async get(input: KeyParamInput): Promise<SystemConfig | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("key", input.key)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToEntity(data) : null;
  }

  async getAll(): Promise<SystemConfig[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .order("key");

    if (error) throw error;

    return (data || []).map((row) => this.mapToEntity(row));
  }

  async upsert(input: UpdateConfigWithKeyInput): Promise<SystemConfig> {
    const { key, value, description } = input;

    const { data, error } = await this.db
      .from(this.table)
      .upsert({
        key,
        value,
        description,
        updated_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  // =========================
  // HELPERS
  // =========================

  async getValue(key: string): Promise<string | null> {
    const config = await this.get({ key });
    return config?.value ?? null;
  }

  async getNumber(key: string): Promise<number | null> {
    const value = await this.getValue(key);

    if (value === null) return null;

    const parsed = Number(value);

    if (isNaN(parsed)) {
      throw new Error(`System config "${key}" is not a valid number`);
    }

    return parsed;
  }

  async getNumberOrDefault(
    key: string,
    defaultValue: number
  ): Promise<number> {
    const value = await this.getNumber(key);
    return value ?? defaultValue;
  }
}