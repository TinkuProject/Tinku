-- Agrega codigo alfanumerico de retiro para pedidos del marketplace.
-- Null temporalmente para no romper pedidos existentes.

ALTER TABLE marketplace_orders
  ADD COLUMN IF NOT EXISTS pickup_code varchar(20) UNIQUE;

UPDATE marketplace_orders
SET pickup_code = 'TK-' || UPPER(SUBSTRING(REPLACE(gen_random_uuid()::text, '-', ''), 1, 8))
WHERE pickup_code IS NULL;

CREATE INDEX IF NOT EXISTS idx_marketplace_orders_pickup_code
  ON marketplace_orders(pickup_code);
