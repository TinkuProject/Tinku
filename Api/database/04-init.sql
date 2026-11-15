-- =========================
-- INIT POSTGRES LOCAL / SERVER
-- =========================
--
-- Tinku ya no expone la base directamente al cliente como Supabase/PostgREST.
-- La seguridad se aplica en la API mediante JWT, middlewares de rol y servicios.
--
-- Este archivo queda en la secuencia de creacion para mantener el orden 01-05,
-- pero no crea politicas RLS dependientes de auth.uid(), auth.jwt() ni roles
-- internos de Supabase.
--
-- En el futuro, si se decide usar RLS en PostgreSQL propio, las politicas deben
-- basarse en current_setting('app.user_id', true) y current_setting('app.user_role', true),
-- seteados desde la API dentro de cada transaccion.

SELECT 'API-managed security initialized' AS status;

-- =========================
-- BASELINE CATALOG / CONFIG
-- =========================
--
-- Datos mínimos para que una base creada desde cero pueda operar sin depender
-- de inserts manuales posteriores. Mantener idempotente con ON CONFLICT.

INSERT INTO system_config (key, value, description)
VALUES
  ('upgrade_to_partner', '100', 'Costo en Tinkus para solicitar rol socio'),
  ('business_create_cost', '25', 'Costo en Tinkus para crear un negocio'),
  ('event_create_cost', '15', 'Costo en Tinkus para crear un evento'),
  ('discount_create_cost', '10', 'Costo en Tinkus para crear una promocion'),
  ('boost_create_cost', '20', 'Costo en Tinkus para crear un impulso'),
  ('product_publication_base_cost', '5', 'Costo base en Tinkus para publicar un producto en marketplace'),
  ('product_publication_stock_unit_cost', '1', 'Costo en Tinkus por unidad de stock publicada'),
  ('product_publication_price_rate', '0.02', 'Multiplicador del precio para calcular costo de publicacion'),
  ('marketplace_service_fee_rate', '0.10', 'Incremento aplicado al precio mostrado en marketplace'),
  ('marketplace_pickup_expiration_days', '7', 'Días disponibles para retirar un pedido una vez que está listo'),
  ('warehouse_delivery_reward_tinkus', '3', 'Recompensa fallback en Tinkus para almacenes por entrega realizada'),
  ('warehouse_delivery_reward_small', '1', 'Recompensa en Tinkus para almacenes por producto pequeno'),
  ('warehouse_delivery_reward_medium', '2', 'Recompensa en Tinkus para almacenes por producto mediano'),
  ('warehouse_delivery_reward_large', '3', 'Recompensa en Tinkus para almacenes por producto grande')
ON CONFLICT (key)
DO UPDATE SET
  value = EXCLUDED.value,
  description = EXCLUDED.description,
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO coin_packages (name, tinkus_amount, cash_amount, status)
VALUES
  ('partner_upgrade', 100, 20.00, 'active'),
  ('Basico', 100, 10.00, 'active'),
  ('Emprendedor', 300, 25.00, 'active'),
  ('Impulso', 700, 50.00, 'active')
ON CONFLICT (name)
DO UPDATE SET
  tinkus_amount = EXCLUDED.tinkus_amount,
  cash_amount = EXCLUDED.cash_amount,
  status = EXCLUDED.status,
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO cashout_packages (name, tinkus_amount, cash_amount, status)
VALUES
  ('Retiro pequeno', 500, 25.00, 'active'),
  ('Retiro medio', 1200, 60.00, 'active'),
  ('Retiro grande', 2500, 125.00, 'active')
ON CONFLICT (name)
DO UPDATE SET
  tinkus_amount = EXCLUDED.tinkus_amount,
  cash_amount = EXCLUDED.cash_amount,
  status = EXCLUDED.status,
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO subscription_plans (name, price, currency, duration_months, included_tinku, status)
VALUES
  ('Socio Mensual', 49.00, 'BOB', 1, 100, 'active'),
  ('Socio Trimestral', 129.00, 'BOB', 3, 350, 'active')
ON CONFLICT (name)
DO UPDATE SET
  price = EXCLUDED.price,
  currency = EXCLUDED.currency,
  duration_months = EXCLUDED.duration_months,
  included_tinku = EXCLUDED.included_tinku,
  status = EXCLUDED.status,
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO vehicle_types (name)
VALUES
  ('Bus'),
  ('Micro'),
  ('Trufi'),
  ('Taxi trufi')
ON CONFLICT (name) DO NOTHING;

INSERT INTO categories (name, entity_type, business_type, status)
VALUES
  ('Gastronomia', 'business', 'business', 'active'),
  ('Comercio', 'business', 'business', 'active'),
  ('Salud y bienestar', 'business', 'service', 'active'),
  ('Servicios profesionales', 'business', 'service', 'active'),
  ('Cultura', 'event', NULL, 'active'),
  ('Entretenimiento', 'event', NULL, 'active'),
  ('Capacitacion', 'event', NULL, 'active'),
  ('Naturaleza', 'tourist_place', NULL, 'active'),
  ('Patrimonio', 'tourist_place', NULL, 'active'),
  ('Artesania', 'product', NULL, 'active'),
  ('Alimentos', 'product', NULL, 'active')
ON CONFLICT (name)
DO UPDATE SET
  entity_type = EXCLUDED.entity_type,
  business_type = EXCLUDED.business_type,
  status = EXCLUDED.status,
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO tags (name, description, status)
VALUES
  ('Familiar', 'Apto para visitar en familia', 'active'),
  ('Cultural', 'Relacionado con cultura local', 'active'),
  ('Naturaleza', 'Relacionado con espacios naturales', 'active'),
  ('Accesible', 'Cuenta con acceso o facilidades relevantes', 'active')
ON CONFLICT (name)
DO UPDATE SET
  description = EXCLUDED.description,
  status = EXCLUDED.status,
  updated_at = CURRENT_TIMESTAMP;
