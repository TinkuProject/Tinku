-- Permite certificaciones sin numero de licencia.
-- Algunos registros pueden ser premios, reconocimientos o avales sin codigo formal.

ALTER TABLE certifications
  ALTER COLUMN license_number DROP NOT NULL;
