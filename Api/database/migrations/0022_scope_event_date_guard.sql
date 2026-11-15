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
