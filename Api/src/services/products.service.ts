import { ProductsDAO } from "../dao/products.dao";
import { Product } from "../dto/product.dto";
import { ProductCreateInput, ProductUpdateInput } from "../validation/products.validation";

export class ProductsService {
  constructor(private dao: ProductsDAO) {}

  async create(data: ProductCreateInput): Promise<Product> {
    if (
      data.price === undefined &&
      data.tinku_price === undefined
    ) {
      throw new Error("Product must have price or tinku_price");
    }

    return this.dao.create({
      ...data,
      status: "active",
    });
  }

  getAll(): Promise<Product[]> {
    return this.dao.getAll();
  }

  getActive(): Promise<Product[]> {
    return this.dao.getActive();
  }

  async getById(id: number): Promise<Product> {
    const product = await this.dao.getById(id);

    if (!product) {
      throw new Error("Product not found");
    }

    return product;
  }

  async getPublicById(id: number): Promise<Product> {
    const product = await this.dao.getPublicById(id);
    if (!product) throw new Error("Product not found");
    return product;
  }

  getByBusiness(businessId: number): Promise<Product[]> {
    return this.dao.getByBusiness(businessId);
  }

  getMine(userId: string) {
    return this.dao.getMine(userId);
  }

  async getByBusinesses(
    businessIds: number[]
  ): Promise<Record<number, Product[]>> {
    return this.dao.getByBusinesses(businessIds);
  }

  async getByBusinessesAdmin(
    businessIds: number[]
  ): Promise<Record<number, Product[]>> {
    return this.dao.getByBusinessesAdmin(businessIds);
  }

  getByBusinessAdmin(
    businessId: number
  ): Promise<Product[]> {
    return this.dao.getByBusinessAdmin(businessId);
  }

  async update(
    id: number,
    data: ProductUpdateInput
  ): Promise<Product> {
    const existing = await this.dao.getById(id);

    if (!existing) {
      throw new Error("Product not found");
    }

    // validar precios solo si vienen
    if (
      data.price !== undefined ||
      data.tinku_price !== undefined
    ) {
      if (
        data.price === undefined &&
        data.tinku_price === undefined
      ) {
        throw new Error(
          "Product must have price or tinku_price"
        );
      }
    }

    return this.dao.update(id, data);
  }

  async softDelete(id: number): Promise<Product> {
    const existing = await this.dao.getById(id);

    if (!existing) {
      throw new Error("Product not found");
    }

    return this.dao.softDelete(id);
  }
}
