ALTER TABLE ejecuciones_caso_prueba
  ADD COLUMN IF NOT EXISTS bloqueado_por_caso_id INTEGER
  REFERENCES casos_prueba(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_ejecuciones_bloqueado_por_caso
  ON ejecuciones_caso_prueba(bloqueado_por_caso_id);
