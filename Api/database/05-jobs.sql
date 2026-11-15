-- =========================
-- JOBS OPCIONALES
-- =========================
--
-- Requiere pg_cron instalado y habilitado en el servidor.
-- Si pg_cron no existe, este archivo no falla para permitir crear la base desde cero.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_namespace
    WHERE nspname = 'cron'
  ) THEN
    RAISE NOTICE 'pg_cron no esta disponible. Jobs no programados.';
    RETURN;
  END IF;

  PERFORM cron.schedule(
    'expire_boosts',
    '*/5 * * * *',
    $job$
    UPDATE boosts
    SET status = 'inactive'
    WHERE status = 'active'
    AND end_date::date < current_date;
    $job$
  );

  PERFORM cron.schedule(
    'expire_discounts',
    '*/5 * * * *',
    $job$
    UPDATE discounts
    SET status = 'inactive'
    WHERE status = 'active'
    AND end_date::date < current_date;
    $job$
  );

  PERFORM cron.schedule(
    'expire_events',
    '*/5 * * * *',
    $job$
    UPDATE events
    SET status = 'finished'
    WHERE status = 'active'
    AND end_date < CURRENT_TIMESTAMP;
    $job$
  );

  PERFORM cron.schedule(
    'cancel_reservations',
    '*/5 * * * *',
    $job$
    UPDATE reservations
    SET status = 'cancelled'
    WHERE status = 'pending'
    AND created_at < now() - interval '15 minutes';
    $job$
  );

  PERFORM cron.schedule(
    'expire_event_ticket_days',
    '*/5 * * * *',
    $job$
    UPDATE event_ticket_days
    SET status = 'expired',
        updated_at = now()
    WHERE status = 'active'
    AND valid_until < now();
    $job$
  );

  RAISE NOTICE 'Jobs pg_cron programados.';
END $$;
