-- Track creator for tourist places so admin/master management views can show
-- only the places created by the logged-in administrator.

BEGIN;

ALTER TABLE tourist_places
  ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_tourist_places_created_by
  ON tourist_places(created_by, created_at DESC);

COMMIT;
