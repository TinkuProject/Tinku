import { CategoriesDAO } from "../dao/categories.dao";
import { Category } from "../dto/category.dto";
import { CategoryCreateInput, CategoryUpdateInput } from "../validation/categories.validation";
import { CategoryEntityType, BusinessType, BasicStatus } from "../constants/enums.constants";

export class CategoriesService {
  constructor(private dao: CategoriesDAO) {}

  async create(data: CategoryCreateInput): Promise<Category> {
    // business_type solo si es business
    if (data.entity_type !== "business") {
      data.business_type = null;
    }

    return this.dao.create(data);
  }

  // 🔹 público
  getAll(): Promise<Category[]> {
    return this.dao.findAll();
  }

  // 🔹 admin
  getAllAdmin(): Promise<Category[]> {
    return this.dao.findAllAdmin();
  }

  async getById(id: number): Promise<Category> {
    const cat = await this.dao.findById(id);

    if (!cat) {
      throw new Error("Category not found");
    }

    return cat;
  }

  getByIds(ids: number[]): Promise<Category[]> {
    return this.dao.findByIds(ids);
  }

  // 🔹 para uso seguro (solo activos)
  async getActiveById(id: number): Promise<Category> {
    const cat = await this.dao.findById(id);

    if (!cat || cat.status !== "active") {
      throw new Error("Category not available");
    }

    return cat;
  }

  async update(id: number, data: CategoryUpdateInput): Promise<Category> {
    const existing = await this.getById(id);

    if (Object.keys(data).length === 0) {
      throw new Error("No valid fields provided for update");
    }

    // 🔹 si cambia entity_type, ajustar business_type
    if (data.entity_type && data.entity_type !== "business") {
      data.business_type = null;
    }

    // 🔹 si sigue siendo business pero no mandan business_type → mantener
    if (
      (data.entity_type === "business" || existing.entity_type === "business") &&
      data.business_type === undefined
    ) {
      data.business_type = existing.business_type;
    }

    return this.dao.update(id, data);
  }

  async softDelete(id: number): Promise<void> {
    await this.getById(id);
    return this.dao.softDelete(id);
  }

  // 🟡 deactivate
  async deactivate(id: number): Promise<Category> {
    await this.getById(id);
    return this.dao.deactivate(id);
  }

  // 🟢 activate
  async activate(id: number): Promise<Category> {
    await this.getById(id);
    return this.dao.activate(id);
  }

  async getActiveByType(
    entityType: CategoryEntityType,
    businessType?: BusinessType
  ): Promise<Category[]> {
    return this.dao.findByFilters({
      entity_type: entityType,
      status: "active",
      business_type:
        entityType === "business"
          ? businessType ?? null
          : null,
    });
  }

  async getByFilters(params: {
    entity_type?: CategoryEntityType;
    status?: BasicStatus;
    business_type?: BusinessType;
  }): Promise<Category[]> {
    return this.dao.findByFilters(params);
  }
}