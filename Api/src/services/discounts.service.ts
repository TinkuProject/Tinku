import { DiscountsDAO } from "../dao/discounts.dao";
import { DiscountCreateInput, DiscountUpdateInput } from "../validation/discounts.validation";

export class DiscountsService {
  constructor(private dao: DiscountsDAO) {}

  async create(data: DiscountCreateInput, user: any) {
    if (new Date(data.start_date) >= new Date(data.end_date)) {
      throw new Error("start_date must be before end_date");
    }

    if (user.role === "partner") {
      return this.dao.createWithCharge(data, user.id);
    }

    return this.dao.create(data);
  }

  getAll() {
    return this.dao.getAll();
  }

  async getById(id: number) {
    const discount = await this.dao.getById(id);

    if (!discount) {
      throw new Error("Discount not found");
    }

    return discount;
  }

  getMine(userId: string) {
    return this.dao.getMine(userId);
  }

  getByBusinessId(businessId: number) {
    return this.dao.getByBusinessId(businessId);
  }

  getActive() {
    return this.dao.getActive();
  }

  getActiveByBusinessId(businessId: number) {
    return this.dao.getActiveByBusinessId(businessId);
  }

  getByBusinessIds(businessIds: number[], activeOnly = false) {
    return this.dao.getByBusinessIds(businessIds, activeOnly);
  }

  async update(id: number, data: DiscountUpdateInput) {
    if (data.start_date && data.end_date) {
      if (new Date(data.start_date) >= new Date(data.end_date)) {
        throw new Error("start_date must be before end_date");
      }
    }

    return this.dao.update(id, data);
  }

  async softDelete(id: number) {
    return this.dao.softDelete(id);
  }
}
