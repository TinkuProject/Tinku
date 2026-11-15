import { DbClient } from "../types/db-client";
import { VehicleType } from "../dto/vehicle-type.dto";
import { VehicleTypeCreateInput, VehicleTypeUpdateInput,
  VehicleTypeIdInput } from "../validation/vehicle-types.validation";

export class VehicleTypesDAO {
  private table = "vehicle_types";
  constructor(private readonly db: DbClient) {}

  private mapToEntity(data: any): VehicleType {
    return {
      id: data.id,
      name: data.name,
    };
  }

  async create(input: VehicleTypeCreateInput): Promise<VehicleType> {
    const { data, error } = await this.db
      .from(this.table)
      .insert(input)
      .select()
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async findAll(): Promise<VehicleType[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .order("name");

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async findById(
    input: VehicleTypeIdInput
  ): Promise<VehicleType | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToEntity(data) : null;
  }

  async update(
    input: VehicleTypeUpdateInput
  ): Promise<VehicleType> {
    const { id, ...updates } = input;

    const { data, error } = await this.db
      .from(this.table)
      .update(updates)
      .eq("id", id)
      .select()
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async delete(input: VehicleTypeIdInput): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("id", input.id);

    if (error) throw error;
  }

  async exists(input: VehicleTypeIdInput): Promise<boolean> {
    const { data, error } = await this.db
      .from(this.table)
      .select("id")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return !!data;
  }
}