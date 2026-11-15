import { UserVisitsDAO } from "../dao/user-visits.dao";
import { UserVisit } from "../dto/user-visit.dto";
import { UserVisitCreateInput, UserVisitByUserInput, UserVisitByEntityInput,
  UserVisitEntityCountsInput,
} from "../validation/user-visits.validation";

export class UserVisitsService {
  constructor(private readonly dao: UserVisitsDAO) {}

  async create(
    user_id: string,
    input: UserVisitCreateInput
  ): Promise<UserVisit> {
    if (input.type === "favorited") {
      const exists = await this.dao.exists(
        user_id,
        input.entity_type,
        input.entity_id,
        input.type
      );

      if (exists) {
        throw new Error("User visit already exists");
      }
    }

    return this.dao.create(user_id, input);
  }

  async getByUser(
    input: UserVisitByUserInput
  ): Promise<UserVisit[]> {
    return this.dao.findByUser(input);
  }

  async getByEntity(
    user_id: string,
    input: UserVisitByEntityInput
  ): Promise<UserVisit[]> {
    return this.dao.findByEntity(user_id, input);
  }

  async countByEntities(
    input: UserVisitEntityCountsInput
  ): Promise<Record<number, number>> {
    return this.dao.countByEntities(input.entity_type, input.ids, input.type);
  }

  async delete(
    user_id: string,
    entity_type: string,
    entity_id: number
  ): Promise<void> {
    await this.dao.delete(user_id, entity_type, entity_id);
  }
}
