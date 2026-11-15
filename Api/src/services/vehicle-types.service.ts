import { VehicleTypesDAO } from "../dao/vehicle-types.dao";
import { VehicleTypeCreateInput, VehicleTypeUpdateInput, VehicleTypeIdInput,
} from "../validation/vehicle-types.validation";
import { VehicleType } from "../dto/vehicle-type.dto";

export class VehicleTypesService {
  constructor(private readonly dao: VehicleTypesDAO) {}

  async create(input: VehicleTypeCreateInput): Promise<VehicleType> {
    return this.dao.create(input);
  }

  async getAll(): Promise<VehicleType[]> {
    return this.dao.findAll();
  }

  async getById(input: VehicleTypeIdInput): Promise<VehicleType> {
    const v = await this.dao.findById(input);

    if (!v) {
      throw new Error("Vehicle type not found");
    }

    return v;
  }

  async update(input: VehicleTypeUpdateInput): Promise<VehicleType> {
    const exists = await this.dao.exists({ id: input.id });

    if (!exists) {
      throw new Error("Vehicle type not found");
    }

    return this.dao.update(input);
  }

  async delete(input: VehicleTypeIdInput): Promise<void> {
    const exists = await this.dao.exists(input);

    if (!exists) {
      throw new Error("Vehicle type not found");
    }

    await this.dao.delete(input);
  }
}