-- =========================
-- HELPERS
-- =========================
CREATE OR REPLACE FUNCTION current_app_user_id()
RETURNS uuid AS $$
  SELECT NULLIF(current_setting('app.user_id', true), '')::uuid;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION current_app_user_role()
RETURNS text AS $$
  SELECT NULLIF(current_setting('app.user_role', true), '');
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION is_master()
RETURNS boolean AS $$
  SELECT COALESCE(current_app_user_role() = 'master', false);
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
  SELECT COALESCE(current_app_user_role() IN ('admin','master'), false);
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION set_system_context()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM set_config('app.context', 'system', true);
  PERFORM set_config('app.user_role', 'master', true);
END;
$$;

----MEDIA
CREATE OR REPLACE FUNCTION can_access_media(
  p_entity_type media_entity_type,
  p_entity_id text
)
RETURNS boolean AS $$
BEGIN
  RETURN (

    is_admin()

    OR
    (
      p_entity_type = 'business'
      AND EXISTS (
        SELECT 1 FROM businesses b
        WHERE b.id::text = p_entity_id
        AND b.owner_id = current_app_user_id()
      )
    )

    OR
    (
      p_entity_type = 'certification'
      AND EXISTS (
        SELECT 1 FROM certifications c
        JOIN businesses b ON b.id = c.business_id
        WHERE c.id::text = p_entity_id
        AND b.owner_id = current_app_user_id()
      )
    )

    OR
    (
      p_entity_type = 'discount'
      AND EXISTS (
        SELECT 1
        FROM discounts d
        JOIN businesses b ON b.id = d.business_id
        WHERE d.id::text = p_entity_id
        AND b.owner_id = current_app_user_id()
      )
    )

    OR
    (
      p_entity_type = 'event'
      AND EXISTS (
        SELECT 1 FROM events e
        WHERE e.id::text = p_entity_id
        AND e.creator_id = current_app_user_id()
      )
    )

    OR
    (
      p_entity_type = 'payment'
      AND EXISTS (
        SELECT 1 FROM payments p
        WHERE p.id::text = p_entity_id
        AND p.user_id = current_app_user_id()
      )
    )

    OR
    (
      p_entity_type = 'product'
      AND EXISTS (
        SELECT 1 FROM products p
        JOIN businesses b ON b.id = p.business_id
        WHERE p.id::text = p_entity_id
        AND b.owner_id = current_app_user_id()
      )
    )

    OR
    (
      p_entity_type = 'review'
      AND EXISTS (
        SELECT 1 FROM reviews r
        WHERE r.id::text = p_entity_id
        AND r.user_id = current_app_user_id()
      )
    )

    OR
    (
      p_entity_type = 'tourist_place'
      AND is_admin()
    )

    OR
    (
      p_entity_type = 'user'
      AND p_entity_id = current_app_user_id()::text
    ) 
  );
END;
$$ LANGUAGE plpgsql STABLE;


CREATE OR REPLACE FUNCTION can_read_media_public(
  p_entity_type media_entity_type,
  p_entity_id text
)
RETURNS boolean AS $$
BEGIN
  RETURN (
    -- contenido público
    (
      p_entity_type = 'business'
      AND EXISTS (
        SELECT 1 FROM businesses b
        WHERE b.id::text = p_entity_id
        AND b.status = 'active'
      )
    )

    OR
    (
      p_entity_type = 'certification'
      AND EXISTS (
        SELECT 1
        FROM certifications c
        JOIN businesses b ON b.id = c.business_id
        WHERE c.id::text = p_entity_id
        AND b.status = 'active'
      )
    )

    OR
    (
      p_entity_type = 'coin_package'
      AND EXISTS (
        SELECT 1
        FROM coin_packages cp
        WHERE cp.id::text = p_entity_id
        AND cp.status = 'active'
      )
    )

    OR 
    (
      p_entity_type = 'discount'
      AND EXISTS (
        SELECT 1
        FROM discounts d
        JOIN businesses b ON b.id = d.business_id
        WHERE d.id::text = p_entity_id
        AND b.status = 'active'
      )
    )

    OR
    (
      p_entity_type = 'event'
      AND EXISTS (
        SELECT 1 FROM events e
        WHERE e.id::text = p_entity_id
        AND e.status = 'active'
      )
    )

    OR
    (
      p_entity_type = 'event'
      AND EXISTS (
        SELECT 1
        FROM reservations r
        WHERE r.event_id::text = p_entity_id
          AND r.user_id = current_app_user_id()
          AND r.status = 'confirmed'
      )
    )

    OR
    (
      p_entity_type = 'product'
      AND EXISTS (
        SELECT 1
        FROM products p
        JOIN businesses b ON b.id = p.business_id
        WHERE p.id::text = p_entity_id
        AND b.status = 'active'
      )
    )

    OR
    (
      p_entity_type = 'review'
      AND EXISTS (
        SELECT 1
        FROM reviews r
        WHERE r.id::text = p_entity_id
      )
    )

    OR
    (
      p_entity_type = 'subscription'
      AND EXISTS (
        SELECT 1
        FROM subscription_plans sp
        WHERE sp.id::text = p_entity_id
        AND sp.status = 'active'
      )
    )

    OR
    (
      p_entity_type = 'tourist_place'
      AND EXISTS (
        SELECT 1 FROM tourist_places t
        WHERE t.id::text = p_entity_id
      )
    )

  );
END;
$$ LANGUAGE plpgsql STABLE;

-- =========================
-- ECONOMÍA (CORE)
-- =========================

CREATE OR REPLACE FUNCTION apply_transaction(
  p_user_id uuid,
  p_type transaction_type,
  p_amount numeric,
  p_status transaction_status DEFAULT 'approved',
  p_description text DEFAULT NULL,
  p_reference_id bigint DEFAULT NULL,
  p_payment_id bigint DEFAULT NULL
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_transaction_id bigint;
  v_effect numeric;
BEGIN
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be greater than 0';
  END IF;

  IF p_reference_id IS NOT NULL THEN
    SELECT id INTO v_transaction_id
    FROM financial_transactions
    WHERE reference_id = p_reference_id
    AND type = p_type;

    IF FOUND THEN
      RETURN v_transaction_id;
    END IF;
  END IF;

  PERFORM set_config('app.context', 'system', true);

  v_effect := CASE
    WHEN p_type IN ('spend', 'cashout') THEN -p_amount
    ELSE p_amount
  END;

  PERFORM 1 FROM wallets
  WHERE user_id = p_user_id
  FOR UPDATE;

  IF v_effect < 0 THEN
    IF NOT EXISTS (
      SELECT 1 FROM wallets
      WHERE user_id = p_user_id
      AND balance >= ABS(v_effect)
    ) THEN
      RAISE EXCEPTION 'Insufficient balance';
    END IF;
  END IF;

  INSERT INTO financial_transactions (
    user_id,
    type,
    status,
    amount,
    description,
    reference_id,
    payment_id
  )
  VALUES (
    p_user_id,
    p_type,
    p_status,
    p_amount,
    p_description,
    p_reference_id,
    p_payment_id
  )
  RETURNING id INTO v_transaction_id;

  IF p_status = 'approved' THEN
    UPDATE wallets
    SET balance = balance + v_effect
    WHERE user_id = p_user_id;
  END IF;

  RETURN v_transaction_id;
END;
$$;

ALTER FUNCTION apply_transaction(uuid, transaction_type, numeric, transaction_status, text, bigint, bigint) 
OWNER TO postgres;

-- =========================
-- TRANSFERENCIAS
-- =========================

CREATE OR REPLACE FUNCTION transfer_tinku(
  p_from_user uuid,
  p_to_user uuid,
  p_amount numeric,
  p_description text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_ref bigint := floor(random() * 1e12);
BEGIN
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Invalid amount';
  END IF;

  IF p_from_user = p_to_user THEN
    RAISE EXCEPTION 'Cannot transfer to same user';
  END IF;

  PERFORM apply_transaction(
    p_from_user,
    'spend',
    p_amount,
    'approved',
    p_description,
    v_ref
  );

  PERFORM apply_transaction(
    p_to_user,
    'reward',
    p_amount,
    'approved',
    p_description,
    v_ref
  );

END;
$$;

ALTER FUNCTION transfer_tinku(uuid, uuid, numeric, text) OWNER TO postgres;
-- =========================
-- ADMIN
-- =========================

CREATE OR REPLACE FUNCTION admin_adjustment(
  p_user_id uuid,
  p_amount numeric,
  p_description text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  IF p_amount = 0 THEN
    RAISE EXCEPTION 'Amount cannot be zero';
  END IF;

  PERFORM apply_transaction(
    p_user_id,
    'admin_adjustment',
    ABS(p_amount),
    'approved',
    p_description
  );
END;
$$;

ALTER FUNCTION admin_adjustment(uuid, numeric, text) OWNER TO postgres;
-- =========================
-- PAGOS
-- =========================

CREATE OR REPLACE FUNCTION create_payment(
  p_user_id uuid,
  p_amount numeric,
  p_method payment_method,
  p_external_reference text
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_payment_id bigint;
BEGIN
  IF p_user_id != current_app_user_id() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Invalid amount';
  END IF;

  INSERT INTO payments (
    user_id,
    method,
    amount,
    external_reference,
    status
  )
  VALUES (
    p_user_id,
    p_method,
    p_amount,
    p_external_reference,
    'pending'
  )
  RETURNING id INTO v_payment_id;

  RETURN v_payment_id;
END;
$$;

CREATE OR REPLACE FUNCTION approve_payment(
  p_payment_id bigint
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_amount numeric;
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  UPDATE payments
  SET status = 'approved'
  WHERE id = p_payment_id
  AND status = 'pending'
  RETURNING user_id, amount
  INTO v_user_id, v_amount;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payment not found or already processed';
  END IF;

  PERFORM apply_transaction(
    v_user_id,
    'purchase',
    v_amount,
    'approved',
    'Payment approved',
    p_payment_id,
    p_payment_id
  );
END;
$$;

ALTER FUNCTION create_payment(uuid, numeric, payment_method, text) OWNER TO postgres;
ALTER FUNCTION approve_payment(bigint) OWNER TO postgres;

-- =========================
-- CASHOUT REQUESTS
-- =========================
CREATE OR REPLACE FUNCTION create_cashout_request(
  p_user_id uuid,
  p_cashout_package_id bigint,
  p_comment text DEFAULT NULL
)
RETURNS cashout_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_package cashout_packages%ROWTYPE;
  v_wallet wallets%ROWTYPE;
  v_request cashout_requests;
BEGIN
  IF current_app_user_id() IS NULL OR current_app_user_id() <> p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT *
  INTO v_package
  FROM cashout_packages
  WHERE id = p_cashout_package_id
    AND status = 'active';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Cashout package not found';
  END IF;

  SELECT *
  INTO v_wallet
  FROM wallets
  WHERE user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Wallet not found';
  END IF;

  IF v_wallet.balance < v_package.tinkus_amount THEN
    RAISE EXCEPTION 'Insufficient balance';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM cashout_requests
    WHERE user_id = p_user_id
      AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'User already has a pending cashout request';
  END IF;

  INSERT INTO cashout_requests (
    user_id,
    cashout_package_id,
    status,
    tinkus_amount,
    cash_amount,
    comment
  )
  VALUES (
    p_user_id,
    p_cashout_package_id,
    'pending',
    v_package.tinkus_amount,
    v_package.cash_amount,
    p_comment
  )
  RETURNING * INTO v_request;

  PERFORM write_audit_log(
    p_user_id,
    'cashout_request_created',
    'cashout_request',
    v_request.id,
    jsonb_build_object(
      'cashout_package_id', p_cashout_package_id,
      'tinkus_amount', v_package.tinkus_amount,
      'cash_amount', v_package.cash_amount
    )
  );

  RETURN v_request;
END;
$$;

CREATE OR REPLACE FUNCTION approve_cashout_request(
  p_request_id bigint,
  p_admin_id uuid,
  p_comment text DEFAULT NULL
)
RETURNS cashout_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_request cashout_requests%ROWTYPE;
  v_tx_id bigint;
BEGIN
  IF current_app_user_id() IS NULL OR NOT is_admin() THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  SELECT *
  INTO v_request
  FROM cashout_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Request not found';
  END IF;

  IF v_request.status = 'approved' THEN
    RETURN v_request;
  END IF;

  IF v_request.status <> 'pending' THEN
    RAISE EXCEPTION 'Request already processed';
  END IF;

  v_tx_id := apply_transaction(
    v_request.user_id,
    'cashout',
    v_request.tinkus_amount,
    'approved',
    'Cashout approved',
    v_request.id,
    NULL
  );

  UPDATE cashout_requests
  SET status = 'approved',
      reviewed_by = p_admin_id,
      reviewed_at = NOW(),
      comment = p_comment,
      transaction_id = v_tx_id,
      updated_at = NOW()
  WHERE id = v_request.id
  RETURNING * INTO v_request;

  PERFORM write_audit_log(
    p_admin_id,
    'cashout_request_approved',
    'cashout_request',
    v_request.id,
    jsonb_build_object(
      'user_id', v_request.user_id,
      'transaction_id', v_tx_id,
      'tinkus_amount', v_request.tinkus_amount,
      'cash_amount', v_request.cash_amount
    )
  );

  RETURN v_request;
END;
$$;

CREATE OR REPLACE FUNCTION reject_cashout_request(
  p_request_id bigint,
  p_admin_id uuid,
  p_comment text DEFAULT NULL
)
RETURNS cashout_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_request cashout_requests%ROWTYPE;
BEGIN
  IF current_app_user_id() IS NULL OR NOT is_admin() THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  SELECT *
  INTO v_request
  FROM cashout_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Request not found';
  END IF;

  IF v_request.status = 'rejected' THEN
    RETURN v_request;
  END IF;

  IF v_request.status <> 'pending' THEN
    RAISE EXCEPTION 'Request already processed';
  END IF;

  UPDATE cashout_requests
  SET status = 'rejected',
      reviewed_by = p_admin_id,
      reviewed_at = NOW(),
      comment = p_comment,
      updated_at = NOW()
  WHERE id = v_request.id
  RETURNING * INTO v_request;

  PERFORM write_audit_log(
    p_admin_id,
    'cashout_request_rejected',
    'cashout_request',
    v_request.id,
    jsonb_build_object(
      'user_id', v_request.user_id,
      'tinkus_amount', v_request.tinkus_amount,
      'cash_amount', v_request.cash_amount,
      'comment', p_comment
    )
  );

  RETURN v_request;
END;
$$;

ALTER FUNCTION create_cashout_request(uuid, bigint, text) OWNER TO postgres;
ALTER FUNCTION approve_cashout_request(bigint, uuid, text) OWNER TO postgres;
ALTER FUNCTION reject_cashout_request(bigint, uuid, text) OWNER TO postgres;

GRANT EXECUTE ON FUNCTION create_cashout_request(uuid, bigint, text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION approve_cashout_request(bigint, uuid, text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION reject_cashout_request(bigint, uuid, text) TO PUBLIC;
-- =========================
-- REVERSOS
-- =========================

CREATE OR REPLACE FUNCTION reverse_transaction(
  p_transaction_id bigint
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tx financial_transactions%ROWTYPE;
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  SELECT * INTO v_tx
  FROM financial_transactions
  WHERE id = p_transaction_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaction not found';
  END IF;

  IF v_tx.status != 'approved' THEN
    RAISE EXCEPTION 'Only approved transactions can be reversed';
  END IF;

  PERFORM apply_transaction(
    v_tx.user_id,
    'refund',
    v_tx.amount,
    'approved',
    'Reversal of tx ' || v_tx.id,
    v_tx.id
  );
END;
$$;

ALTER FUNCTION reverse_transaction(bigint) OWNER TO postgres;
-- =========================
-- WALLET
-- =========================

CREATE OR REPLACE FUNCTION create_wallet(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- contexto interno
  PERFORM set_config('app.context', 'system', true);

  IF EXISTS (
    SELECT 1 FROM wallets WHERE user_id = p_user_id
  ) THEN
    RETURN;
  END IF;

  INSERT INTO wallets (user_id, balance)
  VALUES (p_user_id, 0);
END;
$$;

-- =========================
-- RESERVATION
-- =========================

CREATE OR REPLACE FUNCTION generate_event_tickets_for_reservation(
  p_reservation_id bigint
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_reservation reservations%ROWTYPE;
  v_event events%ROWTYPE;
  v_ticket_id uuid;
  v_ticket_number int;
  v_day date;
  v_valid_from timestamp;
  v_valid_until timestamp;
BEGIN
  SELECT *
  INTO v_reservation
  FROM reservations
  WHERE id = p_reservation_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reservation not found';
  END IF;

  IF v_reservation.status <> 'confirmed' THEN
    RAISE EXCEPTION 'Tickets can only be generated for confirmed reservations';
  END IF;

  SELECT *
  INTO v_event
  FROM events
  WHERE id = v_reservation.event_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event not found';
  END IF;

  FOR v_ticket_number IN 1..v_reservation.quantity LOOP
    INSERT INTO event_tickets (
      reservation_id,
      event_id,
      user_id,
      attendee_index
    )
    VALUES (
      v_reservation.id,
      v_reservation.event_id,
      v_reservation.user_id,
      v_ticket_number
    )
    ON CONFLICT (reservation_id, attendee_index) DO UPDATE
    SET updated_at = NOW()
    RETURNING id INTO v_ticket_id;

    FOR v_day IN
      SELECT generate_series(
        v_event.start_date::date,
        v_event.end_date::date,
        interval '1 day'
      )::date
    LOOP
      v_valid_from := GREATEST(v_event.start_date, v_day::timestamp);
      v_valid_until := LEAST(v_event.end_date, v_day::timestamp + interval '1 day');

      IF v_valid_until > v_valid_from THEN
        INSERT INTO event_ticket_days (
          ticket_id,
          event_id,
          event_date,
          status,
          valid_from,
          valid_until
        )
        VALUES (
          v_ticket_id,
          v_reservation.event_id,
          v_day,
          'active',
          v_valid_from,
          v_valid_until
        )
        ON CONFLICT (ticket_id, event_date) DO NOTHING;
      END IF;
    END LOOP;
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION write_audit_log(
  p_user_id uuid,
  p_action text,
  p_entity_type text DEFAULT NULL,
  p_entity_id bigint DEFAULT NULL,
  p_details jsonb DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO audit_logs (
    user_id,
    action,
    entity_type,
    entity_id,
    details
  )
  VALUES (
    p_user_id,
    p_action,
    p_entity_type,
    p_entity_id,
    p_details
  );
END;
$$;

ALTER FUNCTION write_audit_log(uuid, text, text, bigint, jsonb)
OWNER TO postgres;

CREATE OR REPLACE FUNCTION create_reservation_with_payment(
  p_user_id uuid,
  p_event_id bigint,
  p_quantity int
)
RETURNS reservations
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_event RECORD;
  v_total numeric;
  v_owner_id uuid;
  v_confirmed int;
  v_reservation reservations;
BEGIN

  -- =========================
  -- AUTH
  -- =========================
  IF current_app_user_id() IS NULL OR current_app_user_id() <> p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF p_quantity <= 0 THEN
    RAISE EXCEPTION 'Invalid quantity';
  END IF;

  -- =========================
  -- GET EVENT
  -- =========================
  SELECT *
  INTO v_event
  FROM events
  WHERE id = p_event_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event not found';
  END IF;

  -- =========================
  -- CALCULAR COSTO
  -- =========================
  v_total := COALESCE(v_event.tinku_price, 0) * p_quantity;

  -- =========================
  -- VALIDAR CAPACIDAD
  -- =========================
  IF v_event.capacity IS NOT NULL AND v_event.capacity > 0 THEN

    SELECT COALESCE(SUM(quantity), 0)
    INTO v_confirmed
    FROM reservations
    WHERE event_id = p_event_id
      AND status = 'confirmed';

    IF v_confirmed + p_quantity > v_event.capacity THEN
      RAISE EXCEPTION 'Not enough capacity';
    END IF;

  END IF;

  -- =========================
  -- OBTENER OWNER
  -- =========================
  IF v_event.business_id IS NOT NULL THEN

    SELECT owner_id
    INTO v_owner_id
    FROM businesses
    WHERE id = v_event.business_id;

    IF v_owner_id IS NULL THEN
      RAISE EXCEPTION 'Business owner not found';
    END IF;

  ELSE
    v_owner_id := v_event.creator_id;
  END IF;

  -- =========================
  -- TRANSFERENCIA (SI ES PAGO)
  -- =========================
  IF v_total > 0 THEN

    PERFORM transfer_tinku(
      p_user_id,
      v_owner_id,
      v_total,
      'Reserva de evento'
    );

  END IF;

  -- =========================
  -- CREAR RESERVA
  -- =========================
  INSERT INTO reservations(
    user_id,
    event_id,
    quantity,
    tinku_amount,
    status,
    created_at
  )
  VALUES (
    p_user_id,
    p_event_id,
    p_quantity,
    v_total,
    'confirmed',
    NOW()
  )
  RETURNING * INTO v_reservation;

  PERFORM generate_event_tickets_for_reservation(v_reservation.id);

  PERFORM write_audit_log(
    p_user_id,
    'reservation_created',
    'reservation',
    v_reservation.id,
    jsonb_build_object(
      'event_id', p_event_id,
      'quantity', p_quantity,
      'tinku_amount', v_total
    )
  );

  RETURN v_reservation;

END;
$$;

ALTER FUNCTION generate_event_tickets_for_reservation(bigint)
OWNER TO postgres;

ALTER FUNCTION create_reservation_with_payment(uuid, bigint, int)
OWNER TO postgres;

GRANT EXECUTE ON FUNCTION generate_event_tickets_for_reservation(bigint)
TO PUBLIC;

GRANT EXECUTE ON FUNCTION create_reservation_with_payment(uuid, bigint, int)
TO PUBLIC;

-- =========================
-- EVENT TICKETS / CHECK-IN
-- =========================
CREATE OR REPLACE FUNCTION issue_event_ticket_day_qr(
  p_ticket_day_id uuid,
  p_user_id uuid
)
RETURNS TABLE (
  ticket_day_id uuid,
  ticket_id uuid,
  reservation_id bigint,
  event_id bigint,
  event_name text,
  event_date date,
  valid_from timestamp,
  valid_until timestamp,
  qr_token text,
  qr_payload jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_ticket_day event_ticket_days%ROWTYPE;
  v_ticket event_tickets%ROWTYPE;
  v_event events%ROWTYPE;
  v_token text;
BEGIN
  IF current_app_user_id() IS NULL OR current_app_user_id() <> p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT *
  INTO v_ticket_day
  FROM event_ticket_days
  WHERE id = p_ticket_day_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Ticket day not found';
  END IF;

  SELECT *
  INTO v_ticket
  FROM event_tickets
  WHERE id = v_ticket_day.ticket_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Ticket not found';
  END IF;

  IF v_ticket.user_id <> p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF v_ticket.status <> 'active' THEN
    RAISE EXCEPTION 'Ticket is not active';
  END IF;

  IF v_ticket_day.status = 'used' THEN
    RAISE EXCEPTION 'Ticket day already used';
  END IF;

  IF v_ticket_day.status = 'cancelled' THEN
    RAISE EXCEPTION 'Ticket day cancelled';
  END IF;

  IF NOW() > v_ticket_day.valid_until THEN
    UPDATE event_ticket_days
    SET status = 'expired',
        updated_at = NOW()
    WHERE id = v_ticket_day.id
      AND status = 'active';

    RAISE EXCEPTION 'Ticket day expired';
  END IF;

  SELECT *
  INTO v_event
  FROM events
  WHERE id = v_ticket_day.event_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event not found';
  END IF;

  v_token := encode(gen_random_bytes(32), 'hex');

  UPDATE event_ticket_days
  SET qr_token_hash = encode(digest(v_token, 'sha256'), 'hex'),
      updated_at = NOW()
  WHERE id = v_ticket_day.id;

  RETURN QUERY
  SELECT
    v_ticket_day.id,
    v_ticket.id,
    v_ticket.reservation_id,
    v_ticket.event_id,
    v_event.name::text,
    v_ticket_day.event_date,
    v_ticket_day.valid_from,
    v_ticket_day.valid_until,
    v_token,
    jsonb_build_object(
      'type', 'event_checkin',
      'token', v_token,
      'ticket_day_id', v_ticket_day.id,
      'ticket_id', v_ticket.id,
      'reservation_id', v_ticket.reservation_id,
      'event_id', v_ticket.event_id,
      'event_name', v_event.name,
      'event_date', v_ticket_day.event_date,
      'valid_from', v_ticket_day.valid_from,
      'valid_until', v_ticket_day.valid_until
    );
END;
$$;

CREATE OR REPLACE FUNCTION check_in_event_ticket(
  p_token text,
  p_event_id bigint,
  p_scanner_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_hash text;
  v_ticket_day event_ticket_days%ROWTYPE;
  v_ticket event_tickets%ROWTYPE;
  v_event events%ROWTYPE;
  v_scanner_role user_role;
  v_allowed boolean := false;
BEGIN
  IF current_app_user_id() IS NULL OR current_app_user_id() <> p_scanner_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF p_token IS NULL OR length(trim(p_token)) = 0 THEN
    RETURN jsonb_build_object('status', 'invalid', 'reason', 'empty_token');
  END IF;

  SELECT role
  INTO v_scanner_role
  FROM users
  WHERE id = p_scanner_id;

  v_hash := encode(digest(trim(p_token), 'sha256'), 'hex');

  SELECT *
  INTO v_ticket_day
  FROM event_ticket_days
  WHERE qr_token_hash = v_hash
    AND event_id = p_event_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('status', 'invalid', 'reason', 'ticket_not_found');
  END IF;

  SELECT *
  INTO v_ticket
  FROM event_tickets
  WHERE id = v_ticket_day.ticket_id;

  SELECT *
  INTO v_event
  FROM events
  WHERE id = v_ticket_day.event_id;

  IF v_scanner_role IN ('admin', 'master') THEN
    v_allowed := true;
  ELSIF v_event.creator_id = p_scanner_id THEN
    v_allowed := true;
  ELSIF v_event.business_id IS NOT NULL AND EXISTS (
    SELECT 1
    FROM businesses b
    WHERE b.id = v_event.business_id
      AND b.owner_id = p_scanner_id
  ) THEN
    v_allowed := true;
  END IF;

  IF NOT v_allowed THEN
    RAISE EXCEPTION 'Not authorized to check in this event';
  END IF;

  IF v_ticket.status <> 'active' OR v_ticket_day.status = 'cancelled' THEN
    RETURN jsonb_build_object('status', 'invalid', 'reason', 'ticket_cancelled');
  END IF;

  IF v_ticket_day.status = 'used' THEN
    RETURN jsonb_build_object(
      'status', 'duplicate',
      'ticket_day_id', v_ticket_day.id,
      'used_at', v_ticket_day.used_at
    );
  END IF;

  IF NOW() < v_ticket_day.valid_from THEN
    RETURN jsonb_build_object(
      'status', 'not_yet_valid',
      'valid_from', v_ticket_day.valid_from
    );
  END IF;

  IF NOW() > v_ticket_day.valid_until THEN
    UPDATE event_ticket_days
    SET status = 'expired',
        updated_at = NOW()
    WHERE id = v_ticket_day.id
      AND status = 'active';

    RETURN jsonb_build_object(
      'status', 'expired',
      'valid_until', v_ticket_day.valid_until
    );
  END IF;

  UPDATE event_ticket_days
  SET status = 'used',
      used_at = NOW(),
      used_by = p_scanner_id,
      updated_at = NOW()
  WHERE id = v_ticket_day.id
    AND status = 'active'
    AND used_at IS NULL;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'status', 'duplicate',
      'ticket_day_id', v_ticket_day.id,
      'used_at', v_ticket_day.used_at
    );
  END IF;

  UPDATE events
  SET attendees_count = COALESCE(attendees_count, 0) + 1,
      updated_at = NOW()
  WHERE id = v_ticket_day.event_id;

  PERFORM write_audit_log(
    p_scanner_id,
    'event_ticket_checked_in',
    'event_ticket_day',
    NULL,
    jsonb_build_object(
      'ticket_day_id', v_ticket_day.id,
      'ticket_id', v_ticket.id,
      'reservation_id', v_ticket.reservation_id,
      'event_id', v_ticket_day.event_id,
      'event_date', v_ticket_day.event_date
    )
  );

  RETURN jsonb_build_object(
    'status', 'valid',
    'ticket_day_id', v_ticket_day.id,
    'ticket_id', v_ticket.id,
    'reservation_id', v_ticket.reservation_id,
    'event_id', v_ticket_day.event_id,
    'event_name', v_event.name,
    'event_date', v_ticket_day.event_date,
    'used_at', NOW()
  );
END;
$$;

ALTER FUNCTION issue_event_ticket_day_qr(uuid, uuid) OWNER TO postgres;
ALTER FUNCTION check_in_event_ticket(text, bigint, uuid) OWNER TO postgres;

GRANT EXECUTE ON FUNCTION issue_event_ticket_day_qr(uuid, uuid) TO PUBLIC;
GRANT EXECUTE ON FUNCTION check_in_event_ticket(text, bigint, uuid) TO PUBLIC;

-- =========================
-- APPROVE PAYMENT REQUEST
-- =========================
CREATE OR REPLACE FUNCTION approve_payment_request(
  p_request_id bigint,
  p_admin_id uuid,
  p_comment text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_request RECORD;
  v_payment RECORD;

  v_tinkus int;
  v_duration int;
BEGIN

  -- =========================
  -- AUTH
  -- =========================
  IF current_app_user_id() IS NULL OR NOT is_admin() THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  -- =========================
  -- LOCK REQUEST
  -- =========================
  SELECT *
  INTO v_request
  FROM payment_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Request not found';
  END IF;

  -- IDEMPOTENCIA
  IF v_request.status = 'approved' THEN
    RETURN;
  END IF;

  IF v_request.status <> 'pending' THEN
    RAISE EXCEPTION 'Request already processed';
  END IF;

  -- =========================
  -- LOCK PAYMENT
  -- =========================
  SELECT *
  INTO v_payment
  FROM payments
  WHERE id = v_request.payment_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payment not found';
  END IF;

  IF v_payment.status <> 'pending' THEN
    RAISE EXCEPTION 'Payment already processed';
  END IF;

  IF v_payment.type <> v_request.type THEN
    RAISE EXCEPTION 'Invalid payment type';
  END IF;

  -- =========================
  -- LOGIC BY TYPE
  -- =========================

  -- 🔵 PARTNER UPGRADE
  IF v_request.type = 'partner_upgrade' THEN

    SELECT value::int
    INTO v_tinkus
    FROM system_config
    WHERE key = 'upgrade_to_partner';

    IF v_tinkus IS NULL THEN
      RAISE EXCEPTION 'Upgrade config not found';
    END IF;

    UPDATE users
    SET role = 'partner',
        updated_at = NOW()
    WHERE id = v_request.user_id;

    INSERT INTO wallets (user_id, balance)
    VALUES (v_request.user_id, 0)
    ON CONFLICT (user_id) DO NOTHING;

    PERFORM apply_transaction(
      v_request.user_id,
      'reward',
      v_tinkus,
      'approved',
      'Cambio a rol socio',
      v_request.payment_id,
      v_request.payment_id
    );

  -- 🟡 COIN PURCHASE
  ELSIF v_request.type = 'coin_purchase' THEN

    IF v_request.target_id IS NULL THEN
      RAISE EXCEPTION 'Target ID required for coin purchase';
    END IF;

    SELECT tinkus_amount
    INTO v_tinkus
    FROM coin_packages
    WHERE id = v_request.target_id;

    IF v_tinkus IS NULL THEN
      RAISE EXCEPTION 'Invalid coin package';
    END IF;

    INSERT INTO wallets (user_id, balance)
    VALUES (v_request.user_id, 0)
    ON CONFLICT (user_id) DO NOTHING;

    PERFORM apply_transaction(
      v_request.user_id,
      'reward',
      v_tinkus,
      'approved',
      'Compra de monedas',
      v_request.payment_id,
      v_request.payment_id
    );

  -- 🟣 SUBSCRIPTION
  ELSIF v_request.type = 'subscription' THEN

    IF v_request.target_id IS NULL THEN
      RAISE EXCEPTION 'Target ID required for subscription';
    END IF;

    SELECT duration_months, included_tinku
    INTO v_duration, v_tinkus
    FROM subscription_plans
    WHERE id = v_request.target_id;

    IF v_duration IS NULL THEN
      RAISE EXCEPTION 'Invalid subscription plan';
    END IF;

    INSERT INTO user_subscriptions (
      user_id,
      plan_id,
      start_date,
      end_date,
      status
    )
    VALUES (
      v_request.user_id,
      v_request.target_id,
      NOW(),
      NOW() + (v_duration || ' months')::interval,
      'active'
    );

    -- bonus tinkus si aplica
    IF v_tinkus IS NOT NULL AND v_tinkus > 0 THEN
      PERFORM apply_transaction(
        v_request.user_id,
        'reward',
        v_tinkus,
        'approved',
        'Beneficio de suscripción',
        v_request.payment_id,
        v_request.payment_id
      );
    END IF;

  ELSE
    RAISE EXCEPTION 'Unsupported request type';
  END IF;

  -- =========================
  -- UPDATE REQUEST
  -- =========================
  UPDATE payment_requests
  SET status = 'approved',
      reviewed_by = p_admin_id,
      reviewed_at = NOW(),
      comment = p_comment,
      updated_at = NOW()
  WHERE id = v_request.id;

  -- =========================
  -- UPDATE PAYMENT
  -- =========================
  UPDATE payments
  SET status = 'approved',
      updated_at = NOW()
  WHERE id = v_payment.id;

  PERFORM write_audit_log(
    p_admin_id,
    'payment_request_approved',
    'payment_request',
    v_request.id,
    jsonb_build_object(
      'payment_id', v_payment.id,
      'user_id', v_request.user_id,
      'type', v_request.type,
      'target_id', v_request.target_id,
      'comment', p_comment
    )
  );

END;
$$;

-- =========================
-- APPROVE STRIPE PAYMENT REQUEST
-- =========================
CREATE OR REPLACE FUNCTION approve_stripe_payment_request(
  p_request_id bigint,
  p_payment_intent_id text,
  p_system_user_id uuid,
  p_comment text DEFAULT 'Pago aprobado automaticamente por Stripe'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_request RECORD;
  v_payment RECORD;

  v_tinkus int;
  v_duration int;
BEGIN
  SELECT *
  INTO v_request
  FROM payment_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Request not found';
  END IF;

  IF v_request.status = 'approved' THEN
    RETURN;
  END IF;

  IF v_request.status <> 'pending' THEN
    RAISE EXCEPTION 'Request already processed';
  END IF;

  SELECT *
  INTO v_payment
  FROM payments
  WHERE id = v_request.payment_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payment not found';
  END IF;

  IF v_payment.status = 'approved' THEN
    RETURN;
  END IF;

  IF v_payment.status <> 'pending' THEN
    RAISE EXCEPTION 'Payment already processed';
  END IF;

  IF v_payment.method <> 'gateway' THEN
    RAISE EXCEPTION 'Payment is not a gateway payment';
  END IF;

  IF v_payment.external_reference IS DISTINCT FROM p_payment_intent_id THEN
    RAISE EXCEPTION 'Invalid Stripe payment reference';
  END IF;

  IF v_payment.type <> v_request.type THEN
    RAISE EXCEPTION 'Invalid payment type';
  END IF;

  IF v_request.type = 'partner_upgrade' THEN
    SELECT value::int
    INTO v_tinkus
    FROM system_config
    WHERE key = 'upgrade_to_partner';

    IF v_tinkus IS NULL THEN
      RAISE EXCEPTION 'Upgrade config not found';
    END IF;

    UPDATE users
    SET role = 'partner',
        updated_at = NOW()
    WHERE id = v_request.user_id;

    INSERT INTO wallets (user_id, balance)
    VALUES (v_request.user_id, 0)
    ON CONFLICT (user_id) DO NOTHING;

    PERFORM apply_transaction(
      v_request.user_id,
      'reward',
      v_tinkus,
      'approved',
      'Cambio a rol socio',
      v_request.payment_id,
      v_request.payment_id
    );

  ELSIF v_request.type = 'coin_purchase' THEN
    IF v_request.target_id IS NULL THEN
      RAISE EXCEPTION 'Target ID required for coin purchase';
    END IF;

    SELECT tinkus_amount
    INTO v_tinkus
    FROM coin_packages
    WHERE id = v_request.target_id;

    IF v_tinkus IS NULL THEN
      RAISE EXCEPTION 'Invalid coin package';
    END IF;

    INSERT INTO wallets (user_id, balance)
    VALUES (v_request.user_id, 0)
    ON CONFLICT (user_id) DO NOTHING;

    PERFORM apply_transaction(
      v_request.user_id,
      'reward',
      v_tinkus,
      'approved',
      'Compra de monedas',
      v_request.payment_id,
      v_request.payment_id
    );

  ELSIF v_request.type = 'subscription' THEN
    IF v_request.target_id IS NULL THEN
      RAISE EXCEPTION 'Target ID required for subscription';
    END IF;

    SELECT duration_months, included_tinku
    INTO v_duration, v_tinkus
    FROM subscription_plans
    WHERE id = v_request.target_id;

    IF v_duration IS NULL THEN
      RAISE EXCEPTION 'Invalid subscription plan';
    END IF;

    INSERT INTO user_subscriptions (
      user_id,
      plan_id,
      start_date,
      end_date,
      status
    )
    VALUES (
      v_request.user_id,
      v_request.target_id,
      NOW(),
      NOW() + (v_duration || ' months')::interval,
      'active'
    );

    IF v_tinkus IS NOT NULL AND v_tinkus > 0 THEN
      PERFORM apply_transaction(
        v_request.user_id,
        'reward',
        v_tinkus,
        'approved',
        'Beneficio de suscripcion',
        v_request.payment_id,
        v_request.payment_id
      );
    END IF;

  ELSE
    RAISE EXCEPTION 'Unsupported request type';
  END IF;

  UPDATE payment_requests
  SET status = 'approved',
      reviewed_by = p_system_user_id,
      reviewed_at = NOW(),
      comment = p_comment,
      updated_at = NOW()
  WHERE id = v_request.id;

  UPDATE payments
  SET status = 'approved',
      updated_at = NOW()
  WHERE id = v_payment.id;

  PERFORM write_audit_log(
    p_system_user_id,
    'stripe_payment_request_approved',
    'payment_request',
    v_request.id,
    jsonb_build_object(
      'payment_id', v_payment.id,
      'stripe_payment_intent_id', p_payment_intent_id,
      'user_id', v_request.user_id,
      'type', v_request.type,
      'target_id', v_request.target_id,
      'comment', p_comment
    )
  );
END;
$$;


CREATE OR REPLACE FUNCTION reject_payment_request(
  p_request_id bigint,
  p_admin_id uuid,
  p_comment text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_request RECORD;
  v_payment RECORD;
BEGIN

  IF current_app_user_id() IS NULL OR NOT is_admin() THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  SELECT *
  INTO v_request
  FROM payment_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Request not found';
  END IF;

  IF v_request.status = 'rejected' THEN
    RETURN;
  END IF;

  IF v_request.status <> 'pending' THEN
    RAISE EXCEPTION 'Request already processed';
  END IF;

  SELECT *
  INTO v_payment
  FROM payments
  WHERE id = v_request.payment_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payment not found';
  END IF;

  IF v_payment.status <> 'pending' THEN
    RAISE EXCEPTION 'Payment already processed';
  END IF;

  UPDATE payment_requests
  SET status = 'rejected',
      reviewed_by = p_admin_id,
      reviewed_at = NOW(),
      comment = p_comment,
      updated_at = NOW()
  WHERE id = v_request.id;

  UPDATE payments
  SET status = 'rejected',
      updated_at = NOW()
  WHERE id = v_payment.id;

  PERFORM write_audit_log(
    p_admin_id,
    'payment_request_rejected',
    'payment_request',
    v_request.id,
    jsonb_build_object(
      'payment_id', v_payment.id,
      'user_id', v_request.user_id,
      'type', v_request.type,
      'target_id', v_request.target_id,
      'comment', p_comment
    )
  );

END;
$$;

ALTER FUNCTION approve_payment_request(bigint, uuid, text) OWNER TO postgres;
ALTER FUNCTION reject_payment_request(bigint, uuid, text) OWNER TO postgres;

GRANT EXECUTE ON FUNCTION approve_payment_request(bigint, uuid, text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION reject_payment_request(bigint, uuid, text) TO PUBLIC;

-- =========================
-- MANEJO DE TINKUS
-- =========================
CREATE OR REPLACE FUNCTION perform_tinku_spend(
  p_user_id uuid,
  p_amount numeric,
  p_purpose text,
  p_reference_id bigint DEFAULT NULL,
  p_description text DEFAULT NULL
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_wallet RECORD;
  v_tx_id bigint;
BEGIN

  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be greater than zero';
  END IF;

  -- 🔒 lock wallet
  SELECT *
  INTO v_wallet
  FROM wallets
  WHERE user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Wallet not found';
  END IF;

  IF v_wallet.balance < p_amount THEN
    RAISE EXCEPTION 'Insufficient balance';
  END IF;

  -- 💰 descontar
  UPDATE wallets
  SET balance = balance - p_amount,
      updated_at = NOW()
  WHERE user_id = p_user_id;

  -- 🧾 registrar tx
  INSERT INTO financial_transactions(
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
    p_user_id,
    'spend',
    p_amount,
    'TINKU',
    p_purpose,
    p_reference_id,
    'approved',
    COALESCE(p_description, 'Tinku spend'),
    NOW()
  )
  RETURNING id INTO v_tx_id;

  RETURN v_tx_id;

END;
$$;

ALTER FUNCTION perform_tinku_spend(uuid, numeric, text, bigint, text)
OWNER TO postgres;

GRANT EXECUTE ON FUNCTION perform_tinku_spend(uuid, numeric, text, bigint, text)
TO PUBLIC;

CREATE OR REPLACE FUNCTION reverse_tinku_charge(
  p_tx_id bigint,
  p_reason text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tx RECORD;
BEGIN

  -- 🔒 lock tx
  SELECT *
  INTO v_tx
  FROM financial_transactions
  WHERE id = p_tx_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaction not found';
  END IF;

  IF v_tx.status <> 'approved' THEN
    RAISE EXCEPTION 'Only approved transactions can be reversed';
  END IF;

  IF v_tx.type <> 'spend' THEN
    RAISE EXCEPTION 'Only spend transactions can be reversed';
  END IF;

  -- 💰 devolver dinero
  UPDATE wallets
  SET balance = balance + v_tx.amount,
      updated_at = NOW()
  WHERE user_id = v_tx.user_id;

  -- 🔁 marcar reverso
  UPDATE financial_transactions
  SET status = 'reversed',
      description = COALESCE(p_reason, 'Charge reversed'),
      updated_at = NOW()
  WHERE id = v_tx.id;

END;
$$;

ALTER FUNCTION reverse_tinku_charge(bigint, text)
OWNER TO postgres;

GRANT EXECUTE ON FUNCTION reverse_tinku_charge(bigint, text)
TO PUBLIC;

-- =========================
-- EVENTS
-- =========================
CREATE OR REPLACE FUNCTION create_event_with_charge(
  p_user_id uuid,
  p_business_id int,
  p_category_id int,
  p_name text,
  p_description text,
  p_start_date timestamptz,
  p_end_date timestamptz,
  p_capacity int,
  p_tinku_price int,
  p_address text,
  p_lat double precision,
  p_lng double precision
)
RETURNS TABLE (
  id bigint,
  business_id bigint,
  creator_id uuid,
  category_id bigint,
  name text,
  description text,
  start_date timestamp,
  end_date timestamp,
  capacity int,
  tinku_price int,
  address text,
  latitude double precision,
  longitude double precision,
  status text,
  created_at timestamp,
  updated_at timestamp
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cost numeric;
  v_event events;
BEGIN

  -- 🔒 seguridad
  IF current_app_user_id() IS NULL OR p_user_id <> current_app_user_id() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- 💸 costo desde config
  SELECT value::numeric
  INTO v_cost
  FROM system_config
  WHERE key = 'event_create_cost';

  IF v_cost IS NULL THEN
    RAISE EXCEPTION 'Event cost not configured';
  END IF;

  -- 🚀 crear evento
  INSERT INTO events(
    business_id,
    creator_id,
    category_id,
    name,
    description,
    start_date,
    end_date,
    capacity,
    tinku_price,
    address,
    location,
    status
  )
  VALUES (
    p_business_id,
    p_user_id,
    p_category_id,
    p_name,
    p_description,
    p_start_date,
    p_end_date,
    p_capacity,
    p_tinku_price,
    p_address,
    ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
    'pending'
  )
  RETURNING * INTO v_event;

  -- 💥 cobrar (si falla → rollback total)
  PERFORM perform_tinku_spend(
    p_user_id,
    v_cost,
    'event_creation',
    v_event.id,
    'Creación de evento'
  );

  PERFORM write_audit_log(
    p_user_id,
    'event_created_with_charge',
    'event',
    v_event.id,
    jsonb_build_object(
      'business_id', p_business_id,
      'category_id', p_category_id,
      'cost', v_cost
    )
  );

  RETURN QUERY
  SELECT
    e.id,
    e.business_id,
    e.creator_id,
    e.category_id,
    e.name::text,
    e.description,
    e.start_date,
    e.end_date,
    e.capacity,
    e.tinku_price,
    e.address::text,
    ST_Y(e.location::geometry) AS latitude,
    ST_X(e.location::geometry) AS longitude,
    e.status::text,
    e.created_at,
    e.updated_at
  FROM events e
  WHERE e.id = v_event.id;

END;
$$;

GRANT EXECUTE ON FUNCTION create_event_with_charge(
  uuid, int, int, text, text, timestamptz, timestamptz, int, int, text, double precision, double precision
) TO PUBLIC;

-- ==========================
-- BUSINESS 
-- ==========================
CREATE OR REPLACE FUNCTION create_business_with_charge(
  p_user_id uuid,
  p_category_id int,
  p_name text,
  p_nit text,
  p_description text,
  p_phone text,
  p_email text,
  p_business_type business_type,
  p_address text,
  p_lat double precision,
  p_lng double precision,
  p_website text
)
RETURNS businesses
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cost numeric;
  v_business businesses;
BEGIN

  -- 🔒 seguridad
  IF current_app_user_id() IS NULL OR p_user_id <> current_app_user_id() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- 💸 costo desde config
  SELECT value::numeric
  INTO v_cost
  FROM system_config
  WHERE key = 'business_create_cost';

  IF v_cost IS NULL THEN
    RAISE EXCEPTION 'Business cost not configured';
  END IF;

  -- 🚀 crear business (PENDING + NO VALIDATED)
  INSERT INTO businesses(
    category_id,
    owner_id,
    name,
    nit,
    description,
    phone,
    email,
    business_type,
    address,
    location,
    website,
    status,
    validated
  )
  VALUES (
    p_category_id,
    p_user_id,
    p_name,
    p_nit,
    p_description,
    p_phone,
    p_email,
    p_business_type,
    p_address,
    ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
    p_website,
    'pending',
    false
  )
  RETURNING * INTO v_business;

  -- 💥 cobrar (rollback si falla)
  PERFORM perform_tinku_spend(
    p_user_id,
    v_cost,
    'business_creation',
    v_business.id,
    'Creación de negocio'
  );

  PERFORM write_audit_log(
    p_user_id,
    'business_created_with_charge',
    'business',
    v_business.id,
    jsonb_build_object(
      'category_id', p_category_id,
      'business_type', p_business_type,
      'cost', v_cost
    )
  );

  RETURN v_business;

END;
$$;

GRANT EXECUTE ON FUNCTION create_business_with_charge(
  uuid, int, text, text, text, text, text, business_type, text, double precision, double precision, text
) TO PUBLIC;

-- =========================
-- WAREHOUSES
-- =========================
CREATE OR REPLACE FUNCTION create_warehouse_with_charge(
  p_user_id uuid,
  p_name text,
  p_description text DEFAULT NULL,
  p_phone text DEFAULT NULL,
  p_email text DEFAULT NULL,
  p_address text DEFAULT NULL,
  p_lat double precision DEFAULT NULL,
  p_lng double precision DEFAULT NULL
)
RETURNS warehouses
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cost numeric;
  v_warehouse warehouses;
BEGIN
  IF current_app_user_id() IS NULL OR p_user_id <> current_app_user_id() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT value::numeric
  INTO v_cost
  FROM system_config
  WHERE key = 'business_create_cost';

  IF v_cost IS NULL THEN
    RAISE EXCEPTION 'Business cost not configured';
  END IF;

  INSERT INTO warehouses(
    owner_id,
    name,
    description,
    phone,
    email,
    address,
    location,
    validated,
    status
  )
  VALUES (
    p_user_id,
    p_name,
    p_description,
    p_phone,
    p_email,
    p_address,
    CASE
      WHEN p_lat IS NULL OR p_lng IS NULL THEN NULL
      ELSE ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
    END,
    false,
    'pending'
  )
  RETURNING * INTO v_warehouse;

  PERFORM perform_tinku_spend(
    p_user_id,
    v_cost,
    'warehouse_creation',
    v_warehouse.id,
    'Creación de almacén'
  );

  PERFORM write_audit_log(
    p_user_id,
    'warehouse_created_with_charge',
    'warehouse',
    v_warehouse.id,
    jsonb_build_object(
      'cost', v_cost
    )
  );

  RETURN v_warehouse;
END;
$$;

ALTER FUNCTION create_warehouse_with_charge(uuid, text, text, text, text, text, double precision, double precision)
OWNER TO postgres;

GRANT EXECUTE ON FUNCTION create_warehouse_with_charge(
  uuid, text, text, text, text, text, double precision, double precision
) TO PUBLIC;

-- ==========================
-- DISCOUNTS 
-- ==========================
CREATE OR REPLACE FUNCTION create_discount_with_charge(
  p_user_id uuid,
  p_business_id int,
  p_description text,
  p_discount_percent numeric,
  p_start_date timestamptz,
  p_end_date timestamptz,
  p_status promotion_status DEFAULT 'active'
)
RETURNS discounts
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cost_per_day numeric;
  v_days int;
  v_total numeric;
  v_discount discounts;
BEGIN
  -- 🔒 seguridad
  IF current_app_user_id() IS NULL OR p_user_id <> current_app_user_id() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- 📅 calcular días (mínimo 1)
  v_days := GREATEST(1, (p_end_date::date - p_start_date::date) + 1);

  -- 💰 costo por día
  SELECT value::numeric
  INTO v_cost_per_day
  FROM system_config
  WHERE key = 'discount_create_cost';

  IF v_cost_per_day IS NULL THEN
    RAISE EXCEPTION 'Discount cost not configured';
  END IF;

  -- 💸 total
  v_total := v_days * v_cost_per_day;

  -- 🚀 crear descuento
  INSERT INTO discounts(
    business_id,
    description,
    discount_percent,
    start_date,
    end_date,
    status
  )
  VALUES (
    p_business_id,
    p_description,
    p_discount_percent,
    p_start_date,
    p_end_date,
    p_status
  )
  RETURNING * INTO v_discount;

  -- 💥 cobrar
  PERFORM perform_tinku_spend(
    p_user_id,
    v_total,
    'discount_creation',
    v_discount.id,
    'Creación de promoción'
  );

  PERFORM write_audit_log(
    p_user_id,
    'discount_created_with_charge',
    'discount',
    v_discount.id,
    jsonb_build_object(
      'business_id', p_business_id,
      'days', v_days,
      'cost', v_total
    )
  );

  RETURN v_discount;
END;
$$;

GRANT EXECUTE ON FUNCTION create_discount_with_charge(
  uuid, int, text, numeric, timestamptz, timestamptz, promotion_status
) TO PUBLIC;

-- =========================
-- BOOSTS
-- ==========================
CREATE OR REPLACE FUNCTION create_boost_with_charge(
  p_user_id uuid,
  p_entity_type visit_entity,
  p_entity_id int,
  p_start_date timestamptz,
  p_end_date timestamptz
)
RETURNS boosts
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cost_per_day numeric;
  v_days int;
  v_total numeric;
  v_boost boosts;
BEGIN

  -- 🔒 seguridad
  IF current_app_user_id() IS NULL OR p_user_id <> current_app_user_id() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- 📅 calcular días (mínimo 1)
  v_days := GREATEST(1, (p_end_date::date - p_start_date::date) + 1);

  -- 💰 costo por día
  SELECT value::numeric
  INTO v_cost_per_day
  FROM system_config
  WHERE key = 'boost_create_cost';

  IF v_cost_per_day IS NULL THEN
    RAISE EXCEPTION 'Boost cost not configured';
  END IF;

  -- 💸 total
  v_total := v_days * v_cost_per_day;

  -- 🚀 crear boost
  INSERT INTO boosts(
    entity_type,
    entity_id,
    start_date,
    end_date,
    status
  )
  VALUES (
    p_entity_type,
    p_entity_id,
    p_start_date,
    p_end_date,
    'active'
  )
  RETURNING * INTO v_boost;

  -- 💥 cobrar (igual que business)
  PERFORM perform_tinku_spend(
    p_user_id,
    v_total,
    'boost_creation',
    v_boost.id,
    'Creación de un impulso'
  );

  PERFORM write_audit_log(
    p_user_id,
    'boost_created_with_charge',
    'boost',
    v_boost.id,
    jsonb_build_object(
      'entity_type', p_entity_type,
      'entity_id', p_entity_id,
      'days', v_days,
      'cost', v_total
    )
  );

  RETURN v_boost;

END;
$$;

GRANT EXECUTE ON FUNCTION create_boost_with_charge(
  uuid, visit_entity, int, timestamptz, timestamptz
) TO PUBLIC;
-- ==========================
-- ENTITY UPDATES 
-- ==========================
CREATE OR REPLACE FUNCTION approve_business_update(
  p_update_id BIGINT,
  p_admin_id UUID,
  p_comment TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_update RECORD;
BEGIN

  SELECT *
  INTO v_update
  FROM entity_updates
  WHERE id = p_update_id
    AND entity_type = 'business'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Update not found';
  END IF;

  IF v_update.status <> 'pending' THEN
    RAISE EXCEPTION 'Already processed';
  END IF;

  UPDATE businesses
  SET
    category_id = COALESCE((v_update.data->>'category_id')::int, category_id),
    name = COALESCE(v_update.data->>'name', name),
    nit = COALESCE(v_update.data->>'nit', nit),
    description = COALESCE(v_update.data->>'description', description),
    phone = COALESCE(v_update.data->>'phone', phone),
    email = COALESCE(v_update.data->>'email', email),
    business_type = COALESCE((v_update.data->>'business_type')::business_type, business_type),
    address = COALESCE(v_update.data->>'address', address),
    website = COALESCE(v_update.data->>'website', website),

    location = COALESCE(
      CASE
        WHEN v_update.data ? 'location' THEN
          ST_SetSRID(
            ST_MakePoint(
              (v_update.data->'location'->'coordinates'->>0)::float,
              (v_update.data->'location'->'coordinates'->>1)::float
            ),
            4326
          )::geography
        ELSE NULL
      END,
      location
    ),

    updated_at = NOW()

  WHERE id = v_update.entity_id;

  UPDATE entity_updates
  SET
    status = 'approved',
    reviewed_by = p_admin_id,
    reviewed_at = NOW(),
    comment = p_comment
  WHERE id = v_update.id;

END;
$$;


CREATE OR REPLACE FUNCTION approve_event_update(
  p_update_id bigint,
  p_admin_id uuid,
  p_comment text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_update RECORD;
  v_event RECORD;
  v_start_date timestamptz;
  v_end_date timestamptz;
BEGIN

  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT *
  INTO v_update
  FROM entity_updates
  WHERE id = p_update_id
    AND entity_type = 'event'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Update not found';
  END IF;

  IF v_update.status <> 'pending' THEN
    RAISE EXCEPTION 'Already processed';
  END IF;

  SELECT *
  INTO v_event
  FROM events
  WHERE id = v_update.entity_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event not found';
  END IF;

  v_start_date := COALESCE(
    (v_update.data->>'start_date')::timestamptz,
    v_event.start_date
  );
  v_end_date := COALESCE(
    (v_update.data->>'end_date')::timestamptz,
    v_event.end_date
  );

  IF v_update.data ? 'start_date' OR v_update.data ? 'end_date' THEN
    IF v_end_date < NOW() THEN
      RAISE EXCEPTION 'La fecha y hora de fin no puede estar en el pasado';
    END IF;

    IF v_end_date <= v_start_date THEN
      RAISE EXCEPTION 'La fecha de fin debe ser posterior al inicio';
    END IF;

    IF v_end_date - v_start_date < INTERVAL '30 minutes' THEN
      RAISE EXCEPTION 'El evento debe durar al menos 30 minutos';
    END IF;
  END IF;

  UPDATE events
  SET
    name = COALESCE(v_update.data->>'name', name),
    description = COALESCE(v_update.data->>'description', description),
    start_date = v_start_date,
    end_date = v_end_date,
    capacity = COALESCE((v_update.data->>'capacity')::int, capacity),
    address = COALESCE(v_update.data->>'address', address),
    tinku_price = COALESCE((v_update.data->>'tinku_price')::int, tinku_price),
    business_id = COALESCE((v_update.data->>'business_id')::int, business_id),

    location = COALESCE(
      CASE
        WHEN v_update.data ? 'location' THEN
          ST_SetSRID(
            ST_MakePoint(
              (v_update.data->'location'->'coordinates'->>0)::float,
              (v_update.data->'location'->'coordinates'->>1)::float
            ),
            4326
          )
        ELSE NULL
      END,
      location
    ),

    updated_at = NOW()

  WHERE id = v_update.entity_id;

  UPDATE entity_updates
  SET
    status = 'approved',
    reviewed_by = p_admin_id,
    reviewed_at = NOW(),
    comment = p_comment
  WHERE id = v_update.id;

END;
$$;


CREATE OR REPLACE FUNCTION reject_entity_update(
  p_update_id bigint,
  p_admin_id uuid,
  p_comment text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_update RECORD;
BEGIN

  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT *
  INTO v_update
  FROM entity_updates
  WHERE id = p_update_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Update not found';
  END IF;

  IF v_update.status <> 'pending' THEN
    RAISE EXCEPTION 'Already processed';
  END IF;

  UPDATE entity_updates
  SET
    status = 'rejected',
    reviewed_by = p_admin_id,
    reviewed_at = NOW(),
    comment = p_comment
  WHERE id = v_update.id;

END;
$$;

GRANT EXECUTE ON FUNCTION approve_business_update(bigint, uuid, text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION approve_event_update(bigint, uuid, text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION reject_entity_update(bigint, uuid, text) TO PUBLIC;

-- ==========================
-- NEARBY ENTITIES
-- ==========================
CREATE OR REPLACE FUNCTION public.get_nearby_entities(
  user_lat double precision,
  user_lng double precision,
  radius_meters integer
)
RETURNS TABLE (
  entity_id bigint,
  entity_type text,
  name text,
  latitude double precision,
  longitude double precision,
  distance double precision,
  image_url text
)
LANGUAGE sql
STABLE
AS $$
WITH user_location AS (
  SELECT ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography AS p
)

-- BUSINESS
SELECT
  b.id AS entity_id,
  'business' AS entity_type,
  b.name,
  ST_Y(b.location::geometry) AS latitude,
  ST_X(b.location::geometry) AS longitude,
  ST_Distance(b.location::geography, u.p) AS distance,
  m.url AS image_url
FROM businesses b
CROSS JOIN user_location u
LEFT JOIN LATERAL (
  SELECT md.url
  FROM media md
  WHERE md.entity_type = 'business'
    AND md.entity_id = b.id::text
  ORDER BY md.is_primary DESC, md.id ASC
  LIMIT 1
) m ON TRUE
WHERE b.status = 'active'
  AND b.location IS NOT NULL
  AND ST_DWithin(b.location::geography, u.p, radius_meters)

UNION ALL

-- TOURIST PLACES
SELECT
  t.id AS entity_id,
  'tourist_place' AS entity_type,
  t.name,
  ST_Y(t.location::geometry) AS latitude,
  ST_X(t.location::geometry) AS longitude,
  ST_Distance(t.location::geography, u.p) AS distance,
  m.url AS image_url
FROM tourist_places t
CROSS JOIN user_location u
LEFT JOIN LATERAL (
  SELECT md.url
  FROM media md
  WHERE md.entity_type = 'tourist_place'
    AND md.entity_id = t.id::text
  ORDER BY md.is_primary DESC, md.id ASC
  LIMIT 1
) m ON TRUE
WHERE t.status = 'active'
  AND t.location IS NOT NULL
  AND ST_DWithin(t.location::geography, u.p, radius_meters)

UNION ALL

-- EVENTS
SELECT
  e.id AS entity_id,
  'event' AS entity_type,
  e.name,
  ST_Y(e.location::geometry) AS latitude,
  ST_X(e.location::geometry) AS longitude,
  ST_Distance(e.location::geography, u.p) AS distance,
  m.url AS image_url
FROM events e
CROSS JOIN user_location u
LEFT JOIN LATERAL (
  SELECT md.url
  FROM media md
  WHERE md.entity_type = 'event'
    AND md.entity_id = e.id::text
  ORDER BY md.is_primary DESC, md.id ASC
  LIMIT 1
) m ON TRUE
WHERE e.status = 'active'
  AND e.location IS NOT NULL
  AND ST_DWithin(e.location::geography, u.p, radius_meters)

ORDER BY distance ASC;
$$;

-- =========================
-- TRANSPORT AUTO RELATIONS
-- =========================

CREATE OR REPLACE FUNCTION refresh_entity_transport_relations(
  p_entity_type visit_entity,
  p_entity_id bigint,
  p_lat double precision,
  p_lng double precision,
  p_radius_m integer DEFAULT 1000
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  affected integer := 0;
BEGIN
  DELETE FROM entity_transport_relations
  WHERE entity_type = p_entity_type
    AND entity_id = p_entity_id
    AND source = 'auto';

  WITH entity_point AS (
    SELECT ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography AS point
  ),
  route_shapes AS (
    SELECT
      tr.transport_line_id,
      tr.direction,
      ST_MakeLine(tr.location::geometry ORDER BY tr.stop_order)::geography AS path
    FROM transport_routes tr
    JOIN transport_lines tl ON tl.id = tr.transport_line_id
    WHERE tl.status = 'active'
    GROUP BY tr.transport_line_id, tr.direction
    HAVING COUNT(*) >= 2
  ),
  nearby_candidates AS (
    SELECT rs.transport_line_id, ST_Distance(rs.path, ep.point) AS distance_m
    FROM route_shapes rs
    CROSS JOIN entity_point ep
    WHERE ST_DWithin(rs.path, ep.point, p_radius_m)
    UNION ALL
    SELECT tr.transport_line_id, ST_Distance(tr.location, ep.point) AS distance_m
    FROM transport_routes tr
    JOIN transport_lines tl ON tl.id = tr.transport_line_id
    CROSS JOIN entity_point ep
    WHERE tl.status = 'active'
      AND ST_DWithin(tr.location, ep.point, p_radius_m)
  ),
  nearby_lines AS (
    SELECT transport_line_id, MIN(distance_m)::integer AS distance_m
    FROM nearby_candidates
    GROUP BY transport_line_id
  )
  INSERT INTO entity_transport_relations (
    entity_type,
    entity_id,
    transport_line_id,
    distance_m,
    radius_m,
    source,
    computed_at
  )
  SELECT
    p_entity_type,
    p_entity_id,
    transport_line_id,
    distance_m,
    p_radius_m,
    'auto',
    CURRENT_TIMESTAMP
  FROM nearby_lines
  ON CONFLICT (entity_type, entity_id, transport_line_id)
  DO UPDATE SET
    distance_m = EXCLUDED.distance_m,
    radius_m = EXCLUDED.radius_m,
    source = EXCLUDED.source,
    computed_at = EXCLUDED.computed_at;

  GET DIAGNOSTICS affected = ROW_COUNT;
  RETURN affected;
END;
$$;

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

-- =========================
-- MARKETPLACE / WAREHOUSES
-- =========================

CREATE OR REPLACE FUNCTION calculate_product_publication_cost(
  p_stock int,
  p_unit_price numeric DEFAULT 0,
  p_unit_tinku_price numeric DEFAULT 0
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
  v_effective_price numeric := 0;
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

  v_effective_price := GREATEST(
    COALESCE(p_unit_price, 0),
    COALESCE(p_unit_tinku_price, 0),
    0
  );

  RETURN CEIL(v_base + (p_stock * v_stock_unit) + (v_effective_price * p_stock * v_price_rate))::int;
END;
$$;

CREATE OR REPLACE FUNCTION create_product_publication_with_charge(
  p_user_id uuid,
  p_product_id bigint,
  p_published_stock int,
  p_unit_price numeric DEFAULT NULL,
  p_unit_tinku_price int DEFAULT NULL,
  p_payment_mode text DEFAULT NULL
)
RETURNS product_publications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_product products%ROWTYPE;
  v_business businesses%ROWTYPE;
  v_unit_tinku_price int;
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

  IF p_unit_price IS NOT NULL
     OR COALESCE(NULLIF(TRIM(p_payment_mode), ''), 'tinkus') <> 'tinkus' THEN
    RAISE EXCEPTION 'Marketplace publications only support Tinkus';
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

  IF NOT v_business.validated OR v_business.status <> 'active' THEN
    RAISE EXCEPTION 'Business must be approved to publish products';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM product_publications
    WHERE product_id = p_product_id
      AND status <> 'archived'
  ) THEN
    RAISE EXCEPTION 'Product already has an open publication';
  END IF;

  v_unit_tinku_price := COALESCE(p_unit_tinku_price, v_product.tinku_price::int);

  IF v_unit_tinku_price IS NULL OR v_unit_tinku_price <= 0 THEN
    RAISE EXCEPTION 'Tinku price is required';
  END IF;

  UPDATE products
  SET
    tinku_price = v_unit_tinku_price,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = v_product.id;

  v_cost := calculate_product_publication_cost(
    p_published_stock,
    0,
    v_unit_tinku_price
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
    payment_mode,
    calculated_cost_tinkus,
    charged_tinkus,
    status
  )
  VALUES (
    v_product.id,
    v_product.business_id,
    p_user_id,
    p_published_stock,
    NULL,
    v_unit_tinku_price,
    'tinkus',
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
  p_published_stock int,
  p_unit_price numeric DEFAULT NULL,
  p_unit_tinku_price int DEFAULT NULL,
  p_payment_mode text DEFAULT NULL
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
  v_unit_tinku_price int;
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

  IF p_unit_price IS NOT NULL
     OR COALESCE(NULLIF(TRIM(p_payment_mode), ''), 'tinkus') <> 'tinkus' THEN
    RAISE EXCEPTION 'Marketplace publications only support Tinkus';
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

  IF NOT v_business.validated OR v_business.status <> 'active' THEN
    RAISE EXCEPTION 'Business must be approved to publish products';
  END IF;

  v_unit_tinku_price := COALESCE(p_unit_tinku_price, v_publication.unit_tinku_price, v_product.tinku_price::int);

  IF v_unit_tinku_price IS NULL OR v_unit_tinku_price <= 0 THEN
    RAISE EXCEPTION 'Tinku price is required';
  END IF;

  UPDATE products
  SET
    tinku_price = v_unit_tinku_price,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = v_product.id;

  v_new_cost := calculate_product_publication_cost(
    p_published_stock,
    0,
    v_unit_tinku_price
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
    unit_price = NULL,
    unit_tinku_price = v_unit_tinku_price,
    payment_mode = 'tinkus',
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

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Marketplace order not found';
  END IF;

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

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Marketplace seller wallet not found';
  END IF;

  INSERT INTO financial_transactions (
    user_id, type, amount, currency, purpose, reference_id,
    status, description, created_at
  ) VALUES (
    v_order.seller_id, 'reward', v_order.seller_amount_tinkus, 'TINKU',
    'marketplace_sale', v_order.id, 'approved',
    'Venta marketplace #' || v_order.id || ' entregada', CURRENT_TIMESTAMP
  )
  RETURNING id INTO v_tx_id;

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

ALTER FUNCTION calculate_product_publication_cost(int, numeric, numeric) OWNER TO postgres;
ALTER FUNCTION create_product_publication_with_charge(uuid, bigint, int, numeric, int, text) OWNER TO postgres;
ALTER FUNCTION update_product_publication_with_charge(uuid, bigint, int, numeric, int, text) OWNER TO postgres;
ALTER FUNCTION reward_warehouse_delivery(bigint) OWNER TO postgres;
ALTER FUNCTION register_business_view(bigint) OWNER TO postgres;

GRANT EXECUTE ON FUNCTION calculate_product_publication_cost(int, numeric, numeric) TO PUBLIC;
GRANT EXECUTE ON FUNCTION create_product_publication_with_charge(uuid, bigint, int, numeric, int, text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION update_product_publication_with_charge(uuid, bigint, int, numeric, int, text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION reward_warehouse_delivery(bigint) TO PUBLIC;
GRANT EXECUTE ON FUNCTION register_business_view(bigint) TO PUBLIC;

CREATE OR REPLACE FUNCTION refresh_all_entity_transport_relations(
  p_radius_m integer DEFAULT 1000
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  item record;
  affected integer := 0;
BEGIN
  FOR item IN
    SELECT
      'business'::visit_entity AS entity_type,
      id AS entity_id,
      ST_Y(location::geometry) AS lat,
      ST_X(location::geometry) AS lng
    FROM businesses
    WHERE location IS NOT NULL
      AND status IN ('active', 'pending')

    UNION ALL

    SELECT
      'event'::visit_entity AS entity_type,
      id AS entity_id,
      ST_Y(location::geometry) AS lat,
      ST_X(location::geometry) AS lng
    FROM events
    WHERE location IS NOT NULL
      AND status IN ('active', 'pending')

    UNION ALL

    SELECT
      'tourist_place'::visit_entity AS entity_type,
      id AS entity_id,
      ST_Y(location::geometry) AS lat,
      ST_X(location::geometry) AS lng
    FROM tourist_places
    WHERE location IS NOT NULL
      AND status IN ('active', 'inactive')
  LOOP
    affected := affected + refresh_entity_transport_relations(
      item.entity_type,
      item.entity_id,
      item.lat,
      item.lng,
      p_radius_m
    );
  END LOOP;

  RETURN affected;
END;
$$;
