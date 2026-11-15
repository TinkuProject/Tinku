DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'warehouse_stock_request_status') THEN
    CREATE TYPE warehouse_stock_request_status AS ENUM ('pending', 'approved', 'rejected', 'cancelled');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS warehouse_stock_requests (
  id bigserial PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  warehouse_id bigint NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
  product_id bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  requested_by uuid NOT NULL REFERENCES users(id),
  processed_by uuid REFERENCES users(id),
  quantity int NOT NULL CHECK (quantity > 0),
  status warehouse_stock_request_status NOT NULL DEFAULT 'pending',
  notes text,
  response_message text,
  processed_at timestamp NULL,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE INDEX IF NOT EXISTS idx_warehouse_stock_requests_business
  ON warehouse_stock_requests(business_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_warehouse_stock_requests_warehouse
  ON warehouse_stock_requests(warehouse_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_warehouse_stock_requests_product
  ON warehouse_stock_requests(product_id, created_at DESC);
