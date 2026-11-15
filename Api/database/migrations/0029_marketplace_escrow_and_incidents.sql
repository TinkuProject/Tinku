ALTER TABLE marketplace_orders
  ADD COLUMN IF NOT EXISTS seller_id uuid REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS seller_amount_tinkus int NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS seller_payout_transaction_id bigint REFERENCES financial_transactions(id),
  ADD COLUMN IF NOT EXISTS settled_at timestamp NULL,
  ADD COLUMN IF NOT EXISTS pickup_expires_at timestamp NULL,
  ADD COLUMN IF NOT EXISTS cancellation_reason varchar(500),
  ADD COLUMN IF NOT EXISTS cancelled_by uuid REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS cancelled_at timestamp NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'marketplace_orders_seller_amount_nonnegative'
  ) THEN
    ALTER TABLE marketplace_orders
      ADD CONSTRAINT marketplace_orders_seller_amount_nonnegative
      CHECK (seller_amount_tinkus >= 0);
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS marketplace_order_incidents (
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

UPDATE marketplace_orders mo
SET seller_id = seller.owner_id,
    seller_amount_tinkus = seller.amount
FROM (
  SELECT
    oi.order_id,
    MIN(b.owner_id::text)::uuid AS owner_id,
    COALESCE(SUM(oi.unit_tinku_price * oi.quantity), 0)::int AS amount
  FROM marketplace_order_items oi
  JOIN businesses b ON b.id = oi.business_id
  WHERE b.owner_id IS NOT NULL
  GROUP BY oi.order_id
  HAVING COUNT(DISTINCT b.owner_id) = 1
) seller
WHERE seller.order_id = mo.id
  AND mo.seller_id IS NULL;

WITH payouts AS (
  SELECT DISTINCT ON (ft.reference_id)
    ft.reference_id AS order_id,
    ft.id,
    ft.created_at
  FROM financial_transactions ft
  WHERE ft.purpose = 'marketplace_sale'
    AND ft.type = 'reward'
    AND ft.status = 'approved'
  ORDER BY ft.reference_id, ft.id DESC
)
UPDATE marketplace_orders mo
SET seller_payout_transaction_id = payouts.id,
    settled_at = COALESCE(payouts.created_at, mo.updated_at, mo.created_at)
FROM payouts
WHERE payouts.order_id = mo.id
  AND mo.seller_payout_transaction_id IS NULL;

INSERT INTO system_config (key, value, description)
VALUES (
  'marketplace_pickup_expiration_days',
  '7',
  'Días disponibles para retirar un pedido una vez que está listo'
)
ON CONFLICT (key) DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_marketplace_orders_seller
  ON marketplace_orders(seller_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_marketplace_orders_unsettled
  ON marketplace_orders(status, settled_at)
  WHERE settled_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_marketplace_order_incidents_order
  ON marketplace_order_incidents(order_id, created_at DESC);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'trg_set_updated_at'
      AND tgrelid = 'marketplace_order_incidents'::regclass
      AND NOT tgisinternal
  ) THEN
    CREATE TRIGGER trg_set_updated_at
      BEFORE UPDATE ON marketplace_order_incidents
      FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;
END $$;

CREATE OR REPLACE FUNCTION settle_marketplace_order(
  p_order_id bigint
)
RETURNS marketplace_orders
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_order marketplace_orders%ROWTYPE;
  v_tx_id bigint;
BEGIN
  SELECT * INTO v_order
  FROM marketplace_orders
  WHERE id = p_order_id
  FOR UPDATE;

  IF NOT FOUND THEN RAISE EXCEPTION 'Marketplace order not found'; END IF;
  IF v_order.status <> 'delivered' THEN
    RAISE EXCEPTION 'Marketplace order is not delivered';
  END IF;
  IF v_order.seller_payout_transaction_id IS NOT NULL
     OR v_order.settled_at IS NOT NULL THEN
    RETURN v_order;
  END IF;
  IF v_order.seller_id IS NULL OR v_order.seller_amount_tinkus <= 0 THEN
    RAISE EXCEPTION 'Marketplace seller settlement is not configured';
  END IF;

  UPDATE wallets
  SET balance = balance + v_order.seller_amount_tinkus,
      updated_at = CURRENT_TIMESTAMP
  WHERE user_id = v_order.seller_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Marketplace seller wallet not found'; END IF;

  INSERT INTO financial_transactions (
    user_id, type, amount, currency, purpose, reference_id,
    status, description, created_at
  ) VALUES (
    v_order.seller_id, 'reward', v_order.seller_amount_tinkus, 'TINKU',
    'marketplace_sale', v_order.id, 'approved',
    'Venta marketplace #' || v_order.id || ' entregada', CURRENT_TIMESTAMP
  ) RETURNING id INTO v_tx_id;

  UPDATE marketplace_orders
  SET seller_payout_transaction_id = v_tx_id,
      settled_at = CURRENT_TIMESTAMP,
      updated_at = CURRENT_TIMESTAMP
  WHERE id = v_order.id
  RETURNING * INTO v_order;

  PERFORM write_audit_log(
    v_order.seller_id,
    'marketplace_order_settled',
    'marketplace_order',
    v_order.id,
    jsonb_build_object(
      'transaction_id', v_tx_id,
      'seller_amount_tinkus', v_order.seller_amount_tinkus
    )
  );

  RETURN v_order;
END;
$$;

ALTER FUNCTION settle_marketplace_order(bigint) OWNER TO postgres;
GRANT EXECUTE ON FUNCTION settle_marketplace_order(bigint) TO PUBLIC;
