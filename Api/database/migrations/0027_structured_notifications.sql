ALTER TABLE notifications
  ADD COLUMN IF NOT EXISTS type varchar(50),
  ADD COLUMN IF NOT EXISTS entity_type varchar(50),
  ADD COLUMN IF NOT EXISTS entity_id bigint,
  ADD COLUMN IF NOT EXISTS route varchar(180);

CREATE INDEX IF NOT EXISTS idx_notifications_entity
  ON notifications(entity_type, entity_id)
  WHERE entity_type IS NOT NULL AND entity_id IS NOT NULL;
