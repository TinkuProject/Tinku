-- Ubicaciones internas de almacenes.
-- Un producto en un almacen mantiene una sola ubicacion interna opcional.

CREATE TABLE IF NOT EXISTS warehouse_locations (
  id bigserial PRIMARY KEY,
  warehouse_id bigint NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
  parent_id bigint REFERENCES warehouse_locations(id) ON DELETE SET NULL,
  name varchar(120) NOT NULL,
  code varchar(40) NOT NULL,
  description text,
  status basic_status NOT NULL DEFAULT 'active',
  sort_order int NOT NULL DEFAULT 0,
  created_by uuid REFERENCES users(id),
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL,
  UNIQUE (warehouse_id, code),
  CHECK (parent_id IS NULL OR parent_id <> id)
);

ALTER TABLE warehouse_inventory
  ADD COLUMN IF NOT EXISTS location_id bigint;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'warehouse_inventory_location_id_fkey'
  ) THEN
    ALTER TABLE warehouse_inventory
      ADD CONSTRAINT warehouse_inventory_location_id_fkey
      FOREIGN KEY (location_id)
      REFERENCES warehouse_locations(id)
      ON DELETE SET NULL;
  END IF;
END;
$$;

CREATE INDEX IF NOT EXISTS idx_warehouse_locations_warehouse
  ON warehouse_locations(warehouse_id, status, sort_order);

CREATE INDEX IF NOT EXISTS idx_warehouse_locations_parent
  ON warehouse_locations(parent_id);

CREATE INDEX IF NOT EXISTS idx_warehouse_inventory_location
  ON warehouse_inventory(location_id);
