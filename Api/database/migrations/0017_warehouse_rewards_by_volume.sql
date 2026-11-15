-- Recompensas de almacenes por volumen de producto.
-- El cliente paga el cargo logistico al comprar; el almacen lo cobra al completar la entrega.

INSERT INTO system_config (key, value, description)
VALUES
  ('warehouse_delivery_reward_small', '1', 'Recompensa en Tinkus para almacenes por producto pequeno'),
  ('warehouse_delivery_reward_medium', '2', 'Recompensa en Tinkus para almacenes por producto mediano'),
  ('warehouse_delivery_reward_large', '3', 'Recompensa en Tinkus para almacenes por producto grande')
ON CONFLICT (key)
DO UPDATE SET
  value = EXCLUDED.value,
  description = EXCLUDED.description,
  updated_at = CURRENT_TIMESTAMP;

ALTER TABLE products
  ADD COLUMN IF NOT EXISTS volume_tier varchar(20) DEFAULT 'small';

UPDATE products
SET volume_tier = 'small'
WHERE volume_tier IS NULL
   OR volume_tier NOT IN ('small', 'medium', 'large');

ALTER TABLE products
  DROP CONSTRAINT IF EXISTS products_volume_tier_check;

ALTER TABLE products
  ADD CONSTRAINT products_volume_tier_check
  CHECK (volume_tier IS NULL OR volume_tier IN ('small', 'medium', 'large'));

ALTER TABLE marketplace_orders
  ADD COLUMN IF NOT EXISTS warehouse_delivery_fee_tinkus int NOT NULL DEFAULT 0;

ALTER TABLE marketplace_orders
  DROP CONSTRAINT IF EXISTS marketplace_orders_warehouse_delivery_fee_check;

ALTER TABLE marketplace_orders
  ADD CONSTRAINT marketplace_orders_warehouse_delivery_fee_check
  CHECK (warehouse_delivery_fee_tinkus >= 0);

ALTER TABLE marketplace_order_items
  ADD COLUMN IF NOT EXISTS warehouse_reward_tinkus int NOT NULL DEFAULT 0;

ALTER TABLE marketplace_order_items
  DROP CONSTRAINT IF EXISTS marketplace_order_items_warehouse_reward_check;

ALTER TABLE marketplace_order_items
  ADD CONSTRAINT marketplace_order_items_warehouse_reward_check
  CHECK (warehouse_reward_tinkus >= 0);

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

  v_reward := COALESCE(v_delivery.reward_tinkus, 0);

  IF v_reward <= 0 THEN
    SELECT COALESCE(value::int, 0)
    INTO v_reward
    FROM system_config
    WHERE key = 'warehouse_delivery_reward_tinkus';
  END IF;

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
