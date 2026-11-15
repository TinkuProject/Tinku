ALTER TABLE auth_verification_codes
  ADD COLUMN IF NOT EXISTS attempt_count int NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS max_attempts int NOT NULL DEFAULT 5,
  ADD COLUMN IF NOT EXISTS requested_ip varchar(64);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'auth_verification_codes_attempt_count_check'
  ) THEN
    ALTER TABLE auth_verification_codes
      ADD CONSTRAINT auth_verification_codes_attempt_count_check
      CHECK (attempt_count >= 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'auth_verification_codes_max_attempts_check'
  ) THEN
    ALTER TABLE auth_verification_codes
      ADD CONSTRAINT auth_verification_codes_max_attempts_check
      CHECK (max_attempts > 0);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_auth_codes_ip_rate
  ON auth_verification_codes(requested_ip, created_at DESC)
  WHERE requested_ip IS NOT NULL;

-- Conserva el acceso de cuentas creadas antes de habilitar el correo real.
UPDATE users
SET email_verified = true,
    updated_at = COALESCE(updated_at, CURRENT_TIMESTAMP)
WHERE google_sub IS NULL
  AND email_verified = false;
