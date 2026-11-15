ALTER TABLE payments ADD COLUMN IF NOT EXISTS gateway_target_id bigint NULL;
ALTER TABLE marketplace_orders
  ADD COLUMN IF NOT EXISTS client_request_id uuid NULL,
  ADD COLUMN IF NOT EXISTS request_hash text NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uniq_marketplace_order_request
  ON marketplace_orders(buyer_id, client_request_id) WHERE client_request_id IS NOT NULL;
ALTER TABLE boosts ADD COLUMN IF NOT EXISTS paid_days int NULL CHECK (paid_days > 0);
ALTER TABLE reservations ADD COLUMN IF NOT EXISTS payee_id uuid NULL REFERENCES users(id);
ALTER TABLE auth_verification_codes DROP CONSTRAINT IF EXISTS auth_verification_codes_purpose_check;
ALTER TABLE auth_verification_codes ADD CONSTRAINT auth_verification_codes_purpose_check
  CHECK (purpose IN ('email_verification', 'password_recovery', 'email_change'));
CREATE TABLE IF NOT EXISTS notification_push_queue (
  notification_id bigint PRIMARY KEY REFERENCES notifications(id) ON DELETE CASCADE,
  attempts int NOT NULL DEFAULT 0,
  available_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  lease_until timestamptz NULL
);
CREATE INDEX IF NOT EXISTS idx_notification_push_due ON notification_push_queue(available_at);
DO $$
DECLARE target record;
BEGIN
  FOR target IN SELECT DISTINCT grantee FROM information_schema.role_table_grants
    WHERE table_schema = 'public' AND table_name = 'notifications' AND grantee <> 'PUBLIC'
  LOOP
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON notification_push_queue TO %I', target.grantee);
  END LOOP;
END $$;
-- New columns remain nullable for existing clients and historical rows.
-- Recover a historical payee only from one exact, paired event transfer.
WITH payees AS (
  SELECT r.id, (array_agg(DISTINCT credit.user_id))[1] AS payee_id
  FROM reservations r
  JOIN financial_transactions debit ON debit.user_id = r.user_id
    AND debit.type = 'spend' AND debit.status = 'approved'
    AND debit.description = 'Reserva de evento' AND debit.amount = r.tinku_amount
    AND debit.created_at = r.created_at
  JOIN financial_transactions credit ON credit.reference_id = debit.reference_id
    AND credit.type = 'reward' AND credit.status = 'approved' AND credit.amount = debit.amount
    AND credit.created_at = debit.created_at AND credit.user_id <> debit.user_id
  WHERE r.payee_id IS NULL AND r.tinku_amount > 0
  GROUP BY r.id HAVING COUNT(DISTINCT credit.id) = 1
)
UPDATE reservations r SET payee_id = p.payee_id FROM payees p WHERE r.id = p.id;
-- Other historical refunds require reconciliation, never a guessed payee.
UPDATE boosts SET paid_days = GREATEST(1, end_date::date - start_date::date + 1) WHERE paid_days IS NULL;
-- Invalidate codes that may have been returned to sellers by older versions.
UPDATE marketplace_orders SET pickup_code = 'TK-' || upper(substr(md5(gen_random_uuid()::text), 1, 16))
  WHERE status NOT IN ('delivered', 'cancelled');
UPDATE marketplace_orders SET pickup_expires_at = CURRENT_TIMESTAMP +
  GREATEST(COALESCE((SELECT value::int FROM system_config WHERE key = 'marketplace_pickup_expiration_days'), 7), 1) * INTERVAL '1 day'
  WHERE status = 'ready_for_pickup' AND pickup_expires_at IS NULL;
CREATE OR REPLACE FUNCTION enqueue_notification_push() RETURNS trigger
LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  INSERT INTO notification_push_queue(notification_id) VALUES (NEW.id) ON CONFLICT DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION initialize_boost_paid_days() RETURNS trigger
LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  NEW.paid_days := GREATEST(1, NEW.end_date::date - NEW.start_date::date + 1);
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION guard_reservation_state() RETURNS trigger
LANGUAGE plpgsql SET search_path = public AS $$
DECLARE
  v_event events%ROWTYPE;
  v_owner uuid;
  v_count int;
BEGIN
  IF TG_OP = 'UPDATE' THEN
    IF NEW.user_id IS DISTINCT FROM OLD.user_id OR NEW.event_id <> OLD.event_id OR
       NEW.quantity <> OLD.quantity OR NEW.tinku_amount <> OLD.tinku_amount OR
       NEW.payee_id IS DISTINCT FROM OLD.payee_id THEN
      RAISE EXCEPTION 'Invalid reservation transition';
    END IF;
    IF NEW.status <> OLD.status AND NEW.status = 'confirmed' THEN
      RAISE EXCEPTION 'Invalid reservation transition';
    END IF;
    IF NEW.status <> OLD.status AND NEW.status = 'cancelled'
       AND COALESCE(current_setting('app.cancelling_reservation', true), '') <> 'true' THEN
      RAISE EXCEPTION 'Invalid reservation transition';
    END IF;
    RETURN NEW;
  END IF;
  SELECT * INTO v_event FROM events WHERE id = NEW.event_id FOR UPDATE;
  IF NOT FOUND OR v_event.status <> 'active' OR v_event.end_date <= CURRENT_TIMESTAMP THEN
    RAISE EXCEPTION 'Event is not available for reservations';
  END IF;
  IF v_event.business_id IS NOT NULL THEN
    SELECT owner_id INTO v_owner FROM businesses
      WHERE id = v_event.business_id AND validated = true AND status = 'active';
    IF NOT FOUND THEN RAISE EXCEPTION 'Event is not available for reservations'; END IF;
  ELSE
    v_owner := v_event.creator_id;
  END IF;
  IF NEW.quantity <= 0 THEN RAISE EXCEPTION 'Invalid quantity'; END IF;
  IF NEW.status = 'confirmed' AND v_event.capacity > 0 THEN
    SELECT COALESCE(SUM(quantity), 0) INTO v_count FROM reservations
      WHERE event_id = NEW.event_id AND status = 'confirmed';
    IF v_count + NEW.quantity > v_event.capacity THEN RAISE EXCEPTION 'Not enough capacity'; END IF;
  END IF;
  NEW.payee_id := v_owner;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION cancel_reservation_with_refund(p_id bigint, p_actor_id uuid, p_event_cancel boolean DEFAULT false)
RETURNS reservations LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_res reservations%ROWTYPE;
  v_event events%ROWTYPE;
  v_event_id bigint;
BEGIN
  IF current_app_user_id() IS DISTINCT FROM p_actor_id AND NOT is_admin() THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  SELECT event_id INTO v_event_id FROM reservations WHERE id = p_id;
  SELECT * INTO v_event FROM events WHERE id = v_event_id FOR UPDATE;
  SELECT * INTO v_res FROM reservations WHERE id = p_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Reservation not found'; END IF;
  IF v_res.user_id <> p_actor_id AND NOT is_admin() AND NOT (p_event_cancel AND v_event.creator_id = p_actor_id) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  IF v_res.status = 'cancelled' THEN RETURN v_res; END IF;
  IF EXISTS (SELECT 1 FROM event_tickets t JOIN event_ticket_days d ON d.ticket_id = t.id
             WHERE t.reservation_id = p_id AND (d.status = 'used' OR d.used_at IS NOT NULL)) OR
     (v_event.end_date <= CURRENT_TIMESTAMP AND NOT is_admin()) THEN
    RAISE EXCEPTION 'Used or finished reservations cannot be cancelled';
  END IF;
  IF v_res.status = 'confirmed' AND v_res.tinku_amount > 0 THEN
    IF v_res.payee_id IS NULL THEN RAISE EXCEPTION 'Reservation refund requires review'; END IF;
    PERFORM user_id FROM wallets WHERE user_id IN (v_res.payee_id, v_res.user_id) ORDER BY user_id FOR UPDATE;
    IF NOT EXISTS (SELECT 1 FROM wallets WHERE user_id = v_res.payee_id AND balance >= v_res.tinku_amount) THEN
      RAISE EXCEPTION 'Organizer balance is insufficient for refund';
    END IF;
    PERFORM transfer_tinku(v_res.payee_id, v_res.user_id, v_res.tinku_amount, 'Devolucion de reserva #' || p_id::text);
  END IF;
  PERFORM set_config('app.cancelling_reservation', 'true', true);
  UPDATE reservations SET status = 'cancelled' WHERE id = p_id RETURNING * INTO v_res;
  PERFORM set_config('app.cancelling_reservation', 'false', true);
  UPDATE event_ticket_days SET status = 'cancelled' WHERE ticket_id IN (SELECT id FROM event_tickets WHERE reservation_id = p_id);
  UPDATE event_tickets SET status = 'cancelled' WHERE reservation_id = p_id;
  INSERT INTO notifications(user_id, title, message, type, entity_type, entity_id, route)
    VALUES (v_res.user_id, 'Reserva cancelada', 'Se cancelo tu reserva #' || p_id::text || '. Tinkus devueltos: ' || v_res.tinku_amount::text,
            'reservation', 'event', v_res.event_id, '/myCalendar');
  PERFORM write_audit_log(p_actor_id, 'reservation_cancelled', 'reservation', p_id,
    jsonb_build_object('refunded_tinkus', v_res.tinku_amount, 'payee_id', v_res.payee_id));
  RETURN v_res;
END;
$$;

CREATE OR REPLACE FUNCTION cancel_event_with_refunds(p_event_id bigint) RETURNS events
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_event events%ROWTYPE;
  v_id bigint;
BEGIN
  SELECT * INTO v_event FROM events WHERE id = p_event_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Event not found'; END IF;
  IF v_event.creator_id IS DISTINCT FROM current_app_user_id() THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  FOR v_id IN SELECT id FROM reservations WHERE event_id = p_event_id AND status <> 'cancelled' ORDER BY id LOOP
    PERFORM cancel_reservation_with_refund(v_id, current_app_user_id(), true);
  END LOOP;
  UPDATE events SET status = 'cancelled' WHERE id = p_event_id RETURNING * INTO v_event;
  RETURN v_event;
END;
$$;
DROP TRIGGER IF EXISTS trg_queue_notification_push ON notifications;
CREATE TRIGGER trg_queue_notification_push AFTER INSERT ON notifications
  FOR EACH ROW EXECUTE FUNCTION enqueue_notification_push();
DROP TRIGGER IF EXISTS trg_initialize_boost_paid_days ON boosts;
CREATE TRIGGER trg_initialize_boost_paid_days BEFORE INSERT ON boosts
  FOR EACH ROW EXECUTE FUNCTION initialize_boost_paid_days();
DROP TRIGGER IF EXISTS trg_guard_reservation_state ON reservations;
CREATE TRIGGER trg_guard_reservation_state BEFORE INSERT OR UPDATE ON reservations
  FOR EACH ROW EXECUTE FUNCTION guard_reservation_state();

