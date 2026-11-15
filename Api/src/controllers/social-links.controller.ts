import { Request, Response } from "express";
import { SocialLinksService } from "../services/social-links.service";
import { SocialLinksDAO } from "../dao/social-links.dao";
import { createSocialLinkSchema, updateSocialLinkSchema, socialLinkIdSchema,
  socialLinksByBusinessSchema, socialLinksByBusinessesSchema } from "../validation/social-links.validation";
import { handleError } from "../utils/handleError";
import { getUserClientFromRequest, supabaseAdmin, supabasePublic } from "../config/supabase-client.config";
import { OwnershipService } from "../services/ownership.service";

export class SocialLinksController {
  private getService(req: Request): SocialLinksService {
    const db = getUserClientFromRequest(req);
    const dao = new SocialLinksDAO(db);
    return new SocialLinksService(dao);
  }

  private getPublicService(): SocialLinksService {
    const dao = new SocialLinksDAO(supabasePublic);
    return new SocialLinksService(dao);
  }

  create = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = createSocialLinkSchema.parse(req.body);
      await new OwnershipService(supabaseAdmin).validate(
        "business",
        input.business_id,
        req.user!
      );

      const service = this.getService(req);
      const result = await service.create(input);

      res.status(201).json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByBusiness = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = socialLinksByBusinessSchema.parse({
        business_id: Number(req.params.businessId),
      });

      const service = this.getPublicService();
      const data = await service.getByBusiness(input);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  getByBusinesses = async (req: Request, res: Response): Promise<void> => {
    try {
      const { business_ids } = socialLinksByBusinessesSchema.parse({
        business_ids: req.query.business_ids,
      });

      const service = this.getPublicService();
      const data = await service.getByBusinesses(business_ids);

      res.json(data);
    } catch (err) {
      return handleError(res, err);
    }
  };

  update = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = updateSocialLinkSchema.parse({
        ...req.body,
        id: Number(req.params.id),
      });
      const ownership = new OwnershipService(supabaseAdmin);
      await ownership.validate("social_link", input.id, req.user!);
      if (input.business_id !== undefined) {
        await ownership.validate("business", input.business_id, req.user!);
      }

      const service = this.getService(req);
      const result = await service.update(input);

      res.json(result);
    } catch (err) {
      return handleError(res, err);
    }
  };

  delete = async (req: Request, res: Response): Promise<void> => {
    try {
      const input = socialLinkIdSchema.parse({
        id: Number(req.params.id),
      });
      await new OwnershipService(supabaseAdmin).validate(
        "social_link",
        input.id,
        req.user!
      );

      const service = this.getService(req);
      await service.delete(input);

      res.status(204).send();
    } catch (err) {
      return handleError(res, err);
    }
  };
}
