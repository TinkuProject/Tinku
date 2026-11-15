ALTER TYPE warehouse_stock_request_status ADD VALUE IF NOT EXISTS 'sent';
ALTER TYPE warehouse_stock_request_status ADD VALUE IF NOT EXISTS 'received';

ALTER TABLE warehouse_stock_requests
  ADD COLUMN IF NOT EXISTS location_id bigint,
  ADD COLUMN IF NOT EXISTS sent_at timestamp NULL,
  ADD COLUMN IF NOT EXISTS received_at timestamp NULL,
  ADD COLUMN IF NOT EXISTS received_by uuid REFERENCES users(id);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'warehouse_stock_requests_location_id_fkey'
  ) THEN
    ALTER TABLE warehouse_stock_requests
      ADD CONSTRAINT warehouse_stock_requests_location_id_fkey
      FOREIGN KEY (location_id)
      REFERENCES warehouse_locations(id)
      ON DELETE SET NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_warehouse_stock_requests_received
  ON warehouse_stock_requests(warehouse_id, status, received_at DESC);
