import { DbClient } from "../types/db-client";
import { Tag } from "../dto/tag.dto";
import { TagCreateInput, TagUpdateInput, TagIdInput } from "../validation/tags.validation";

export class TagsDAO {
  private table = "tags";
  constructor(private readonly db: DbClient) {}

  private mapToEntity(data: any): Tag {
    return {
      id: data.id,
      name: data.name,
      description: data.description ?? null,
      status: data.status,
      created_at: new Date(data.created_at),
      updated_at: data.updated_at ? new Date(data.updated_at) : null,
    };
  }

  async create(input: TagCreateInput): Promise<Tag> {
    const { data, error } = await this.db
      .from(this.table)
      .insert(input)
      .select()
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async findAll(): Promise<Tag[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .in("status", ["active", "inactive"]) // no mostrar archived
      .order("name");

    if (error) throw error;

    return (data ?? []).map((item) => this.mapToEntity(item));
  }

  async findById(input: TagIdInput): Promise<Tag | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToEntity(data) : null;
  }

  async update(input: TagUpdateInput): Promise<Tag> {
    const { id, ...updates } = input;

    const { data, error } = await this.db
      .from(this.table)
      .update({
        ...updates,
        updated_at: new Date(),
      })
      .eq("id", id)
      .select()
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async softDelete(id: number): Promise<Tag> {
    const { data, error } = await this.db
      .from(this.table)
      .update({
        status: "archived",
        updated_at: new Date(),
      })
      .eq("id", id)
      .select("*")
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async exists(input: TagIdInput): Promise<boolean> {
    const { data, error } = await this.db
      .from(this.table)
      .select("id")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return !!data;
  }
}