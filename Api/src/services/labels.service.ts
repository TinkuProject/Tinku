import { LabelsDAO } from "../dao/labels.dao";
import { LabelCreateInput, LabelUpdateInput } from "../validation/labels.validation";
import { Label } from "../dto/label.dto";

export class LabelsService {
  constructor(private dao: LabelsDAO) {}

  create(data: LabelCreateInput): Promise<Label> {
    return this.dao.create(data);
  }

  getAll(): Promise<Label[]> {
    return this.dao.getAll();
  }

  async getById(id: number): Promise<Label> {
    const label = await this.dao.getById(id);

    if (!label) {
      throw new Error("Label not found");
    }

    return label;
  }

  update(id: number, data: LabelUpdateInput): Promise<Label> {
    return this.dao.update(id, data);
  }

  delete(id: number): Promise<void> {
    return this.dao.delete(id);
  }
}