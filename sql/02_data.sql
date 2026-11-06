-- =====================================================================
-- Laboratorio 11 - Datos de prueba
-- 5 clientes, 5 vehículos (uno EN MANTENIMIENTO) y 3 alquileres.
-- Los importes respetan: importe = días * tarifa_diaria.
-- =====================================================================

USE bd_cliente;

INSERT IGNORE INTO cliente (id, nombres, apellidos, documento, correo, telefono, estado) VALUES
  (1, 'Juan',   'Pérez',    '12345678', 'juan.perez@example.com',    '987654321', 'ACTIVO'),
  (2, 'María',  'Torres',   '23456789', 'maria.torres@example.com',  '987654322', 'ACTIVO'),
  (3, 'Luis',   'Gómez',    '34567890', 'luis.gomez@example.com',    '987654323', 'ACTIVO'),
  (4, 'Ana',    'Ramírez',  '45678901', 'ana.ramirez@example.com',   '987654324', 'INACTIVO'),
  (5, 'Pedro',  'Castillo', '56789012', 'pedro.castillo@example.com','987654325', 'ACTIVO');

USE bd_vehiculo;

INSERT IGNORE INTO vehiculo (id, placa, marca, modelo, anio, tarifa_diaria, estado) VALUES
  (1, 'ABC-123', 'Toyota',    'Corolla', 2022, 120.00, 'DISPONIBLE'),
  (2, 'DEF-456', 'Hyundai',   'Tucson',  2023, 180.00, 'DISPONIBLE'),
  (3, 'GHI-789', 'Kia',       'Rio',     2021, 100.00, 'ALQUILADO'),
  (4, 'JKL-012', 'Nissan',    'Sentra',  2020, 110.00, 'DISPONIBLE'),
  (5, 'MNO-345', 'Chevrolet', 'Spark',   2019,  80.00, 'MANTENIMIENTO');

USE bd_alquiler;

-- Alquiler 1: 2026-09-01 a 2026-09-04 -> 3 días * 120.00 = 360.00
-- Alquiler 2: 2026-09-10 a 2026-09-12 -> 2 días * 180.00 = 360.00
-- Alquiler 3: 2026-11-01 a 2026-11-06 -> 5 días * 100.00 = 500.00 (ACTIVO)
INSERT IGNORE INTO alquiler (id, id_cliente, id_vehiculo, fecha_inicio, fecha_fin, tarifa_diaria, importe_estimado, estado) VALUES
  (1, 1, 1, '2026-09-01', '2026-09-04', 120.00, 360.00, 'FINALIZADO'),
  (2, 2, 2, '2026-09-10', '2026-09-12', 180.00, 360.00, 'CANCELADO'),
  (3, 3, 3, '2026-11-01', '2026-11-06', 100.00, 500.00, 'ACTIVO');
