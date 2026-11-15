-- Integra pagos reales en ordenes de marketplace.
-- Tinkus se registra como financial_transaction; tarjeta queda asociada a payments/Stripe.

ALTER TABLE marketplace_orders
  ADD COLUMN IF NOT EXISTS payment_method varchar(20) NOT NULL DEFAULT 'tinkus',
  ADD COLUMN IF NOT EXISTS payment_id bigint REFERENCES payments(id),
  ADD COLUMN IF NOT EXISTS payment_transaction_id bigint REFERENCES financial_transactions(id);

ALTER TABLE marketplace_orders
  DROP CONSTRAINT IF EXISTS marketplace_orders_payment_method_check;

ALTER TABLE marketplace_orders
  ADD CONSTRAINT marketplace_orders_payment_method_check
  CHECK (payment_method IN ('tinkus', 'stripe'));

ALTER TABLE payment_requests
  DROP CONSTRAINT IF EXISTS check_target_required;

ALTER TABLE payment_requests
  ADD CONSTRAINT check_target_required
  CHECK (
    (type = 'partner_upgrade' AND target_id IS NULL)
    OR
    (type IN ('coin_purchase', 'subscription', 'marketplace_order') AND target_id IS NOT NULL)
  );

CREATE INDEX IF NOT EXISTS idx_marketplace_orders_payment
  ON marketplace_orders(payment_id);

CREATE INDEX IF NOT EXISTS idx_marketplace_orders_buyer_created
  ON marketplace_orders(buyer_id, created_at DESC);
