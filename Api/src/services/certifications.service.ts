import { BasicStatus } from "../constants/enums.constants";
import { CertificationsDAO } from "../dao/certifications.dao";
import { Certification } from "../dto/certification.dto";
import { CertificationCreateInput, CertificationUpdateInput,
} from "../validation/certifications.validation";

export class CertificationsService {
  constructor(private dao: CertificationsDAO) {}

  async create(data: CertificationCreateInput): Promise<Certification> {
    return this.dao.create(data);
  }

  async getAll(includeNonPublic = false): Promise<Certification[]> {
    return includeNonPublic
      ? this.dao.findAll()
      : this.dao.findAllPublic();
  }

  async getById(
    id: number,
    includeNonPublic = false
  ): Promise<Certification> {
    const cert = includeNonPublic
      ? await this.dao.findById(id)
      : await this.dao.findPublicById(id);

    if (!cert) {
      throw new Error("Certification not found");
    }

    return cert;
  }

  async getByBusiness(businessId: number): Promise<Certification[]> {
    return this.dao.findByBusinessId(businessId);
  }

  async getByBusinessAdmin(businessId: number): Promise<Certification[]> {
    return this.dao.findByBusinessIdAdmin(businessId);
  }

  async getByBusinesses(
    businessIds: number[]
  ): Promise<Record<string, Certification[]>> {
    return this.dao.findByBusinessIds(businessIds);
  }

  async getByBusinessesAdmin(
    businessIds: number[]
  ): Promise<Record<string, Certification[]>> {
    return this.dao.findByBusinessIdsAdmin(businessIds);
  }

  async update(
    id: number,
    data: CertificationUpdateInput
  ): Promise<Certification> {
    const existing = await this.dao.findById(id);

    if (!existing) {
      throw new Error("Certification not found");
    }

    return this.dao.update(id, data);
  }

  async softDelete(id: number): Promise<Certification> {
    const existing = await this.dao.findById(id);

    if (!existing) {
      throw new Error("Certification not found");
    }

    return this.dao.softDelete(id);
  }

  async activate(id: number): Promise<Certification> {
    return this.dao.activate(id);
  }

  async deactivate(id: number): Promise<Certification> {
    return this.dao.deactivate(id);
  }

  async getByFilters(params: {
    business_id?: number;
    status?: BasicStatus;
  }): Promise<Certification[]> {
    return this.dao.findByFilters(params);
  }
}
