import { BoostsDAO } from "../dao/boosts.dao";
import { BusinessesDAO } from "../dao/businesses.dao";
import { Boost } from "../dto/boost.dto";
import { Business } from "../dto/business.dto";
import { BoostCreateInput, BoostUpdateInput } from "../validation/boosts.validation";
import { VisitEntity } from "../constants/enums.constants";
import { Actor } from "../helper/role.helper";

export class BoostsService {
  constructor(private dao: BoostsDAO) {}

  async create(data: BoostCreateInput, user: any): Promise<any> {
    if (data.entity_type === "business") {
      const canPromote = await this.dao.canPromoteBusiness(
        data.entity_id,
        user.role === "partner" ? user.id : undefined
      );

      if (!canPromote) {
        throw new Error("Business must be approved before boosting");
      }
    }

    // solo partner paga
    if (user.role === "partner") {
      return this.dao.createWithCharge(data, user.id);
    }

    return this.dao.create(data);
  }

  async getAll(limit = 50, offset = 0): Promise<Boost[]> {
    const safeLimit = Math.min(limit, 100);
    return this.dao.findAll(safeLimit, offset);
  }

  async getById(id: number): Promise<Boost> {
    if (!id || id <= 0) {
      throw new Error("Invalid id");
    }

    const boost = await this.dao.findById(id);

    if (!boost) {
      throw new Error("Boost not found");
    }

    return boost;
  }

  async getActive(): Promise<Boost[]> {
    return this.dao.findActive();
  }

  async getByEntity(
    entityType: VisitEntity,
    entityId: number,
    limit = 50,
    offset = 0
  ): Promise<Boost[]> {
    if (!entityType || entityId <= 0) {
      throw new Error("Invalid parameters");
    }

    const safeLimit = Math.min(limit, 100);
    return this.dao.findByEntity(entityType, entityId, safeLimit, offset);
  }

  async update(id: number, data: BoostUpdateInput, actor: Actor): Promise<Boost> {
    const existing = await this.dao.findById(id);

    if (!existing) {
      throw new Error("Boost not found");
    }

    // 🔒 bloquear cancelación desde update
    if (data.status === "cancelled") {
      throw new Error("Use cancel method instead");
    }

    return this.dao.updateWithCharge(id, data, actor);
  }

  async getMineByBusinessIds(
    businessIds: number[],
    limit = 50,
    offset = 0
  ): Promise<Boost[]> {
    if (!businessIds.length) return [];

    const safeLimit = Math.min(limit, 100);
    return this.dao.findMineByBusinessIds(businessIds, safeLimit, offset);
  }

  async getPromotableBusinesses(
    businessesDao: BusinessesDAO,
    userId?: string
  ): Promise<Business[]> {
    if (!userId) {
      throw new Error("Unauthorized");
    }

    return businessesDao.findPromotableByOwner(userId);
  }

  async softDelete(id: number): Promise<Boost> {
    const existing = await this.dao.findById(id);

    if (!existing) {
      throw new Error("Boost not found");
    }

    if (existing.status === "cancelled") {
      throw new Error("Boost already cancelled");
    }

    return this.dao.softDelete(id);
  }
}
