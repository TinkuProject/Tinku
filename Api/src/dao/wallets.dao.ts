import { DbClient } from "../types/db-client";
import { Wallet } from "../dto/wallet.dto";
import { WalletUserInput } from "../validation/wallets.validation";

export class WalletsDAO {
  private table = "wallets";
  constructor(private readonly db: DbClient) { }

  private mapToEntity(data: any): Wallet {
    return {
      user_id: data.user_id,
      balance: data.balance,
      created_at: new Date(data.created_at),
      updated_at: data.updated_at
        ? new Date(data.updated_at)
        : null,
    };
  }

  async findByUser(
    input: WalletUserInput
  ): Promise<Wallet | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("user_id", input.user_id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToEntity(data) : null;
  }

  /**
   * Crea wallet si no existe (idempotente)
   */
  async createIfNotExists(user_id: string): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .upsert(
        {
          user_id,
          balance: 0,
        },
        {
          onConflict: "user_id",
          ignoreDuplicates: true,
        }
      );

    if (error) throw error;
  }
}
