-- Marketplace, almacenes y metricas de vistas de negocios.
--
-- Ejecutar en bases existentes despues de tener aplicados 01-05.
-- Es idempotente para poder correrlo en local y server sin duplicar datos.

BEGIN;

-- =========================
-- ENUMS
-- =========================

DO $$
BEGIN
  ALTER TYPE media_entity_type ADD VALUE IF NOT EXISTS 'warehouse';
  ALTER TYPE media_entity_type ADD VALUE IF NOT EXISTS 'product_publication';
  ALTER TYPE payment_type ADD VALUE IF NOT EXISTS 'product_publication';
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'warehouse_status') THEN
    CREATE TYPE warehouse_status AS ENUM ('pending', 'active', 'inactive', 'archived');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'warehouse_inventory_status') THEN
    CREATE TYPE warehouse_inventory_status AS ENUM ('available', 'reserved', 'delivered', 'returned', 'cancelled');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'marketplace_publication_status') THEN
    CREATE TYPE marketplace_publication_status AS ENUM ('draft', 'active', 'paused', 'sold_out', 'archived');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'marketplace_order_status') THEN
    CREATE TYPE marketplace_order_status AS ENUM ('pending', 'paid', 'preparing', 'ready_for_pickup', 'in_delivery', 'delivered', 'cancelled');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'delivery_status') THEN
    CREATE TYPE delivery_status AS ENUM ('pending', 'assigned', 'picked_up', 'delivered', 'cancelled');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'fulfillment_method') THEN
    CREATE TYPE fulfillment_method AS ENUM ('pickup', 'warehouse_delivery');
  END IF;
END;
$$;

-- =========================
-- CONFIG
-- =========================

INSERT INTO system_config (key, value, description)
VALUES
  ('product_publication_base_cost', '5', 'Costo base en Tinkus por publicar un producto en marketplace'),
  ('product_publication_stock_unit_cost', '1', 'Costo en Tinkus por unidad publicada'),
  ('product_publication_price_rate', '0.02', 'Factor de costo sobre precio por unidad publicada'),
  ('warehouse_delivery_reward_tinkus', '3', 'Recompensa en Tinkus para almacenes por entrega realizada')
ON CONFLICT (key)
DO UPDATE SET
  value = EXCLUDED.value,
  description = EXCLUDED.description,
  updated_at = CURRENT_TIMESTAMP;

-- =========================
-- ALMACENES
-- =========================

CREATE TABLE IF NOT EXISTS warehouses (
  id bigserial PRIMARY KEY,
  owner_id uuid REFERENCES users(id),
  name varchar(150) NOT NULL,
  description text,
  phone varchar(20),
  email varchar(100),
  address varchar(250),
  location geography(Point, 4326),
  validated boolean NOT NULL DEFAULT false,
  status warehouse_status NOT NULL DEFAULT 'pending',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE IF NOT EXISTS business_fulfillment_options (
  business_id bigint PRIMARY KEY REFERENCES businesses(id) ON DELETE CASCADE,
  pickup_in_store boolean NOT NULL DEFAULT false,
  warehouse_delivery boolean NOT NULL DEFAULT false,
  notes text,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

ALTER TABLE business_fulfillment_options
  ADD COLUMN IF NOT EXISTS warehouse_delivery boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS notes text;

CREATE TABLE IF NOT EXISTS business_warehouses (
  business_id bigint NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  warehouse_id bigint NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
  status basic_status NOT NULL DEFAULT 'active',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL,

  PRIMARY KEY (business_id, warehouse_id)
);

CREATE TABLE IF NOT EXISTS charging_point_warehouses (
  charging_point_id bigint NOT NULL REFERENCES charging_points(id) ON DELETE CASCADE,
  warehouse_id bigint NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
  status basic_status NOT NULL DEFAULT 'active',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL,

  PRIMARY KEY (charging_point_id, warehouse_id)
);

CREATE TABLE IF NOT EXISTS warehouse_inventory (
  id bigserial PRIMARY KEY,
  warehouse_id bigint NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
  product_id bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  quantity int NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  reserved_quantity int NOT NULL DEFAULT 0 CHECK (reserved_quantity >= 0),
  status warehouse_inventory_status NOT NULL DEFAULT 'available',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL,

  UNIQUE (warehouse_id, product_id),
  CHECK (reserved_quantity <= quantity)
);

CREATE TABLE IF NOT EXISTS warehouse_product_history (
  id bigserial PRIMARY KEY,
  warehouse_id bigint NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
  product_id bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  changed_by uuid REFERENCES users(id),
  previous_quantity int,
  new_quantity int NOT NULL CHECK (new_quantity >= 0),
  reason text,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- MARKETPLACE
-- =========================

CREATE TABLE IF NOT EXISTS product_publications (
  id bigserial PRIMARY KEY,
  product_id bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  business_id bigint NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  created_by uuid NOT NULL REFERENCES users(id),
  published_stock int NOT NULL CHECK (published_stock >= 0),
  unit_price decimal(10,2),
  unit_tinku_price int,
  calculated_cost_tinkus int NOT NULL DEFAULT 0 CHECK (calculated_cost_tinkus >= 0),
  charged_tinkus int NOT NULL DEFAULT 0 CHECK (charged_tinkus >= 0),
  status marketplace_publication_status NOT NULL DEFAULT 'active',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL,

  CHECK (unit_price IS NOT NULL OR unit_tinku_price IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS product_publication_history (
  id bigserial PRIMARY KEY,
  publication_id bigint NOT NULL REFERENCES product_publications(id) ON DELETE CASCADE,
  changed_by uuid REFERENCES users(id),
  previous_stock int,
  new_stock int NOT NULL CHECK (new_stock >= 0),
  previous_cost_tinkus int,
  new_cost_tinkus int NOT NULL CHECK (new_cost_tinkus >= 0),
  additional_charged_tinkus int NOT NULL DEFAULT 0 CHECK (additional_charged_tinkus >= 0),
  reason text,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS marketplace_orders (
  id bigserial PRIMARY KEY,
  buyer_id uuid NOT NULL REFERENCES users(id),
  status marketplace_order_status NOT NULL DEFAULT 'pending',
  total_amount decimal(10,2) NOT NULL DEFAULT 0,
  total_tinkus int NOT NULL DEFAULT 0,
  fulfillment fulfillment_method NOT NULL DEFAULT 'pickup',
  pickup_business_id bigint REFERENCES businesses(id),
  warehouse_id bigint REFERENCES warehouses(id),
  delivery_address varchar(250),
  delivery_location geography(Point, 4326),

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE IF NOT EXISTS marketplace_order_items (
  id bigserial PRIMARY KEY,
  order_id bigint NOT NULL REFERENCES marketplace_orders(id) ON DELETE CASCADE,
  publication_id bigint NOT NULL REFERENCES product_publications(id),
  product_id bigint NOT NULL REFERENCES products(id),
  business_id bigint NOT NULL REFERENCES businesses(id),
  quantity int NOT NULL CHECK (quantity > 0),
  unit_price decimal(10,2),
  unit_tinku_price int,
  subtotal_amount decimal(10,2) NOT NULL DEFAULT 0,
  subtotal_tinkus int NOT NULL DEFAULT 0,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS deliveries (
  id bigserial PRIMARY KEY,
  order_id bigint NOT NULL REFERENCES marketplace_orders(id) ON DELETE CASCADE,
  warehouse_id bigint NOT NULL REFERENCES warehouses(id),
  status delivery_status NOT NULL DEFAULT 'pending',
  reward_tinkus int NOT NULL DEFAULT 0 CHECK (reward_tinkus >= 0),
  reward_transaction_id bigint REFERENCES financial_transactions(id),
  picked_up_at timestamp NULL,
  delivered_at timestamp NULL,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

-- =========================
-- VISTAS DE NEGOCIO
-- =========================

CREATE TABLE IF NOT EXISTS business_view_daily (
  business_id bigint NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  day date NOT NULL,
  views_count int NOT NULL DEFAULT 0 CHECK (views_count >= 0),

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL,

  PRIMARY KEY (business_id, day)
);

CREATE TABLE IF NOT EXISTS business_view_totals (
  business_id bigint PRIMARY KEY REFERENCES businesses(id) ON DELETE CASCADE,
  total_views bigint NOT NULL DEFAULT 0 CHECK (total_views >= 0),
  last_viewed_at timestamp NULL,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

-- =========================
-- INDEXES
-- =========================

CREATE INDEX IF NOT EXISTS idx_warehouses_owner ON warehouses(owner_id);
CREATE INDEX IF NOT EXISTS idx_warehouses_status ON warehouses(status);
CREATE INDEX IF NOT EXISTS idx_warehouses_location ON warehouses USING GIST(location);

CREATE INDEX IF NOT EXISTS idx_business_warehouses_warehouse ON business_warehouses(warehouse_id);
CREATE INDEX IF NOT EXISTS idx_charging_point_warehouses_warehouse ON charging_point_warehouses(warehouse_id);

CREATE INDEX IF NOT EXISTS idx_warehouse_inventory_warehouse ON warehouse_inventory(warehouse_id);
CREATE INDEX IF NOT EXISTS idx_warehouse_inventory_product ON warehouse_inventory(product_id);
CREATE INDEX IF NOT EXISTS idx_warehouse_product_history_product ON warehouse_product_history(product_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_product_publications_product ON product_publications(product_id);
CREATE INDEX IF NOT EXISTS idx_product_publications_business_status ON product_publications(business_id, status);
CREATE INDEX IF NOT EXISTS idx_product_publications_created_by ON product_publications(created_by);
CREATE UNIQUE INDEX IF NOT EXISTS idx_product_publications_open_product ON product_publications(product_id)
WHERE status <> 'archived';
CREATE INDEX IF NOT EXISTS idx_product_publication_history_publication ON product_publication_history(publication_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_marketplace_orders_buyer ON marketplace_orders(buyer_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_marketplace_orders_status ON marketplace_orders(status);
CREATE INDEX IF NOT EXISTS idx_marketplace_orders_warehouse ON marketplace_orders(warehouse_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_order_items_order ON marketplace_order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_order_items_publication ON marketplace_order_items(publication_id);

CREATE INDEX IF NOT EXISTS idx_deliveries_warehouse_status ON deliveries(warehouse_id, status);
CREATE INDEX IF NOT EXISTS idx_deliveries_order ON deliveries(order_id);
CREATE INDEX IF NOT EXISTS idx_business_view_daily_day ON business_view_daily(day DESC);

-- =========================
-- FUNCTIONS
-- =========================

CREATE OR REPLACE FUNCTION calculate_product_publication_cost(
  p_stock int,
  p_unit_price numeric DEFAULT 0
)
RETURNS int
LANGUAGE plpgsql
STABLE
SET search_path = public
AS $$
DECLARE
  v_base numeric := 0;
  v_stock_unit numeric := 0;
  v_price_rate numeric := 0;
BEGIN
  IF p_stock < 0 THEN
    RAISE EXCEPTION 'Stock must be greater than or equal to zero';
  END IF;

  SELECT COALESCE(value::numeric, 0)
  INTO v_base
  FROM system_config
  WHERE key = 'product_publication_base_cost';

  SELECT COALESCE(value::numeric, 0)
  INTO v_stock_unit
  FROM system_config
  WHERE key = 'product_publication_stock_unit_cost';

  SELECT COALESCE(value::numeric, 0)
  INTO v_price_rate
  FROM system_config
  WHERE key = 'product_publication_price_rate';

  RETURN CEIL(v_base + (p_stock * v_stock_unit) + (GREATEST(COALESCE(p_unit_price, 0), 0) * p_stock * v_price_rate))::int;
END;
$$;

CREATE OR REPLACE FUNCTION create_product_publication_with_charge(
  p_user_id uuid,
  p_product_id bigint,
  p_published_stock int
)
RETURNS product_publications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_product products%ROWTYPE;
  v_business businesses%ROWTYPE;
  v_cost int;
  v_publication product_publications;
BEGIN
  SELECT *
  INTO v_product
  FROM products
  WHERE id = p_product_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Product not found';
  END IF;

  IF COALESCE(v_product.stock, 0) < p_published_stock THEN
    RAISE EXCEPTION 'Published stock exceeds available stock';
  END IF;

  SELECT *
  INTO v_business
  FROM businesses
  WHERE id = v_product.business_id;

  IF NOT FOUND OR v_business.owner_id <> p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM product_publications
    WHERE product_id = p_product_id
      AND status <> 'archived'
  ) THEN
    RAISE EXCEPTION 'Product already has an open publication';
  END IF;

  v_cost := calculate_product_publication_cost(
    p_published_stock,
    COALESCE(v_product.price, 0)
  );

  IF v_cost > 0 THEN
    PERFORM perform_tinku_spend(
      p_user_id,
      v_cost,
      'product_publication',
      p_product_id,
      'Product marketplace publication'
    );
  END IF;

  INSERT INTO product_publications (
    product_id,
    business_id,
    created_by,
    published_stock,
    unit_price,
    unit_tinku_price,
    calculated_cost_tinkus,
    charged_tinkus,
    status
  )
  VALUES (
    v_product.id,
    v_product.business_id,
    p_user_id,
    p_published_stock,
    v_product.price,
    v_product.tinku_price,
    v_cost,
    v_cost,
    CASE WHEN p_published_stock = 0 THEN 'draft'::marketplace_publication_status ELSE 'active'::marketplace_publication_status END
  )
  RETURNING * INTO v_publication;

  INSERT INTO product_publication_history (
    publication_id,
    changed_by,
    previous_stock,
    new_stock,
    previous_cost_tinkus,
    new_cost_tinkus,
    additional_charged_tinkus,
    reason
  )
  VALUES (
    v_publication.id,
    p_user_id,
    NULL,
    p_published_stock,
    NULL,
    v_cost,
    v_cost,
    'initial_publication'
  );

  RETURN v_publication;
END;
$$;

CREATE OR REPLACE FUNCTION update_product_publication_with_charge(
  p_user_id uuid,
  p_publication_id bigint,
  p_published_stock int
)
RETURNS product_publications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_publication product_publications%ROWTYPE;
  v_product products%ROWTYPE;
  v_business businesses%ROWTYPE;
  v_new_cost int;
  v_additional int;
BEGIN
  SELECT *
  INTO v_publication
  FROM product_publications
  WHERE id = p_publication_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Product publication not found';
  END IF;

  SELECT *
  INTO v_product
  FROM products
  WHERE id = v_publication.product_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Product not found';
  END IF;

  IF COALESCE(v_product.stock, 0) < p_published_stock THEN
    RAISE EXCEPTION 'Published stock exceeds available stock';
  END IF;

  SELECT *
  INTO v_business
  FROM businesses
  WHERE id = v_publication.business_id;

  IF NOT FOUND OR v_business.owner_id <> p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  v_new_cost := calculate_product_publication_cost(
    p_published_stock,
    COALESCE(v_product.price, 0)
  );

  v_additional := GREATEST(v_new_cost - v_publication.charged_tinkus, 0);

  IF v_additional > 0 THEN
    PERFORM perform_tinku_spend(
      p_user_id,
      v_additional,
      'product_publication_update',
      p_publication_id,
      'Product marketplace publication update'
    );
  END IF;

  INSERT INTO product_publication_history (
    publication_id,
    changed_by,
    previous_stock,
    new_stock,
    previous_cost_tinkus,
    new_cost_tinkus,
    additional_charged_tinkus,
    reason
  )
  VALUES (
    v_publication.id,
    p_user_id,
    v_publication.published_stock,
    p_published_stock,
    v_publication.calculated_cost_tinkus,
    v_new_cost,
    v_additional,
    'publication_update'
  );

  UPDATE product_publications
  SET
    published_stock = p_published_stock,
    unit_price = v_product.price,
    unit_tinku_price = v_product.tinku_price,
    calculated_cost_tinkus = v_new_cost,
    charged_tinkus = charged_tinkus + v_additional,
    status = CASE
      WHEN p_published_stock = 0 THEN 'sold_out'::marketplace_publication_status
      WHEN status = 'sold_out' THEN 'active'::marketplace_publication_status
      ELSE status
    END,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = v_publication.id
  RETURNING * INTO v_publication;

  RETURN v_publication;
END;
$$;

CREATE OR REPLACE FUNCTION reward_warehouse_delivery(
  p_delivery_id bigint
)
RETURNS deliveries
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_delivery deliveries%ROWTYPE;
  v_warehouse warehouses%ROWTYPE;
  v_reward int := 0;
  v_tx_id bigint;
BEGIN
  SELECT *
  INTO v_delivery
  FROM deliveries
  WHERE id = p_delivery_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Delivery not found';
  END IF;

  IF v_delivery.status <> 'delivered' THEN
    RAISE EXCEPTION 'Delivery is not completed';
  END IF;

  IF v_delivery.reward_transaction_id IS NOT NULL THEN
    RETURN v_delivery;
  END IF;

  SELECT *
  INTO v_warehouse
  FROM warehouses
  WHERE id = v_delivery.warehouse_id;

  IF NOT FOUND OR v_warehouse.owner_id IS NULL THEN
    RAISE EXCEPTION 'Warehouse owner not found';
  END IF;

  SELECT COALESCE(value::int, 0)
  INTO v_reward
  FROM system_config
  WHERE key = 'warehouse_delivery_reward_tinkus';

  IF v_reward <= 0 THEN
    RETURN v_delivery;
  END IF;

  UPDATE wallets
  SET balance = balance + v_reward,
      updated_at = CURRENT_TIMESTAMP
  WHERE user_id = v_warehouse.owner_id;

  INSERT INTO financial_transactions (
    user_id,
    type,
    amount,
    currency,
    purpose,
    reference_id,
    status,
    description,
    created_at
  )
  VALUES (
    v_warehouse.owner_id,
    'reward',
    v_reward,
    'TINKU',
    'warehouse_delivery',
    v_delivery.id,
    'approved',
    'Warehouse delivery reward',
    CURRENT_TIMESTAMP
  )
  RETURNING id INTO v_tx_id;

  UPDATE deliveries
  SET
    reward_tinkus = v_reward,
    reward_transaction_id = v_tx_id,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = v_delivery.id
  RETURNING * INTO v_delivery;

  RETURN v_delivery;
END;
$$;

CREATE OR REPLACE FUNCTION register_business_view(
  p_business_id bigint
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM businesses
    WHERE id = p_business_id
      AND status = 'active'
  ) THEN
    RETURN;
  END IF;

  INSERT INTO business_view_daily (business_id, day, views_count, updated_at)
  VALUES (p_business_id, CURRENT_DATE, 1, CURRENT_TIMESTAMP)
  ON CONFLICT (business_id, day)
  DO UPDATE SET
    views_count = business_view_daily.views_count + 1,
    updated_at = CURRENT_TIMESTAMP;

  INSERT INTO business_view_totals (business_id, total_views, last_viewed_at, updated_at)
  VALUES (p_business_id, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
  ON CONFLICT (business_id)
  DO UPDATE SET
    total_views = business_view_totals.total_views + 1,
    last_viewed_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP;
END;
$$;

ALTER FUNCTION calculate_product_publication_cost(int, numeric) OWNER TO postgres;
ALTER FUNCTION create_product_publication_with_charge(uuid, bigint, int) OWNER TO postgres;
ALTER FUNCTION update_product_publication_with_charge(uuid, bigint, int) OWNER TO postgres;
ALTER FUNCTION reward_warehouse_delivery(bigint) OWNER TO postgres;
ALTER FUNCTION register_business_view(bigint) OWNER TO postgres;

GRANT EXECUTE ON FUNCTION calculate_product_publication_cost(int, numeric) TO PUBLIC;
GRANT EXECUTE ON FUNCTION create_product_publication_with_charge(uuid, bigint, int) TO PUBLIC;
GRANT EXECUTE ON FUNCTION update_product_publication_with_charge(uuid, bigint, int) TO PUBLIC;
GRANT EXECUTE ON FUNCTION reward_warehouse_delivery(bigint) TO PUBLIC;
GRANT EXECUTE ON FUNCTION register_business_view(bigint) TO PUBLIC;

COMMIT;
