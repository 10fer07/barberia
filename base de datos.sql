-- ======================================================
-- SCRIPT COMPLETO: CREACIÓN DESDE CERO DE LAS TABLAS
-- barberos y citas para el sistema de gestión de citas
-- ======================================================

-- 1️⃣ Crear tabla de barberos
CREATE TABLE IF NOT EXISTS barberos (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre TEXT NOT NULL,
  usuario TEXT UNIQUE NOT NULL,
  contrasena TEXT NOT NULL,
  -- Días disponibles (cadena: "1,2,3" → 1=Lunes ... 7=Domingo)
  dias TEXT,
  horario_inicio TIME,
  horario_fin TIME
);

-- 2️⃣ Insertar barberos de ejemplo (no duplica si ya existe el usuario)
INSERT INTO barberos (nombre, usuario, contrasena, horario_inicio, horario_fin)
VALUES
  ('Juan', 'juan', '1234', '09:00', '18:00'),
  ('Pedro', 'pedro', '1234', '10:00', '17:00')
ON CONFLICT (usuario) DO NOTHING;

-- ======================================================
-- 3️⃣ Crear tabla de citas (referencia a auth.users y barberos)
-- ======================================================

CREATE TABLE IF NOT EXISTS citas (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  telefono TEXT NOT NULL,
  servicio TEXT NOT NULL,
  fecha DATE NOT NULL,
  hora TIME NOT NULL,
  barbero_id BIGINT REFERENCES barberos(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT now(),
  
  -- Restricción: minutos válidos = 00 o 30
  CONSTRAINT cita_hora_30min CHECK (date_part('minute', hora) IN (0, 30))
);

-- 4️⃣ Evitar reservas duplicadas exactas (barbero + fecha + hora)
CREATE UNIQUE INDEX IF NOT EXISTS idx_citas_barbero_fecha_hora
  ON citas (barbero_id, fecha, hora);

-- 5️⃣ Añadir columna `finalizada` si no existe
-- Esta columna permite marcar una cita como completada desde el panel del barbero.
-- Usamos un bloque DO/PLPGSQL que añade la columna sólo si no existe para evitar errores
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='citas' AND column_name='finalizada'
  ) THEN
    ALTER TABLE citas ADD COLUMN finalizada BOOLEAN DEFAULT false;
  END IF;
END$$;

-- ======================================================
-- 🔒 Opcional: Permisos básicos (si estás en Supabase)
-- ======================================================
-- (Puedes ajustar según roles)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON barberos, citas TO authenticated;
-- REVOKE ALL ON barberos, citas FROM anon;
