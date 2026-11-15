import { CashoutPackagesDAO } from "../dao/cashout-packages.dao";
import { CashoutPackage } from "../dto/cashout-package.dto";
import { CashoutPackageCreateInput, CashoutPackageUpdateInput,
} from "../validation/cashout-packages.validation";

export class CashoutPackagesService {
  constructor(private dao: CashoutPackagesDAO) {}

  async create(data: CashoutPackageCreateInput): Promise<CashoutPackage> {
    return this.dao.create(data);
  }

  async getAll(): Promise<CashoutPackage[]> {
    return this.dao.findAll();
  }

  async getAllAdmin(): Promise<CashoutPackage[]> {
    return this.dao.findAllAdmin();
  }

  async getById(id: number): Promise<CashoutPackage> {
    const pkg = await this.dao.findById(id);

    if (!pkg) {
      throw new Error("Cashout package not found");
    }

    return pkg;
  }

  async getActiveById(id: number): Promise<CashoutPackage> {
    const pkg = await this.dao.findById(id);

    if (!pkg || pkg.status !== "active") {
      throw new Error("Cashout package not available");
    }

    return pkg;
  }

  async update(
    id: number,
    data: CashoutPackageUpdateInput
  ): Promise<CashoutPackage> {
    const existing = await this.dao.findById(id);

    if (!existing) {
      throw new Error("Cashout package not found");
    }

    return this.dao.update(id, data);
  }

  async softDelete(id: number): Promise<CashoutPackage> {
    const existing = await this.dao.findById(id);

    if (!existing) {
      throw new Error("Cashout package not found");
    }

    return this.dao.softDelete(id);
  }
  
  async deactivate(id: number): Promise<CashoutPackage> {
    const existing = await this.dao.findById(id);

    if (!existing) {
      throw new Error("Cashout package not found");
    }

    return this.dao.deactivate(id);
  }

  async activate(id: number): Promise<CashoutPackage> {
    const existing = await this.dao.findById(id);

    if (!existing) {
      throw new Error("Cashout package not found");
    }

    return this.dao.activate(id);
  }
}