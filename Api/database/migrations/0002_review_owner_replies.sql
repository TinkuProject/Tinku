-- Permite que el dueño de un negocio, servicio o evento responda reseñas.
-- Los campos son nullable para no afectar reseñas existentes.

BEGIN;

ALTER TABLE reviews
  ADD COLUMN IF NOT EXISTS owner_reply text,
  ADD COLUMN IF NOT EXISTS owner_reply_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS owner_reply_at timestamp;

CREATE INDEX IF NOT EXISTS idx_reviews_owner_reply_at
  ON reviews(owner_reply_at);

COMMIT;
