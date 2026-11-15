import { REVIEW_BLOCKED_TERMS } from "../constants/review-blocked-terms.constants";

export const REVIEW_LANGUAGE_MESSAGE =
  "El texto contiene lenguaje ofensivo. Revísalo antes de enviarlo.";

export function hasBlockedReviewLanguage(value: string | null | undefined): boolean {
  if (!value) return false;

  const normalized = value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[@4]/g, "a")
    .replace(/3/g, "e")
    .replace(/[1!]/g, "i")
    .replace(/0/g, "o")
    .replace(/5/g, "s")
    .replace(/7/g, "t");

  return normalized
    .split(/[^a-z]+/)
    .some((word) => REVIEW_BLOCKED_TERMS.has(word));
}
