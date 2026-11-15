-- Keep public event visibility aligned with the exact event end timestamp.
UPDATE events
SET status = 'finished',
    updated_at = CURRENT_TIMESTAMP
WHERE status = 'active'
  AND end_date < CURRENT_TIMESTAMP;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'cron') THEN
    PERFORM cron.unschedule(jobid)
    FROM cron.job
    WHERE jobname = 'expire_events';

    PERFORM cron.schedule(
      'expire_events',
      '*/5 * * * *',
      $job$
      UPDATE events
      SET status = 'finished',
          updated_at = CURRENT_TIMESTAMP
      WHERE status = 'active'
        AND end_date < CURRENT_TIMESTAMP;
      $job$
    );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm') THEN
    RAISE EXCEPTION 'Required extension pg_trgm is not installed'
      USING HINT = 'Run CREATE EXTENSION IF NOT EXISTS pg_trgm as a PostgreSQL superuser, then retry npm run db:migrate.';
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_businesses_name_trgm
  ON businesses USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_events_name_trgm
  ON events USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_tourist_places_name_trgm
  ON tourist_places USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_products_name_trgm
  ON products USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_products_description_trgm
  ON products USING gin (description gin_trgm_ops);
