-- Esto borra todo
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

-- Extensión para UUIDs
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============= ENUMS =============
CREATE TYPE user_role AS ENUM ('user', 'partner', 'admin', 'master');
CREATE TYPE transaction_type AS ENUM ('purchase', 'spend', 'reward', 'refund', 'cashout', 'admin_adjustment');
CREATE TYPE transaction_status AS ENUM ('pending', 'approved', 'rejected', 'failed', 'cancelled', 'reversed');
CREATE TYPE payment_method AS ENUM ('qr', 'gateway', 'cash_point');
CREATE TYPE payment_status AS ENUM ('pending', 'approved', 'rejected', 'failed', 'cancelled', 'expired');
CREATE TYPE payment_type AS ENUM ('partner_upgrade', 'coin_purchase', 'subscription', 'product_publication', 'marketplace_order');
CREATE TYPE approval_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE business_type AS ENUM ('business', 'service');
CREATE TYPE event_status AS ENUM ('pending', 'active', 'finished', 'cancelled');
CREATE TYPE promotion_status AS ENUM ('active', 'inactive', 'cancelled');
CREATE TYPE visit_type AS ENUM ('visited', 'favorited');
CREATE TYPE reservation_status AS ENUM ('pending', 'confirmed', 'cancelled');
CREATE TYPE event_ticket_status AS ENUM ('active', 'used', 'expired', 'cancelled');
CREATE TYPE media_type AS ENUM ('image', 'video', 'file');
CREATE TYPE media_entity_type AS ENUM ('business', 'event', 'tourist_place', 'product', 'user', 'review', 
'certification', 'category', 'payment', 'coin_package', 'subscription', 'discount', 'transport_line', 'charging_point', 'warehouse', 'product_publication');
CREATE TYPE route_direction AS ENUM ('outbound', 'return');
CREATE TYPE subscription_status AS ENUM ('active', 'paused', 'cancelled', 'expired');
CREATE TYPE visit_entity AS ENUM ('tourist_place','business','event');
CREATE TYPE review_entity_type AS ENUM ('tourist_place','business','event', 'product');
CREATE TYPE opening_entity AS ENUM ('business', 'event', 'tourist_place', 'charging_point');
CREATE TYPE week_day AS ENUM ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday');
CREATE TYPE user_status AS ENUM ('active', 'inactive', 'suspended', 'deleted');
CREATE TYPE business_status AS ENUM ('active', 'inactive', 'suspended', 'pending');
CREATE TYPE product_status AS ENUM ('active', 'inactive', 'out_of_stock');
CREATE TYPE review_status AS ENUM ('visible', 'hidden', 'reported');
CREATE TYPE basic_status AS ENUM ('active', 'inactive', 'archived');
CREATE TYPE charging_point_status AS ENUM ('active', 'inactive', 'maintenance');
CREATE TYPE category_entity_type AS ENUM ('business', 'event', 'tourist_place', 'product');
CREATE TYPE update_entity_type AS ENUM ('business', 'event', 'product', 'certification');
CREATE TYPE warehouse_status AS ENUM ('pending', 'active', 'inactive', 'archived');
CREATE TYPE warehouse_inventory_status AS ENUM ('available', 'reserved', 'delivered', 'returned', 'cancelled');
CREATE TYPE warehouse_stock_request_status AS ENUM ('pending', 'approved', 'sent', 'received', 'rejected', 'cancelled');
CREATE TYPE marketplace_publication_status AS ENUM ('draft', 'active', 'paused', 'sold_out', 'archived');
CREATE TYPE marketplace_order_status AS ENUM ('pending', 'paid', 'preparing', 'ready_for_pickup', 'in_delivery', 'delivered', 'cancelled');
CREATE TYPE delivery_status AS ENUM ('pending', 'assigned', 'picked_up', 'delivered', 'cancelled');
CREATE TYPE fulfillment_method AS ENUM ('pickup', 'warehouse_delivery');
-- =========================
-- ACCESO
-- =========================

CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name varchar(100),
  last_name varchar(100),
  username varchar(100) UNIQUE NOT NULL,
  email varchar(150) UNIQUE NOT NULL,
  password_hash text,
  google_sub text UNIQUE,
  email_verified boolean NOT NULL DEFAULT false,
  phone varchar(20),
  ci varchar(50),
  address varchar(250),
  location geography(Point, 4326),
  role user_role NOT NULL DEFAULT 'user',
  status user_status NOT NULL DEFAULT 'active',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE permissions (
  id bigserial PRIMARY KEY,
  code varchar(100) UNIQUE NOT NULL,
  description text,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE role_permissions (
  role user_role NOT NULL,
  permission_id bigint NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role, permission_id)
);

CREATE TABLE labels (
  id bigserial PRIMARY KEY,
  code varchar(100) UNIQUE NOT NULL,
  description text,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE label_permissions (
  label_id bigint NOT NULL REFERENCES labels(id) ON DELETE CASCADE,
  permission_id bigint NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (label_id, permission_id)
);

CREATE TABLE user_labels (
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  label_id bigint NOT NULL REFERENCES labels(id) ON DELETE CASCADE,
  assigned_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, label_id)
);

INSERT INTO permissions (code, description) VALUES
  ('account.access', 'Acceso autenticado a funciones de cuenta'),
  ('partner.access', 'Acceso exclusivo a funciones del rol socio'),
  ('payment_request.create', 'Crear y consultar solicitudes de pago propias'),
  ('owned_content.manage', 'Gestionar contenido y recursos propios'),
  ('administration.manage', 'Gestionar moderación y administración general'),
  ('authorization.manage', 'Gestionar permisos y autorización')
ON CONFLICT (code) DO NOTHING;

INSERT INTO role_permissions (role, permission_id)
SELECT grants.role::user_role, p.id
FROM (
  VALUES
    ('user', 'account.access'),
    ('user', 'payment_request.create'),
    ('partner', 'account.access'),
    ('partner', 'partner.access'),
    ('partner', 'payment_request.create'),
    ('partner', 'owned_content.manage'),
    ('admin', 'account.access'),
    ('admin', 'owned_content.manage'),
    ('admin', 'administration.manage'),
    ('master', 'account.access'),
    ('master', 'owned_content.manage'),
    ('master', 'administration.manage'),
    ('master', 'authorization.manage')
) AS grants(role, permission_code)
JOIN permissions p ON p.code = grants.permission_code
ON CONFLICT (role, permission_id) DO NOTHING;

CREATE TABLE auth_verification_codes (
  id bigserial PRIMARY KEY,
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  email varchar(150) NOT NULL,
  purpose text NOT NULL CHECK (purpose IN ('email_verification', 'password_recovery', 'email_change')),
  code_hash text NOT NULL,
  expires_at timestamp NOT NULL,
  attempt_count int NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  max_attempts int NOT NULL DEFAULT 5 CHECK (max_attempts > 0),
  requested_ip varchar(64),
  consumed_at timestamp NULL,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_refresh_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash text UNIQUE NOT NULL,
  expires_at timestamp NOT NULL,
  revoked_at timestamp NULL,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- ECONOMÍA
-- =========================

CREATE TABLE wallets (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  balance int NOT NULL DEFAULT 0 CHECK (balance >= 0),

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE payments (
  id bigserial PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  method payment_method NOT NULL,
  status payment_status NOT NULL DEFAULT 'pending',
  amount decimal(10,2) NOT NULL,
  amount_minor bigint NULL,
  currency_minor_unit smallint NULL,
  currency text NOT NULL DEFAULT 'BOB',
  external_reference text, -- id del gateway / QR
  stripe_client_request_id text NULL,
  gateway_target_id bigint NULL,
  type payment_type,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE financial_transactions (
  id bigserial PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  type transaction_type NOT NULL,
  status transaction_status NOT NULL DEFAULT 'pending',
  amount int NOT NULL CHECK (amount > 0),
  currency text NOT NULL DEFAULT 'TINKU',
  -- contexto (NO enum)
  purpose text,
  reference_id bigint,
  -- relación con pagos externos
  payment_id bigint REFERENCES payments(id),
  -- metadata
  description text,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE coin_packages (
  id bigserial PRIMARY KEY,
  name varchar(50) UNIQUE NOT NULL,
  tinkus_amount int NOT NULL,
  cash_amount decimal(10,2) NOT NULL,
  status basic_status DEFAULT 'active',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE cashout_packages (
  id bigserial PRIMARY KEY,
  name varchar(50) UNIQUE NOT NULL,
  tinkus_amount int NOT NULL,
  cash_amount decimal(10,2) NOT NULL,
  status basic_status DEFAULT 'active',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE cashout_requests (
  id bigserial PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  cashout_package_id bigint NOT NULL REFERENCES cashout_packages(id),
  status approval_status NOT NULL DEFAULT 'pending',
  tinkus_amount int NOT NULL CHECK (tinkus_amount > 0),
  cash_amount decimal(10,2) NOT NULL CHECK (cash_amount > 0),
  comment text,
  reviewed_by uuid REFERENCES users(id),
  reviewed_at timestamp,
  transaction_id bigint REFERENCES financial_transactions(id),

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE system_config (
  key varchar(100) PRIMARY KEY,
  value text NOT NULL,
  description text,

  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit_logs (
  id bigserial PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),
  action varchar(100) NOT NULL,
  entity_type text,
  entity_id bigint,
  details jsonb,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- NEGOCIOS
-- =========================

CREATE TABLE categories (
  id bigserial PRIMARY KEY,
  name varchar(100) UNIQUE NOT NULL,
  entity_type category_entity_type NOT NULL,
  business_type business_type, -- solo aplica para negocios, puede ser null para eventos o lugares turísticos
  status basic_status NOT NULL DEFAULT 'active',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE businesses (
  id bigserial PRIMARY KEY,
  category_id bigint NOT NULL REFERENCES categories(id),
  owner_id uuid REFERENCES users(id), -- puede ser null inicialmente
  name varchar(150) NOT NULL,
  nit varchar(20),
  description text,
  phone varchar(20),
  email varchar(100),
  business_type business_type NOT NULL,
  address varchar(250) NOT NULL,
  location geography(Point, 4326) NOT NULL,
  website varchar(150),
  validated boolean DEFAULT false, -- validación administrativa
  status business_status NOT NULL DEFAULT 'active',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE entity_updates (
  id bigserial PRIMARY KEY,
  entity_type update_entity_type NOT NULL,
  entity_id bigint NOT NULL,
  creator_id uuid NOT NULL REFERENCES users(id),
  data jsonb NOT NULL,
  status approval_status NOT NULL DEFAULT 'pending',
  comment text,
  reviewed_by uuid REFERENCES users(id),
  reviewed_at timestamp,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE business_claim_requests (
  id bigserial PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id),
  status approval_status NOT NULL DEFAULT 'pending',
  comment text,
  documents text[] DEFAULT '{}',
  reviewed_by uuid REFERENCES users(id),
  reviewed_at timestamp,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

-- =========================
-- CONTENIDO
-- =========================

CREATE TABLE products (
  id bigserial PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  category_id bigint NOT NULL REFERENCES categories(id),
  name varchar(150) NOT NULL,
  description text,
  price decimal(10,2), -- puede ser dinero real
  tinku_price int,     -- o en Tinkus
  stock int,
  volume_tier varchar(20) NOT NULL DEFAULT 'small',
  status product_status NOT NULL DEFAULT 'active',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL,

  CHECK (volume_tier IN ('small', 'medium', 'large'))
);

CREATE TABLE warehouses (
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

CREATE TABLE business_fulfillment_options (
  business_id bigint PRIMARY KEY REFERENCES businesses(id) ON DELETE CASCADE,
  pickup_in_store boolean NOT NULL DEFAULT false,
  warehouse_delivery boolean NOT NULL DEFAULT false,
  notes text,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE business_warehouses (
  business_id bigint NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  warehouse_id bigint NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
  status basic_status NOT NULL DEFAULT 'active',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL,

  PRIMARY KEY (business_id, warehouse_id)
);

CREATE TABLE warehouse_locations (
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

CREATE TABLE warehouse_inventory (
  id bigserial PRIMARY KEY,
  warehouse_id bigint NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
  product_id bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  location_id bigint REFERENCES warehouse_locations(id) ON DELETE SET NULL,
  quantity int NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  reserved_quantity int NOT NULL DEFAULT 0 CHECK (reserved_quantity >= 0),
  status warehouse_inventory_status NOT NULL DEFAULT 'available',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL,

  UNIQUE (warehouse_id, product_id),
  CHECK (reserved_quantity <= quantity)
);

CREATE TABLE warehouse_stock_requests (
  id bigserial PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  warehouse_id bigint NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
  product_id bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  requested_by uuid NOT NULL REFERENCES users(id),
  processed_by uuid REFERENCES users(id),
  received_by uuid REFERENCES users(id),
  quantity int NOT NULL CHECK (quantity > 0),
  status warehouse_stock_request_status NOT NULL DEFAULT 'pending',
  location_id bigint REFERENCES warehouse_locations(id) ON DELETE SET NULL,
  notes text,
  response_message text,
  processed_at timestamp NULL,
  sent_at timestamp NULL,
  received_at timestamp NULL,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE warehouse_product_history (
  id bigserial PRIMARY KEY,
  warehouse_id bigint NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
  product_id bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  changed_by uuid REFERENCES users(id),
  previous_quantity int,
  new_quantity int NOT NULL CHECK (new_quantity >= 0),
  reason text,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE product_publications (
  id bigserial PRIMARY KEY,
  product_id bigint NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  business_id bigint NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  created_by uuid NOT NULL REFERENCES users(id),
  published_stock int NOT NULL CHECK (published_stock >= 0),
  unit_price decimal(10,2),
  unit_tinku_price int,
  payment_mode varchar(20) NOT NULL DEFAULT 'tinkus',
  calculated_cost_tinkus int NOT NULL DEFAULT 0 CHECK (calculated_cost_tinkus >= 0),
  charged_tinkus int NOT NULL DEFAULT 0 CHECK (charged_tinkus >= 0),
  status marketplace_publication_status NOT NULL DEFAULT 'active',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL,

  CHECK (payment_mode = 'tinkus'),
  CHECK (
    unit_price IS NULL
    AND unit_tinku_price IS NOT NULL
    AND unit_tinku_price > 0
  )
);

CREATE TABLE product_publication_history (
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

CREATE TABLE marketplace_orders (
  client_request_id uuid NULL,
  request_hash text NULL,
  id bigserial PRIMARY KEY,
  buyer_id uuid NOT NULL REFERENCES users(id),
  status marketplace_order_status NOT NULL DEFAULT 'pending',
  payment_method varchar(20) NOT NULL DEFAULT 'tinkus',
  payment_id bigint REFERENCES payments(id),
  payment_transaction_id bigint REFERENCES financial_transactions(id),
  seller_id uuid REFERENCES users(id),
  seller_amount_tinkus int NOT NULL DEFAULT 0 CHECK (seller_amount_tinkus >= 0),
  seller_payout_transaction_id bigint REFERENCES financial_transactions(id),
  settled_at timestamp NULL,
  pickup_code varchar(20) UNIQUE,
  total_amount decimal(10,2) NOT NULL DEFAULT 0,
  total_tinkus int NOT NULL DEFAULT 0,
  warehouse_delivery_fee_tinkus int NOT NULL DEFAULT 0 CHECK (warehouse_delivery_fee_tinkus >= 0),
  fulfillment fulfillment_method NOT NULL DEFAULT 'pickup',
  pickup_business_id bigint REFERENCES businesses(id),
  warehouse_id bigint REFERENCES warehouses(id),
  delivery_address varchar(250),
  delivery_location geography(Point, 4326),
  pickup_expires_at timestamp NULL,
  cancellation_reason varchar(500),
  cancelled_by uuid REFERENCES users(id),
  cancelled_at timestamp NULL,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
  ,
  CHECK (payment_method = 'tinkus')
);

CREATE TABLE marketplace_order_items (
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
  warehouse_reward_tinkus int NOT NULL DEFAULT 0 CHECK (warehouse_reward_tinkus >= 0),

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE marketplace_order_incidents (
  id bigserial PRIMARY KEY,
  order_id bigint NOT NULL REFERENCES marketplace_orders(id) ON DELETE CASCADE,
  created_by uuid NOT NULL REFERENCES users(id),
  type varchar(40) NOT NULL,
  reason varchar(500) NOT NULL,
  status varchar(20) NOT NULL DEFAULT 'resolved',
  resolved_at timestamp NULL,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL,
  CHECK (type IN ('buyer_cancelled', 'seller_rejected', 'admin_cancelled', 'not_collected')),
  CHECK (status IN ('open', 'resolved'))
);

CREATE TABLE deliveries (
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

CREATE TABLE business_view_daily (
  business_id bigint NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  day date NOT NULL,
  views_count int NOT NULL DEFAULT 0 CHECK (views_count >= 0),

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL,

  PRIMARY KEY (business_id, day)
);

CREATE TABLE business_view_totals (
  business_id bigint PRIMARY KEY REFERENCES businesses(id) ON DELETE CASCADE,
  total_views bigint NOT NULL DEFAULT 0 CHECK (total_views >= 0),
  last_viewed_at timestamp NULL,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE events (
  id bigserial PRIMARY KEY,
  business_id bigint REFERENCES businesses(id),
  creator_id uuid NOT NULL REFERENCES users(id),
  category_id bigint NOT NULL REFERENCES categories(id),
  name varchar(150) NOT NULL,
  description text,
  start_date timestamp NOT NULL,
  end_date timestamp NOT NULL,
  capacity int,
  attendees_count int DEFAULT 0,
  tinku_price int DEFAULT 0,
  address varchar(250) NOT NULL,
  location geography(Point, 4326) NOT NULL,
  status event_status DEFAULT 'pending',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE discounts (
  id bigserial PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  description text,
  discount_percent decimal(5,2) NOT NULL,
  start_date timestamp NOT NULL,
  end_date timestamp NOT NULL,
  status promotion_status DEFAULT 'active',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE boosts (
  paid_days int NULL CHECK (paid_days > 0),
  id bigserial PRIMARY KEY,
  entity_type visit_entity NOT NULL,
  entity_id bigint NOT NULL,
  start_date timestamp NOT NULL,
  end_date timestamp NOT NULL,
  status promotion_status DEFAULT 'active',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

-- =========================
-- INTERACCIÓN
-- =========================

CREATE TABLE user_visits (
  id bigserial PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  entity_type visit_entity NOT NULL,
  entity_id bigint NOT NULL,
  type visit_type NOT NULL, -- visited / favorited

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reviews (
  id bigserial PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  entity_type review_entity_type NOT NULL,
  entity_id bigint NOT NULL,
  rating smallint NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment text,
  owner_reply text,
  owner_reply_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  owner_reply_at timestamp,
  status review_status NOT NULL DEFAULT 'visible',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE reservations (
  payee_id uuid NULL REFERENCES users(id),
  id bigserial PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_id bigint NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  quantity int NOT NULL DEFAULT 1,
  tinku_amount int NOT NULL,
  status reservation_status NOT NULL DEFAULT 'pending',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE event_tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reservation_id bigint NOT NULL REFERENCES reservations(id) ON DELETE CASCADE,
  event_id bigint NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  attendee_index int NOT NULL CHECK (attendee_index > 0),
  status event_ticket_status NOT NULL DEFAULT 'active',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL,

  UNIQUE (reservation_id, attendee_index)
);

CREATE TABLE event_ticket_days (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id uuid NOT NULL REFERENCES event_tickets(id) ON DELETE CASCADE,
  event_id bigint NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  event_date date NOT NULL,
  qr_token_hash text UNIQUE,
  status event_ticket_status NOT NULL DEFAULT 'active',
  valid_from timestamp NOT NULL,
  valid_until timestamp NOT NULL,
  used_at timestamp NULL,
  used_by uuid REFERENCES users(id),

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL,

  UNIQUE (ticket_id, event_date)
);

CREATE TABLE notifications (
  id bigserial PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sender_id uuid REFERENCES users(id),
  title varchar(150),
  message text NOT NULL,
  type varchar(50),
  entity_type varchar(50),
  entity_id bigint,
  route varchar(180),
  read boolean DEFAULT false,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE notification_push_queue (
  notification_id bigint PRIMARY KEY REFERENCES notifications(id) ON DELETE CASCADE,
  attempts int NOT NULL DEFAULT 0,
  available_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  lease_until timestamptz NULL
);
CREATE INDEX idx_notification_push_due ON notification_push_queue(available_at);
CREATE UNIQUE INDEX uniq_marketplace_order_request ON marketplace_orders(buyer_id, client_request_id)
  WHERE client_request_id IS NOT NULL;

CREATE TABLE user_device_tokens (
  id bigserial PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token text NOT NULL UNIQUE,
  platform varchar(20),
  last_seen_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_device_tokens_user
  ON user_device_tokens(user_id);

-- =========================
-- TRANSPORTE
-- =========================

CREATE TABLE vehicle_types (
  id bigserial PRIMARY KEY,
  name varchar(50) UNIQUE NOT NULL
);

CREATE TABLE transport_lines (
  id bigserial PRIMARY KEY,
  vehicle_type_id bigint NOT NULL REFERENCES vehicle_types(id),
  name varchar(120) NOT NULL,
  status basic_status NOT NULL DEFAULT 'inactive',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE transport_routes (
  id bigserial PRIMARY KEY,
  transport_line_id bigint NOT NULL REFERENCES transport_lines(id) ON DELETE CASCADE,
  direction route_direction NOT NULL,
  stop_order int NOT NULL,
  location geography(Point, 4326) NOT NULL
);

CREATE TABLE entity_transport_relations (
  entity_type visit_entity NOT NULL,
  entity_id bigint NOT NULL,
  transport_line_id bigint NOT NULL REFERENCES transport_lines(id),
  -- Nullable por compatibilidad con registros existentes y clientes externos.
  -- Futuro: cuando Web y App estén alineadas, source/computed_at podrían volverse NOT NULL para relaciones automáticas.
  distance_m integer NULL,
  radius_m integer NULL,
  source varchar(20) NULL,
  computed_at timestamp NULL,
  PRIMARY KEY (entity_type, entity_id, transport_line_id)
);

-- =========================
-- TURISMO
-- =========================

CREATE TABLE tourist_places (
  id bigserial PRIMARY KEY,
  category_id bigint NOT NULL REFERENCES categories(id),
  name varchar(150) NOT NULL,
  description text,
  address varchar(250),
  location geography(Point, 4326) NOT NULL,
  created_by uuid REFERENCES users(id) ON DELETE SET NULL,
  status basic_status NOT NULL DEFAULT 'active',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE tags (
  id bigserial PRIMARY KEY,
  name varchar(80) UNIQUE NOT NULL,
  description text,
  status basic_status NOT NULL DEFAULT 'active',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE tourist_place_tags (
  tourist_place_id bigint NOT NULL REFERENCES tourist_places(id) ON DELETE CASCADE,
  tag_id bigint NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (tourist_place_id, tag_id)
);

-- =========================
-- MONETIZACIÓN
-- =========================

CREATE TABLE subscription_plans (
  id bigserial PRIMARY KEY,
  name varchar(50) UNIQUE NOT NULL,
  price decimal(10,2) NOT NULL DEFAULT 0,
  currency text NOT NULL DEFAULT 'BOB',
  duration_months int NOT NULL DEFAULT 1,
  included_tinku int NOT NULL DEFAULT 0,
  status basic_status DEFAULT 'active',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE user_subscriptions (
  id bigserial PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_id bigint NOT NULL REFERENCES subscription_plans(id),
  start_date timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  end_date timestamp,
  status subscription_status NOT NULL DEFAULT 'active',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE payment_requests (
  id bigserial PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  payment_id bigint NOT NULL REFERENCES payments(id),
  type payment_type NOT NULL,
  target_id bigint NULL, -- coin_package_id o subscription_plan_id

  status approval_status NOT NULL DEFAULT 'pending',
  comment text,

  reviewed_by uuid REFERENCES users(id),
  reviewed_at timestamp,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL,

  -- VALIDACIÓN DE COHERENCIA
  CONSTRAINT check_target_required
  CHECK (
    (type = 'partner_upgrade' AND target_id IS NULL)
    OR
    (type IN ('coin_purchase', 'subscription', 'marketplace_order') AND target_id IS NOT NULL)
  )
);

CREATE TABLE stripe_webhook_events (
  id text PRIMARY KEY,
  type text NOT NULL,
  processed_at timestamp NULL,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- SOPORTE / METADATA
-- =========================

CREATE TABLE social_links (
  id bigserial PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  platform text NOT NULL, -- antes enum, ahora flexible
  url text NOT NULL,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE opening_hours (
  id bigserial PRIMARY KEY,
  entity_type opening_entity NOT NULL,
  entity_id bigint NOT NULL,
  week_day week_day NOT NULL,
  start_time time NOT NULL,
  end_time time NOT NULL,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE charging_points (
  id bigserial PRIMARY KEY,
  name varchar(150) NOT NULL,
  address varchar(250) NOT NULL,
  location geography(Point, 4326) NOT NULL,
  status charging_point_status NOT NULL DEFAULT 'active',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE charging_point_warehouses (
  charging_point_id bigint NOT NULL REFERENCES charging_points(id) ON DELETE CASCADE,
  warehouse_id bigint NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
  status basic_status NOT NULL DEFAULT 'active',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL,

  PRIMARY KEY (charging_point_id, warehouse_id)
);

CREATE TABLE certifications (
  id bigserial PRIMARY KEY,
  business_id bigint NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  name varchar(255) NOT NULL,
  -- Opcional: premios/reconocimientos pueden no tener numero formal.
  license_number varchar(100) NULL,
  status basic_status DEFAULT 'active',

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

CREATE TABLE media (
  id bigserial PRIMARY KEY,
  entity_type media_entity_type NOT NULL,
  entity_id text NOT NULL,
  url text NOT NULL,
  type media_type NOT NULL,
  description text,
  is_primary boolean DEFAULT false,
  display_order int DEFAULT 0,

  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL
);

-- =========================
-- INDEX
-- =========================
CREATE UNIQUE INDEX uniq_user_favorite
  ON user_visits(user_id, entity_type, entity_id)
  WHERE type = 'favorited';
CREATE UNIQUE INDEX uniq_user_review ON reviews(user_id, entity_type, entity_id);

CREATE UNIQUE INDEX unique_pending_claim ON business_claim_requests (user_id, business_id)
WHERE status = 'pending';

CREATE UNIQUE INDEX one_primary_media_per_entity ON media (entity_id, entity_type)
WHERE is_primary = true;

CREATE INDEX idx_transport_routes_location ON transport_routes USING GIST(location);
CREATE INDEX idx_tourist_places_location ON tourist_places USING GIST(location);
CREATE INDEX idx_user_subscriptions_user_status ON user_subscriptions(user_id, status);
CREATE INDEX idx_charging_points_location ON charging_points USING GIST(location);

CREATE INDEX idx_ft_user ON financial_transactions(user_id);
CREATE INDEX idx_ft_status ON financial_transactions(status);
CREATE INDEX idx_ft_type ON financial_transactions(type);
CREATE INDEX idx_ft_created ON financial_transactions(created_at DESC);

CREATE INDEX idx_payments_user ON payments(user_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_created ON payments(created_at DESC);
CREATE INDEX idx_payments_method_status ON payments(method, status);
CREATE UNIQUE INDEX idx_payments_stripe_client_request
ON payments(user_id, stripe_client_request_id)
WHERE stripe_client_request_id IS NOT NULL;

CREATE INDEX idx_cashout_requests_user ON cashout_requests(user_id);
CREATE INDEX idx_cashout_requests_status ON cashout_requests(status);
CREATE INDEX idx_cashout_requests_package ON cashout_requests(cashout_package_id);
CREATE INDEX idx_cashout_requests_created ON cashout_requests(created_at DESC);

CREATE UNIQUE INDEX unique_pending_cashout_request
ON cashout_requests(user_id)
WHERE status = 'pending';

CREATE INDEX idx_auth_codes_email_purpose
ON auth_verification_codes(email, purpose, consumed_at, created_at DESC);

CREATE INDEX idx_auth_codes_ip_rate
ON auth_verification_codes(requested_ip, created_at DESC)
WHERE requested_ip IS NOT NULL;

CREATE INDEX idx_refresh_tokens_user ON user_refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_hash ON user_refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_expires ON user_refresh_tokens(expires_at);

CREATE INDEX idx_business_owner ON businesses(owner_id);
CREATE INDEX idx_business_category ON businesses(category_id);
CREATE INDEX idx_products_business ON products(business_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_warehouses_owner ON warehouses(owner_id);
CREATE INDEX idx_warehouses_status ON warehouses(status);
CREATE INDEX idx_warehouses_location ON warehouses USING GIST(location);
CREATE INDEX idx_business_warehouses_warehouse ON business_warehouses(warehouse_id);
CREATE INDEX idx_charging_point_warehouses_warehouse ON charging_point_warehouses(warehouse_id);
CREATE INDEX idx_warehouse_locations_warehouse ON warehouse_locations(warehouse_id, status, sort_order);
CREATE INDEX idx_warehouse_locations_parent ON warehouse_locations(parent_id);
CREATE INDEX idx_warehouse_inventory_warehouse ON warehouse_inventory(warehouse_id);
CREATE INDEX idx_warehouse_inventory_product ON warehouse_inventory(product_id);
CREATE INDEX idx_warehouse_inventory_location ON warehouse_inventory(location_id);
CREATE INDEX idx_warehouse_stock_requests_business ON warehouse_stock_requests(business_id, status, created_at DESC);
CREATE INDEX idx_warehouse_stock_requests_warehouse ON warehouse_stock_requests(warehouse_id, status, created_at DESC);
CREATE INDEX idx_warehouse_stock_requests_product ON warehouse_stock_requests(product_id, created_at DESC);
CREATE INDEX idx_warehouse_product_history_product ON warehouse_product_history(product_id, created_at DESC);
CREATE INDEX idx_product_publications_product ON product_publications(product_id);
CREATE INDEX idx_product_publications_business_status ON product_publications(business_id, status);
CREATE INDEX idx_product_publications_created_by ON product_publications(created_by);
CREATE UNIQUE INDEX idx_product_publications_open_product ON product_publications(product_id)
WHERE status <> 'archived';
CREATE INDEX idx_product_publication_history_publication ON product_publication_history(publication_id, created_at DESC);
CREATE INDEX idx_marketplace_orders_buyer ON marketplace_orders(buyer_id, created_at DESC);
CREATE INDEX idx_marketplace_orders_payment ON marketplace_orders(payment_id);
CREATE INDEX idx_marketplace_orders_pickup_code ON marketplace_orders(pickup_code);
CREATE INDEX idx_marketplace_orders_seller ON marketplace_orders(seller_id, created_at DESC);
CREATE INDEX idx_marketplace_orders_unsettled ON marketplace_orders(status, settled_at)
WHERE settled_at IS NULL;
CREATE INDEX idx_marketplace_order_incidents_order ON marketplace_order_incidents(order_id, created_at DESC);
CREATE INDEX idx_marketplace_orders_status ON marketplace_orders(status);
CREATE INDEX idx_marketplace_orders_warehouse ON marketplace_orders(warehouse_id);
CREATE INDEX idx_marketplace_order_items_order ON marketplace_order_items(order_id);
CREATE INDEX idx_marketplace_order_items_publication ON marketplace_order_items(publication_id);
CREATE INDEX idx_businesses_name_trgm ON businesses USING gin (name gin_trgm_ops);
CREATE INDEX idx_events_name_trgm ON events USING gin (name gin_trgm_ops);
CREATE INDEX idx_tourist_places_name_trgm ON tourist_places USING gin (name gin_trgm_ops);
CREATE INDEX idx_products_name_trgm ON products USING gin (name gin_trgm_ops);
CREATE INDEX idx_products_description_trgm ON products USING gin (description gin_trgm_ops);
CREATE INDEX idx_deliveries_warehouse_status ON deliveries(warehouse_id, status);
CREATE INDEX idx_deliveries_order ON deliveries(order_id);
CREATE INDEX idx_business_view_daily_day ON business_view_daily(day DESC);

CREATE INDEX idx_events_business ON events(business_id);
CREATE INDEX idx_events_creator ON events(creator_id);
CREATE INDEX idx_events_category ON events(category_id);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_dates ON events(start_date, end_date);

CREATE UNIQUE INDEX unique_event_per_creator
ON events (creator_id, name, start_date)
WHERE status != 'cancelled';

CREATE INDEX idx_visits_user ON user_visits(user_id);
CREATE INDEX idx_visits_entity ON user_visits(entity_type, entity_id);

CREATE INDEX idx_reviews_user ON reviews(user_id);
CREATE INDEX idx_reviews_entity ON reviews(entity_type, entity_id);

CREATE INDEX idx_reservations_user ON reservations(user_id);
CREATE INDEX idx_reservations_event ON reservations(event_id);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_event_tickets_reservation ON event_tickets(reservation_id);
CREATE INDEX idx_event_tickets_event ON event_tickets(event_id);
CREATE INDEX idx_event_tickets_user ON event_tickets(user_id);
CREATE INDEX idx_event_ticket_days_ticket ON event_ticket_days(ticket_id);
CREATE INDEX idx_event_ticket_days_event_date ON event_ticket_days(event_id, event_date);
CREATE INDEX idx_event_ticket_days_status ON event_ticket_days(status);
CREATE INDEX idx_event_ticket_days_hash ON event_ticket_days(qr_token_hash);

CREATE INDEX idx_notifications_user_created ON notifications(user_id, created_at DESC);
CREATE INDEX idx_media_entity ON media(entity_type, entity_id);
CREATE INDEX idx_media_primary ON media(entity_type, entity_id, is_primary);

CREATE INDEX idx_routes_line ON transport_routes(transport_line_id);
CREATE INDEX idx_entity_transport ON entity_transport_relations(entity_type, entity_id);
CREATE INDEX idx_entity_transport_source ON entity_transport_relations(source);
CREATE INDEX idx_tourist_category ON tourist_places(category_id);
CREATE INDEX idx_user_subscriptions_user ON user_subscriptions(user_id);
CREATE INDEX idx_user_subscriptions_status ON user_subscriptions(status);

CREATE INDEX idx_audit_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_action ON audit_logs(action);
CREATE INDEX idx_audit_created_at ON audit_logs(created_at);

-- evitar múltiples solicitudes pendientes por usuario
CREATE UNIQUE INDEX unique_pending_payment_request
ON payment_requests (user_id, type)
WHERE status = 'pending';

-- consultas frecuentes
CREATE INDEX idx_payment_requests_user ON payment_requests(user_id);
CREATE INDEX idx_payment_requests_status ON payment_requests(status);
CREATE INDEX idx_payment_requests_payment ON payment_requests(payment_id);
CREATE INDEX idx_payment_requests_type ON payment_requests(type);
CREATE INDEX idx_stripe_webhook_events_created ON stripe_webhook_events(created_at DESC);

CREATE INDEX idx_businesses_status_validated_created
  ON businesses(status, validated, created_at DESC);
CREATE INDEX idx_businesses_owner_status_created
  ON businesses(owner_id, status, created_at DESC);
CREATE INDEX idx_businesses_category_status_created
  ON businesses(category_id, status, created_at DESC);
CREATE INDEX idx_events_status_start_date
  ON events(status, start_date ASC);
CREATE INDEX idx_events_creator_status_created
  ON events(creator_id, status, created_at DESC);
CREATE INDEX idx_events_business_status_start
  ON events(business_id, status, start_date ASC);
CREATE INDEX idx_events_category_status_start
  ON events(category_id, status, start_date ASC);
CREATE INDEX idx_tourist_places_status_created
  ON tourist_places(status, created_at DESC);
CREATE INDEX idx_tourist_places_category_status_created
  ON tourist_places(category_id, status, created_at DESC);
CREATE INDEX idx_media_entity_primary_created
  ON media(entity_type, entity_id, is_primary, created_at ASC);
CREATE INDEX idx_payment_requests_user_created
  ON payment_requests(user_id, created_at DESC);
CREATE INDEX idx_payment_requests_user_status_created
  ON payment_requests(user_id, status, created_at DESC);
CREATE INDEX idx_financial_transactions_user_created
  ON financial_transactions(user_id, created_at DESC);
CREATE INDEX idx_notifications_user_read_created
  ON notifications(user_id, read, created_at DESC);
-- =========================
-- ENTITY UPDATES INDEXES
-- =========================

-- búsquedas por entidad
CREATE INDEX idx_entity_updates_entity ON entity_updates(entity_type, entity_id);

-- filtro por estado (admin)
CREATE INDEX idx_entity_updates_status ON entity_updates(status);

-- updates del usuario
CREATE INDEX idx_entity_updates_creator ON entity_updates(creator_id);

-- combinación útil (admin + entity)
CREATE INDEX idx_entity_updates_entity_status ON entity_updates(entity_type, entity_id, status);

-- evitar múltiples updates pendientes por entidad
CREATE UNIQUE INDEX unique_pending_entity_update ON entity_updates(entity_type, entity_id)
WHERE status = 'pending';

-- índice espacial para búsquedas cercanas
CREATE INDEX idx_business_location ON businesses USING GIST(location);
CREATE INDEX idx_tourist_location ON tourist_places USING GIST(location);
CREATE INDEX idx_event_location ON events USING GIST(location);
