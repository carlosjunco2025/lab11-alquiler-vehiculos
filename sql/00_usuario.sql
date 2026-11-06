-- =====================================================================
-- Laboratorio 11 - Usuario de aplicación
-- Se ejecuta como root (Docker lo hace automáticamente al inicializar).
-- lab11_user solo tiene permisos sobre las tres bases del laboratorio.
-- =====================================================================

CREATE USER IF NOT EXISTS 'lab11_user'@'localhost' IDENTIFIED BY 'lab11_pass';
CREATE USER IF NOT EXISTS 'lab11_user'@'%'         IDENTIFIED BY 'lab11_pass';

-- Si el usuario ya existía, nos aseguramos de dejar la clave de desarrollo.
ALTER USER 'lab11_user'@'localhost' IDENTIFIED BY 'lab11_pass';
ALTER USER 'lab11_user'@'%'         IDENTIFIED BY 'lab11_pass';

GRANT ALL PRIVILEGES ON bd_cliente.*  TO 'lab11_user'@'localhost';
GRANT ALL PRIVILEGES ON bd_vehiculo.* TO 'lab11_user'@'localhost';
GRANT ALL PRIVILEGES ON bd_alquiler.* TO 'lab11_user'@'localhost';

GRANT ALL PRIVILEGES ON bd_cliente.*  TO 'lab11_user'@'%';
GRANT ALL PRIVILEGES ON bd_vehiculo.* TO 'lab11_user'@'%';
GRANT ALL PRIVILEGES ON bd_alquiler.* TO 'lab11_user'@'%';

FLUSH PRIVILEGES;
