import { CoinPackagesDAO } from "../dao/coin-packages.dao";
import { CoinPackage } from "../dto/coin-package.dto";
import { CoinPackageCreateInput, CoinPackageUpdateInput,
} from "../validation/coin-packages.validation";
import { BasicStatus } from "../constants/enums.constants";

export class CoinPackagesService {
  constructor(private dao: CoinPackagesDAO) { }

  async create(data: CoinPackageCreateInput): Promise<CoinPackage> {
    return this.dao.create(data);
  }

  async getAll(): Promise<CoinPackage[]> {
    return this.dao.findAll();
  }

  async getAllAdmin(): Promise<CoinPackage[]> {
    return this.dao.findAllAdmin();
  }

  async getById(id: number): Promise<CoinPackage> {
    const pkg = await this.dao.findById(id);

    if (!pkg) {
      throw new Error("Coin package not found");
    }

    return pkg;
  }

  async getActiveById(id: number): Promise<CoinPackage> {
    const pkg = await this.dao.findActiveById(id);

    if (!pkg) {
      throw new Error("Coin package not available");
    }

    return pkg;
  }

  async getPartnerUpgradePackage(): Promise<CoinPackage> {
    const pkg = await this.dao.findPartnerUpgradePackage();

    if (!pkg) {
      throw new Error("partner_upgrade package not found");
    }

    return pkg;
  }

  async update(
    id: number,
    data: CoinPackageUpdateInput
  ): Promise<CoinPackage> {
    const existing = await this.dao.findById(id);

    if (!existing) {
      throw new Error("Coin package not found");
    }

    return this.dao.update(id, data);
  }

  async softDelete(id: number): Promise<CoinPackage> {
    const existing = await this.dao.findById(id);

    if (!existing) {
      throw new Error("Coin package not found");
    }

    return this.dao.softDelete(id);
  }

  async activate(id: number): Promise<CoinPackage> {
    const existing = await this.dao.findById(id);

    if (!existing) {
      throw new Error("Coin package not found");
    }

    return this.dao.activate(id);
  }

  async deactivate(id: number): Promise<CoinPackage> {
    const existing = await this.dao.findById(id);

    if (!existing) {
      throw new Error("Coin package not found");
    }

    return this.dao.deactivate(id);
  }

  async getByFilters(params: {
    status?: BasicStatus;
  }): Promise<CoinPackage[]> {
    return this.dao.findByFilters(params);
  }
}