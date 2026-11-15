import { DbClient } from "../types/db-client";
import { Label } from "../dto/label.dto";
import { LabelCreateInput, LabelUpdateInput } from "../validation/labels.validation";

export class LabelsDAO {
  private table = "labels";
  constructor(private db: DbClient) {}

  private mapToDomain(row: any): Label {
    if (!row) return row;

    return {
      ...row,
      created_at: new Date(row.created_at),
    };
  }

  async create(data: LabelCreateInput): Promise<Label> {
    const { data: result, error } = await this.db
      .from(this.table)
      .insert(data)
      .select()
      .single();

    if (error) throw error;
    return this.mapToDomain(result);
  }

  async getAll(): Promise<Label[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .order("created_at", { ascending: false });

    if (error) throw error;
    return (data || []).map((row) => this.mapToDomain(row));
  }

  async getById(id: number): Promise<Label | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", id)
      .maybeSingle();

    if (error) throw error;
    return data ? this.mapToDomain(data) : null;
  }

  async update(id: number, updates: LabelUpdateInput): Promise<Label> {
    const { data, error } = await this.db
      .from(this.table)
      .update(updates)
      .eq("id", id)
      .select()
      .single();

    if (error) throw error;
    return this.mapToDomain(data);
  }

  async delete(id: number): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("id", id);

    if (error) throw error;
  }
}