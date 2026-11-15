-- Tokens FCM por usuario para notificaciones push en dispositivos moviles.

CREATE TABLE IF NOT EXISTS user_device_tokens (
  id bigserial PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token text NOT NULL UNIQUE,
  platform varchar(20),
  last_seen_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_device_tokens_user
  ON user_device_tokens(user_id);
