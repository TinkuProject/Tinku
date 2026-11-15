import { SocialLinksDAO } from "../dao/social-links.dao";
import { CreateSocialLinkInput, UpdateSocialLinkInput, SocialLinkIdInput,
  SocialLinksByBusinessInput } from "../validation/social-links.validation";
import { SocialLink } from "../dto/social-link.dto";

export class SocialLinksService {
  constructor(private readonly dao: SocialLinksDAO) {}

  async create(input: CreateSocialLinkInput): Promise<SocialLink> {
    return this.dao.create(input);
  }

  async getAll(): Promise<SocialLink[]> {
    return this.dao.findAll();
  }

  async getById(input: SocialLinkIdInput): Promise<SocialLink | null> {
    return this.dao.findById(input);
  }

  async getByBusiness(
    input: SocialLinksByBusinessInput
  ): Promise<SocialLink[]> {
    return this.dao.findByBusinessId(input);
  }

  async getByBusinesses(
    businessIds: number[]
  ): Promise<Record<string, SocialLink[]>> {
    return this.dao.findByBusinessIds(businessIds);
  }

  async update(input: UpdateSocialLinkInput): Promise<SocialLink> {
    const exists = await this.dao.exists({ id: input.id });

    if (!exists) {
      throw new Error("Social link not found");
    }

    return this.dao.update(input);
  }

  async delete(input: SocialLinkIdInput): Promise<void> {
    const exists = await this.dao.exists(input);

    if (!exists) {
      throw new Error("Social link not found");
    }

    await this.dao.delete(input);
  }

  async replaceAllByBusiness(
    businessId: number,
    items: Array<{ platform: string; url: string }>
  ): Promise<void> {
    const existing = await this.dao.findByBusinessId({
      business_id: businessId,
    });

    await Promise.all(
      existing.map((item) => this.dao.delete({ id: item.id }))
    );

    for (const item of items) {
      await this.dao.create({
        business_id: businessId,
        platform: item.platform,
        url: item.url,
      });
    }
  }
}
