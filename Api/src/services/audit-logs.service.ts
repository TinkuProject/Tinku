import { AuditLogsDAO } from "../dao/audit-logs.dao";
import { AuditLog } from "../dto/audit-log.dto";
import { AuditLogCreateInput } from "../validation/audit-logs.validation";

export class AuditLogsService {
  constructor(private dao: AuditLogsDAO) { }

  async create(data: AuditLogCreateInput): Promise<AuditLog> {
    return this.dao.create(data);
  }

  async getAll(limit = 50, offset = 0): Promise<AuditLog[]> {
    const safeLimit = Math.min(limit, 100);
    return this.dao.findAll(safeLimit, offset);
  }

  async getById(id: number): Promise<AuditLog> {
    if (!id || id <= 0) {
      throw new Error("Invalid id");
    }

    const log = await this.dao.findById(id);

    if (!log) {
      throw new Error("Audit log not found");
    }

    return log;
  }

  async getByUser(
    user_id: string,
    limit = 50,
    offset = 0
  ): Promise<AuditLog[]> {
    if (!user_id) {
      throw new Error("user_id is required");
    }

    const safeLimit = Math.min(limit, 100);
    return this.dao.findByUser(user_id, safeLimit, offset);
  }

  async getByEntity(
    entity_type: string,
    entity_id: number
  ): Promise<AuditLog[]> {
    if (!entity_type || entity_id <= 0) {
      throw new Error("Invalid parameters");
    }

    return this.dao.findByEntity(entity_type, entity_id);
  }

  async getByFilters(params: {
    user_id?: string;
    entity_type?: string;
    entity_id?: number;
    action?: string;
    limit?: number;
    offset?: number;
  }): Promise<AuditLog[]> {
    const safeLimit = Math.min(params.limit ?? 50, 100);

    return this.dao.findByFilters({
      ...params,
      limit: safeLimit,
      offset: params.offset ?? 0,
    });
  }
}