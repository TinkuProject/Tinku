import { SystemConfigDAO } from "../dao/system-config.dao";
import { KeyParamInput, UpdateConfigWithKeyInput } from "../validation/system-config.validation";
import { SystemConfig } from "../dto/system-config.dto";

const DEFAULT_CONFIG_NUMBERS: Record<string, number> = {
  upgrade_to_partner: 100,
  business_create_cost: 25,
  event_create_cost: 15,
  discount_create_cost: 10,
  boost_create_cost: 20,
  product_publication_base_cost: 5,
  product_publication_stock_unit_cost: 1,
  product_publication_price_rate: 0.02,
  marketplace_service_fee_rate: 0.10,
  warehouse_delivery_reward_tinkus: 3,
  warehouse_delivery_reward_small: 1,
  warehouse_delivery_reward_medium: 2,
  warehouse_delivery_reward_large: 3,
};

export class SystemConfigService {
  constructor(private readonly dao: SystemConfigDAO) { }

  // =========================
  // BASIC
  // =========================

  async get(input: KeyParamInput): Promise<SystemConfig> {
    const config = await this.dao.get(input);

    if (!config) {
      if (DEFAULT_CONFIG_NUMBERS[input.key] !== undefined) {
        return {
          key: input.key,
          value: String(DEFAULT_CONFIG_NUMBERS[input.key]),
          description: "Default fallback value",
          updated_at: new Date(),
        };
      }
      throw new Error("Config not found");
    }

    return config;
  }

  async getAll(): Promise<SystemConfig[]> {
    return this.dao.getAll();
  }

  async upsert(input: UpdateConfigWithKeyInput): Promise<SystemConfig> {
    const existing = await this.dao.get({ key: input.key });

    // 🔴 CREATE
    if (!existing) {
      if (input.value === undefined) {
        throw new Error("Value is required for new config");
      }

      return this.dao.upsert({
        key: input.key,
        value: input.value,
        description: input.description ?? null,
      });
    }

    // 🟢 UPDATE
    return this.dao.upsert({
      key: input.key,
      value: input.value ?? existing.value,
      description:
        input.description !== undefined
          ? input.description
          : existing.description,
    });
  }

  // =========================
  // HELPERS
  // =========================

  async getValue(key: string): Promise<string> {
    const value = await this.dao.getValue(key);

    if (value === null) {
      if (DEFAULT_CONFIG_NUMBERS[key] !== undefined) {
        return String(DEFAULT_CONFIG_NUMBERS[key]);
      }
      throw new Error(`Config "${key}" not found`);
    }

    return value;
  }

  async getNumber(key: string): Promise<number> {
    const value = await this.dao.getNumber(key);

    if (value === null) {
      if (DEFAULT_CONFIG_NUMBERS[key] !== undefined) {
        return DEFAULT_CONFIG_NUMBERS[key];
      }
      throw new Error(`Config "${key}" not found`);
    }

    return value;
  }

  async getNumberOrDefault(
    key: string,
    defaultValue: number
  ): Promise<number> {
    return this.dao.getNumberOrDefault(key, defaultValue);
  }
}
