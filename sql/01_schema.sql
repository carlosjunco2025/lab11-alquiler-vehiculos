-- =====================================================================
-- Laboratorio 11 - Esquema de las tres bases de datos
-- Cada microservicio tiene su propia base; NO hay llaves foráneas
-- entre bases. Las referencias se guardan únicamente como IDs.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS bd_cliente
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS bd_vehiculo
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS bd_alquiler
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- Base del microservicio ms-cliente
-- ---------------------------------------------------------------------
USE bd_cliente;

CREATE TABLE IF NOT EXISTS cliente (
  id         BIGINT       NOT NULL AUTO_INCREMENT,
  nombres    VARCHAR(100) NOT NULL,
  apellidos  VARCHAR(100) NOT NULL,
  documento  VARCHAR(8)   NOT NULL,
  correo     VARCHAR(150) NOT NULL,
  telefono   VARCHAR(9)   NOT NULL,
  estado     VARCHAR(20)  NOT NULL DEFAULT 'ACTIVO',
  PRIMARY KEY (id),
  UNIQUE KEY uk_cliente_documento (documento)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- Base del microservicio ms-vehiculo
-- ---------------------------------------------------------------------
USE bd_vehiculo;

CREATE TABLE IF NOT EXISTS vehiculo (
  id            BIGINT        NOT NULL AUTO_INCREMENT,
  placa         VARCHAR(10)   NOT NULL,
  marca         VARCHAR(50)   NOT NULL,
  modelo        VARCHAR(50)   NOT NULL,
  anio          INT           NOT NULL,
  tarifa_diaria DECIMAL(10,2) NOT NULL,
  estado        VARCHAR(20)   NOT NULL DEFAULT 'DISPONIBLE',
  PRIMARY KEY (id),
  UNIQUE KEY uk_vehiculo_placa (placa),
  KEY idx_vehiculo_estado (estado)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- Base del microservicio ms-alquiler
-- id_cliente e id_vehiculo son referencias lógicas, no FK entre bases.
-- ---------------------------------------------------------------------
USE bd_alquiler;

CREATE TABLE IF NOT EXISTS alquiler (
  id              BIGINT        NOT NULL AUTO_INCREMENT,
  id_cliente      BIGINT        NOT NULL,
  id_vehiculo     BIGINT        NOT NULL,
  fecha_inicio    DATE          NOT NULL,
  fecha_fin       DATE          NOT NULL,
  tarifa_diaria   DECIMAL(10,2) NOT NULL,
  importe_estimado DECIMAL(10,2) NOT NULL,
  estado          VARCHAR(20)   NOT NULL DEFAULT 'ACTIVO',
  PRIMARY KEY (id),
  KEY idx_alquiler_cliente (id_cliente),
  KEY idx_alquiler_vehiculo (id_vehiculo),
  KEY idx_alquiler_estado (estado)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
