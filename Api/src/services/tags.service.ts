import { TagsDAO } from "../dao/tags.dao";
import { TagCreateInput, TagUpdateInput, TagIdInput,
} from "../validation/tags.validation";
import { Tag } from "../dto/tag.dto";

export class TagsService {
  constructor(private readonly dao: TagsDAO) {}

  async create(input: TagCreateInput): Promise<Tag> {
    return this.dao.create(input);
  }

  async getAll(): Promise<Tag[]> {
    return this.dao.findAll();
  }

  async getById(input: TagIdInput): Promise<Tag> {
    const tag = await this.dao.findById(input);

    if (!tag) {
      throw new Error("Tag not found");
    }

    return tag;
  }

  async update(input: TagUpdateInput): Promise<Tag> {
    const exists = await this.dao.exists({ id: input.id });

    if (!exists) {
      throw new Error("Tag not found");
    }

    return this.dao.update(input);
  }

  async softDelete(input: TagIdInput): Promise<Tag> {
    const exists = await this.dao.exists(input);

    if (!exists) {
      throw new Error("Tag not found");
    }

    return this.dao.softDelete(input.id);
  }
}