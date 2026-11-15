import { UserLabelsDAO } from "../dao/user-labels.dao";
import { AssignUserLabelInput, UserLabelParamsInput, UserLabelByUserInput,
} from "../validation/user-labels.validation";
import { UserLabel } from "../dto/user-label.dto";

export class UserLabelsService {
  constructor(private readonly dao: UserLabelsDAO) {}

  async assign(input: AssignUserLabelInput): Promise<void> {
    const exists = await this.dao.exists(input);

    if (exists) {
      // evitar duplicados silenciosos
      return;
    }

    await this.dao.assign(input);
  }

  async getByUser(
    input: UserLabelByUserInput
  ): Promise<UserLabel[]> {
    return this.dao.findByUser(input);
  }

  async getMyLabels(): Promise<UserLabel[]> {
    return this.dao.getMyLabels();
  }

  async remove(input: UserLabelParamsInput): Promise<void> {
    const exists = await this.dao.exists(input);

    if (!exists) {
      throw new Error("User label not found");
    }

    await this.dao.remove(input);
  }
}