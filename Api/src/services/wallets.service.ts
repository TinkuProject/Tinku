import { WalletsDAO } from "../dao/wallets.dao";
import { Wallet } from "../dto/wallet.dto";
import { WalletUserInput } from "../validation/wallets.validation";

export class WalletsService {
  constructor(private readonly dao: WalletsDAO) {}

  async getByUser(input: WalletUserInput): Promise<Wallet> {
    const wallet = await this.dao.findByUser(input);
    if (!wallet) throw new Error("Wallet not found");

    return wallet;
  }

  createIfNotExists(user_id: string): Promise<void> {
    return this.dao.createIfNotExists(user_id);
  }
}
