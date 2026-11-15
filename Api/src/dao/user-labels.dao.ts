import { DbClient } from "../types/db-client";
import { UserLabel } from "../dto/user-label.dto";
import { AssignUserLabelInput, UserLabelParamsInput, UserLabelByUserInput,
} from "../validation/user-labels.validation";

export class UserLabelsDAO {
  private table = "user_labels";
  constructor(private readonly db: DbClient) {}

  private mapToEntity(data: any): UserLabel {
    return {
      user_id: data.user_id,
      label_id: data.label_id,
      assigned_at: new Date(data.assigned_at),
    };
  }

  async assign(input: AssignUserLabelInput): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .insert(input);

    if (error) throw error;
  }

  async findByUser(
    input: UserLabelByUserInput
  ): Promise<UserLabel[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*")
      .eq("user_id", input.user_id);

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async getMyLabels(): Promise<UserLabel[]> {
    const { data, error } = await this.db
      .from(this.table)
      .select("*");

    if (error) throw error;

    return (data ?? []).map((i) => this.mapToEntity(i));
  }

  async remove(input: UserLabelParamsInput): Promise<void> {
    const { error } = await this.db
      .from(this.table)
      .delete()
      .match({
        user_id: input.user_id,
        label_id: input.label_id,
      });

    if (error) throw error;
  }

  async exists(input: UserLabelParamsInput): Promise<boolean> {
    const { data, error } = await this.db
      .from(this.table)
      .select("user_id")
      .match({
        user_id: input.user_id,
        label_id: input.label_id,
      })
      .maybeSingle();

    if (error) throw error;

    return !!data;
  }
}