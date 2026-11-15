import { UserRole } from "../constants/enums.constants";
import { HomeDashboardDAO } from "../dao/home-dashboard.dao";

export class HomeDashboardService {
  constructor(private readonly dao: HomeDashboardDAO) {}

  async get(userId: string, role: UserRole) {
    if (role === "admin" || role === "master") {
      return {
        mode: "admin" as const,
        admin: await this.dao.getAdminSummary(userId, role),
      };
    }

    const summary = await this.dao.getPartnerSummary(userId, role);
    return {
      mode: "partner" as const,
      ...summary,
    };
  }
}
