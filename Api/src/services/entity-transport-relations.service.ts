import { EntityTransportRelationsDAO } from "../dao/entity-transport-relations.dao";
import { VisitEntity } from "../constants/enums.constants";
import { EntityTransportRelationCreateInput } from "../validation/entity-transport-relations.validation";

export class EntityTransportRelationsService {
  constructor(private dao: EntityTransportRelationsDAO) { }

  async create(data: EntityTransportRelationCreateInput) {
    return this.dao.create(data);
  }

  getByEntity(entityType: VisitEntity, entityId: number) {
    return this.dao.getByEntity(entityType, entityId);
  }

  getByEntities(entityType: VisitEntity, entityIds: number[]) {
    return this.dao.getByEntities(entityType, entityIds);
  }

  async replaceLines(
    entityType: VisitEntity,
    entityId: number,
    newLineIds: number[]
  ) {
    return this.dao.replace(entityType, entityId, newLineIds);
  }

  delete(
    entityType: VisitEntity,
    entityId: number,
    transportLineId: number
  ) {
    return this.dao.delete(entityType, entityId, transportLineId);
  }

  deleteByEntity(entityType: VisitEntity, entityId: number) {
    return this.dao.deleteByEntity(entityType, entityId);
  }

  refreshNearby(input: {
    entityType: VisitEntity;
    entityId: number;
    latitude: number;
    longitude: number;
    radiusMeters?: number;
  }) {
    return this.dao.refreshNearby(input);
  }

  refreshAllNearby(radiusMeters = 1000) {
    return this.dao.refreshAllNearby(radiusMeters);
  }
}
