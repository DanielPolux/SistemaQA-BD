-- =============================================================
-- SCRIPT 21: username para login (independiente del email)
-- El email se conserva obligatorio para notificaciones; el login
-- pasa a hacerse por "username".
-- =============================================================

ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS username VARCHAR(50);

-- Backfill para usuarios ya existentes: nombre + apellido, sin acentos,
-- espacios ni símbolos (solo letras y números), en minúsculas.
-- Si el resultado colisiona con uno ya asignado, se le agrega un
-- sufijo numérico (juanperez, juanperez2, juanperez3, ...).
DO $$
DECLARE
  r RECORD;
  base_slug TEXT;
  candidate TEXT;
  suffix INT;
BEGIN
  FOR r IN SELECT id, nombre, apellido FROM usuarios WHERE username IS NULL ORDER BY id LOOP
    base_slug := lower(regexp_replace(
      translate(r.nombre || r.apellido,
        'áéíóúüñÁÉÍÓÚÜÑ',
        'aeiouunAEIOUUN'),
      '[^a-zA-Z0-9]', '', 'g'
    ));

    IF base_slug = '' THEN
      base_slug := 'usuario' || r.id;
    END IF;

    candidate := base_slug;
    suffix := 1;
    WHILE EXISTS (SELECT 1 FROM usuarios WHERE username = candidate) LOOP
      suffix := suffix + 1;
      candidate := base_slug || suffix;
    END LOOP;

    UPDATE usuarios SET username = candidate WHERE id = r.id;
  END LOOP;
END $$;

ALTER TABLE usuarios ALTER COLUMN username SET NOT NULL;
ALTER TABLE usuarios ADD CONSTRAINT uq_usuarios_username UNIQUE (username);

CREATE INDEX IF NOT EXISTS idx_usuarios_username
  ON usuarios(username);

COMMENT ON COLUMN usuarios.username IS 'Usuario de acceso (login). Independiente del email, que se conserva para notificaciones.';
