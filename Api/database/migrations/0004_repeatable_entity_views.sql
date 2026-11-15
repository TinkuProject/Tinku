-- Permite contar cada apertura real como vista, manteniendo favoritos únicos.
--
-- Antes user_visits tenia un índice único por user/entity/type, lo que hacía que
-- un usuario solo pudiera sumar una vista por negocio/evento/lugar. Para métricas
-- del dueño conviene contar aperturas repetidas, pero favoritos deben seguir
-- siendo únicos por usuario y entidad.

DROP INDEX IF EXISTS uniq_user_visit;

CREATE UNIQUE INDEX IF NOT EXISTS uniq_user_favorite
  ON user_visits(user_id, entity_type, entity_id)
  WHERE type = 'favorited';
