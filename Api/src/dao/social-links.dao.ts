import { DbClient } from "../types/db-client";
import { SocialLink } from "../dto/social-link.dto";
import { CreateSocialLinkInput, UpdateSocialLinkInput, SocialLinkIdInput,
  SocialLinksByBusinessInput } from "../validation/social-links.validation";

export class SocialLinksDAO {
  private table = "social_links";

  constructor(private readonly db: DbClient) {}

  private mapToEntity(data: any): SocialLink {
    return {
      id: data.id,
      business_id: data.business_id,
      platform: data.platform,
      url: data.url,
      created_at: new Date(data.created_at),
      updated_at: data.updated_at ? new Date(data.updated_at) : null,
    };
  }

  async create(input: CreateSocialLinkInput): Promise<SocialLink> {
    const { data, error } = await this.db
      .from(this.table)
      .insert(input)
      .select()
      .single();

    if (error) throw error;

    return this.mapToEntity(data);
  }

  async findAll(): Promise<SocialLink[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*");

    if (error) throw error;

    return (data ?? []).map(this.mapToEntity);
  }

  async findById(input: SocialLinkIdInput): Promise<SocialLink | null> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return data ? this.mapToEntity(data) : null;
  }

  async findByBusinessId(
    input: SocialLinksByBusinessInput
  ): Promise<SocialLink[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("business_id", input.business_id);

    if (error) throw error;

    return (data ?? []).map(this.mapToEntity);
  }

  async findByBusinessIds(
    businessIds: number[]
  ): Promise<Record<string, SocialLink[]>> {
    const uniqueIds = [...new Set(businessIds)];

    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .in("business_id", uniqueIds);

    if (error) throw error;

    const result: Record<string, SocialLink[]> = {};

    for (const row of data ?? []) {
      const mapped = this.mapToEntity(row);
      const key = String(mapped.business_id);

      if (!result[key]) {
        result[key] = [];
      }

      result[key].push(mapped);
    }

    return result;
  }

  async update(input: UpdateSocialLinkInput): Promise<SocialLink> {
    const { id, ...data } = input;

    const { data: result, error } = await this.db
      .from(this.table)
      .update({
        ...data,
        updated_at: new Date(),
      })
      .eq("id", id)
      .select()
      .single();

    if (error) throw error;

    return this.mapToEntity(result);
  }

  async delete(input: SocialLinkIdInput): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .eq("id", input.id);

    if (error) throw error;
  }

  async exists(input: SocialLinkIdInput): Promise<boolean> {
    const { data, error } = await this.db
      .from(this.table)
      .select("id")
      .eq("id", input.id)
      .maybeSingle();

    if (error) throw error;

    return !!data;
  }
}
