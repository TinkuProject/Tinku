DROP TRIGGER IF EXISTS trg_queue_notification_push ON notifications;
CREATE TRIGGER trg_queue_notification_push AFTER INSERT ON notifications
  FOR EACH ROW EXECUTE FUNCTION enqueue_notification_push();
DROP TRIGGER IF EXISTS trg_initialize_boost_paid_days ON boosts;
CREATE TRIGGER trg_initialize_boost_paid_days BEFORE INSERT ON boosts
  FOR EACH ROW EXECUTE FUNCTION initialize_boost_paid_days();
DROP TRIGGER IF EXISTS trg_guard_reservation_state ON reservations;
CREATE TRIGGER trg_guard_reservation_state BEFORE INSERT OR UPDATE ON reservations
  FOR EACH ROW EXECUTE FUNCTION guard_reservation_state();

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  target record;
BEGIN
  FOR target IN
    SELECT table_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND column_name = 'updated_at'
  LOOP
    IF NOT EXISTS (
      SELECT 1
      FROM pg_trigger trigger_row
      JOIN pg_class table_row ON table_row.oid = trigger_row.tgrelid
      JOIN pg_namespace schema_row ON schema_row.oid = table_row.relnamespace
      WHERE trigger_row.tgname = 'trg_set_updated_at'
        AND table_row.relname = target.table_name
        AND schema_row.nspname = 'public'
        AND NOT trigger_row.tgisinternal
    ) THEN
      EXECUTE format(
        'CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION set_updated_at()',
        target.table_name
      );
    END IF;
  END LOOP;
END $$;


CREATE OR REPLACE FUNCTION validate_event_update()
RETURNS trigger AS $$
DECLARE
  v_event RECORD;
BEGIN

  SELECT *
  INTO v_event
  FROM events
  WHERE id = NEW.event_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event not found';
  END IF;

  IF v_event.status IN ('cancelled', 'finished') THEN
    RAISE EXCEPTION 'Cannot update this event';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
