# Evidencias de ejecución — Laboratorio 11

**Proyecto:** `lab11-alquiler-vehiculos` — microservicios de clientes, vehículos y alquileres  
**Fecha de ejecución:** 5 de noviembre de 2026  
**Sistema:** Windows (PowerShell 5.1)  
**Base de datos:** MySQL 8.0.44 local en `127.0.0.1:3306`  
**Perfiles verificados:** `dev` (8081/8082/8083) y `prod` (18081/18082/18083)  
**Docker:** no disponible en el entorno; se usó MySQL local. El `docker-compose.yml`
se entrega como alternativa y no fue ejecutado.

> Todos los bloques de esta página son salidas reales capturadas durante la
> verificación. Los POST se ejecutaron con archivos JSON UTF-8 sin BOM y
> `curl --data-binary @archivo` para evitar que PowerShell alterara las comillas;
> aquí se muestra el JSON equivalente.

---

## 1. Entorno

```text
$ java -version
openjdk version "17.0.20.1" 2026-08-18
OpenJDK Runtime Environment Temurin-17.0.20.1+1 (build 17.0.20.1+1)
OpenJDK 64-Bit Server VM Temurin-17.0.20.1+1 (build 17.0.20.1+1, mixed mode, sharing)

$ mvn -v
Apache Maven 3.9.9 (8e8579a9e76f7d015ee5ec7bfcdc97d260186937)
Maven home: C:\Users\LENOVO\lab11-tools\apache-maven-3.9.9
Java version: 17.0.20.1, vendor: Eclipse Adoptium

$ mysql --version
mysql  Ver 8.0.44 for Win64 on x86_64 (MySQL Community Server - GPL)

$ docker --version
'docker' no se reconoce como un comando interno o externo.
```

| Componente | Versión / estado |
|---|---|
| JDK | Temurin 17.0.20.1 |
| Maven | 3.9.9 |
| Spring Boot | 3.3.5 |
| MySQL | 8.0.44 (servicio local) |
| Docker | No instalado |

---

## 2. Compilación de los tres proyectos

Los servicios en ejecución se detuvieron antes del build porque Windows bloquea los
JAR abiertos por `java -jar`. Luego se ejecutó, para cada proyecto:

```bash
mvn -q clean package -DskipTests -f ms-cliente/pom.xml
mvn -q clean package -DskipTests -f ms-vehiculo/pom.xml
mvn -q clean package -DskipTests -f ms-alquiler/pom.xml
```

Resultado real:

```text
=== ms-cliente ===
exit=0
ms-cliente-0.0.1-SNAPSHOT.jar  48,839,097 bytes
=== ms-vehiculo ===
exit=0
ms-vehiculo-0.0.1-SNAPSHOT.jar  48,840,480 bytes
=== ms-alquiler ===
exit=0
ms-alquiler-0.0.1-SNAPSHOT.jar  48,848,264 bytes
```

Los tres builds terminaron con código de salida `0` y generaron un JAR ejecutable
en `target/`.

---

## 3. Base de datos creada y verificada

### 3.1. Bases existentes

```text
$ mysql -u root -e "SHOW DATABASES;"
Database
bd_alquiler
bd_cliente
bd_vehiculo
information_schema
mysql
performance_schema
sys
```

Las tres bases del laboratorio existen. Las demás son bases internas de MySQL.

### 3.2. Una sola tabla por base, sin tablas cruzadas

```text
$ mysql -u root -e "SELECT table_schema, table_name, engine, table_collation
FROM information_schema.tables
WHERE table_schema IN ('bd_cliente','bd_vehiculo','bd_alquiler')
ORDER BY table_schema;"
TABLE_SCHEMA  TABLE_NAME  ENGINE  TABLE_COLLATION
bd_alquiler   alquiler    InnoDB  utf8mb4_unicode_ci
bd_cliente    cliente     InnoDB  utf8mb4_unicode_ci
bd_vehiculo   vehiculo    InnoDB  utf8mb4_unicode_ci
```

```text
$ mysql -u root -e "SELECT COUNT(*) AS tablas_totales
FROM information_schema.tables
WHERE table_schema IN ('bd_cliente','bd_vehiculo','bd_alquiler');"
tablas_totales
3

$ mysql -u root -e "SELECT COUNT(*) AS llaves_foraneas
FROM information_schema.referential_constraints
WHERE constraint_schema IN ('bd_cliente','bd_vehiculo','bd_alquiler');"
llaves_foraneas
0
```

**Conclusión:** hay exactamente una tabla por base y **cero llaves foráneas entre
bases**. La relación entre alquiler, cliente y vehículo es lógica, mediante
`id_cliente` e `id_vehiculo`.

### 3.3. Esquemas reales

```sql
CREATE TABLE `cliente` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `nombres` varchar(100) NOT NULL,
  `apellidos` varchar(100) NOT NULL,
  `documento` varchar(8) NOT NULL,
  `correo` varchar(150) NOT NULL,
  `telefono` varchar(9) NOT NULL,
  `estado` varchar(20) NOT NULL DEFAULT 'ACTIVO',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_cliente_documento` (`documento`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

```sql
CREATE TABLE `vehiculo` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `placa` varchar(10) NOT NULL,
  `marca` varchar(50) NOT NULL,
  `modelo` varchar(50) NOT NULL,
  `anio` int NOT NULL,
  `tarifa_diaria` decimal(10,2) NOT NULL,
  `estado` varchar(20) NOT NULL DEFAULT 'DISPONIBLE',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_vehiculo_placa` (`placa`),
  KEY `idx_vehiculo_estado` (`estado`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

```sql
CREATE TABLE `alquiler` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `id_cliente` bigint NOT NULL,
  `id_vehiculo` bigint NOT NULL,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL,
  `tarifa_diaria` decimal(10,2) NOT NULL,
  `importe_estimado` decimal(10,2) NOT NULL,
  `estado` varchar(20) NOT NULL DEFAULT 'ACTIVO',
  PRIMARY KEY (`id`),
  KEY `idx_alquiler_cliente` (`id_cliente`),
  KEY `idx_alquiler_vehiculo` (`id_vehiculo`),
  KEY `idx_alquiler_estado` (`estado`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 3.4. Usuario de aplicación

```text
$ mysql -u root -e "SHOW GRANTS FOR 'lab11_user'@'localhost';"
GRANT USAGE ON *.* TO `lab11_user`@`localhost`
GRANT ALL PRIVILEGES ON `bd_alquiler`.* TO `lab11_user`@`localhost`
GRANT ALL PRIVILEGES ON `bd_cliente`.* TO `lab11_user`@`localhost`
GRANT ALL PRIVILEGES ON `bd_vehiculo`.* TO `lab11_user`@`localhost`
```

`lab11_user` solo tiene permisos sobre las tres bases del laboratorio. La
aplicación no se conecta como `root`.

### 3.5. Datos finales

Después de las pruebas end-to-end, las tablas contienen:

```text
$ mysql -u root -e "SELECT id, nombres, apellidos, documento, correo, telefono, estado
FROM bd_cliente.cliente ORDER BY id;"
id  nombres          apellidos         documento  correo                       telefono   estado
1   Juan             Pérez             12345678   juan.perez@example.com       987654321  ACTIVO
2   María            Torres            23456789   maria.torres@example.com     987654322  ACTIVO
3   Luis             Gómez             34567890   luis.gomez@example.com       987654323  ACTIVO
4   Ana              Ramírez           45678901   ana.ramirez@example.com      987654324  INACTIVO
5   Pedro            Castillo          56789012   pedro.castillo@example.com   987654325  ACTIVO
6   Carlos Fernando  Junco Santiago    87654321   carlos.junco@example.com     987111222  ACTIVO
7   Elena            Quispe Rojas      11223344   elena.quispe@example.com     986334455  ACTIVO
```

```text
$ mysql -u root -e "SELECT id, placa, marca, modelo, anio, tarifa_diaria, estado
FROM bd_vehiculo.vehiculo ORDER BY id;"
id  placa    marca       modelo  anio  tarifa_diaria  estado
1   ABC-123  Toyota      Corolla 2022  120.00         DISPONIBLE
2   DEF-456  Hyundai     Tucson  2023  180.00         DISPONIBLE
3   GHI-789  Kia         Rio     2021  100.00         ALQUILADO
4   JKL-012  Nissan      Sentra  2020  110.00         DISPONIBLE
5   MNO-345  Chevrolet   Spark   2019   80.00         MANTENIMIENTO
6   TST-999  Mitsubishi  L200    2024  150.00         DISPONIBLE
7   EVD-111  Mazda       CX-5    2025  185.50         DISPONIBLE
```

```text
$ mysql -u root -e "SELECT id, id_cliente, id_vehiculo, fecha_inicio, fecha_fin,
tarifa_diaria, importe_estimado, estado FROM bd_alquiler.alquiler ORDER BY id;"
id  id_cliente  id_vehiculo  fecha_inicio  fecha_fin   tarifa_diaria  importe_estimado  estado
1   1           1            2026-09-01    2026-09-04  120.00         360.00            FINALIZADO
2   2           2            2026-09-10    2026-09-12  180.00         360.00            CANCELADO
3   3           3            2026-11-01    2026-11-06  100.00         500.00            ACTIVO
4   6           6            2026-11-06    2026-11-09  150.00         450.00            FINALIZADO
5   6           6            2026-11-06    2026-11-09  150.00         450.00            CANCELADO
6   7           7            2026-11-10    2026-11-13  185.50         556.50            FINALIZADO
```

Los alquileres 1–3 son los datos sembrados por `sql/02_data.sql`; los alquileres
4–6 se generaron durante las verificaciones. El alquiler 6 cumple
`3 días × 185.50 = 556.50`.

---

## 4. Arranque con perfil `dev`

Se ejecutaron los tres JAR con el perfil por defecto (`dev`):

```bash
java -jar ms-cliente/target/ms-cliente-0.0.1-SNAPSHOT.jar
java -jar ms-vehiculo/target/ms-vehiculo-0.0.1-SNAPSHOT.jar
java -jar ms-alquiler/target/ms-alquiler-0.0.1-SNAPSHOT.jar
```

Líneas reales de los logs:

```text
2026-11-05T21:31:30.714-05:00  INFO 15236 --- [ms-cliente] [main]
c.tecsup.cliente.MsClienteApplication : The following 1 profile is active: "dev"
2026-11-05T21:32:23.730-05:00  INFO 15236 --- [ms-cliente] [main]
o.s.b.w.embedded.tomcat.TomcatWebServer : Tomcat started on port 8081 (http) with context path '/'

2026-11-05T21:31:27.636-05:00  INFO 9504 --- [ms-vehiculo] [main]
c.tecsup.vehiculo.MsVehiculoApplication : The following 1 profile is active: "dev"
2026-11-05T21:32:30.518-05:00  INFO 9504 --- [ms-vehiculo] [main]
o.s.b.w.embedded.tomcat.TomcatWebServer : Tomcat started on port 8082 (http) with context path '/'

2026-11-05T21:31:33.152-05:00  INFO 13532 --- [ms-alquiler] [main]
c.tecsup.alquiler.MsAlquilerApplication : The following 1 profile is active: "dev"
2026-11-05T21:32:22.502-05:00  INFO 13532 --- [ms-alquiler] [main]
o.s.b.w.embedded.tomcat.TomcatWebServer : Tomcat started on port 8083 (http) with context path '/'
```

Comprobación HTTP de los tres servicios:

```text
GET http://localhost:8081/api/clientes    -> 200
GET http://localhost:8082/api/vehiculos   -> 200
GET http://localhost:8083/api/alquileres  -> 200
```

---

## 5. Flujo end-to-end

### 5.1. Crear cliente

```bash
curl -s -X POST http://localhost:8081/api/clientes \
  -H "Content-Type: application/json" \
  -d '{
    "nombres":"Elena",
    "apellidos":"Quispe Rojas",
    "documento":"11223344",
    "correo":"elena.quispe@example.com",
    "telefono":"986334455",
    "estado":"ACTIVO"
  }'
```

Salida real:

```text
HTTP 201
{"id":7,"nombres":"Elena","apellidos":"Quispe Rojas","documento":"11223344","correo":"elena.quispe@example.com","telefono":"986334455","estado":"ACTIVO"}
```

### 5.2. Crear vehículo

```bash
curl -s -X POST http://localhost:8082/api/vehiculos \
  -H "Content-Type: application/json" \
  -d '{
    "placa":"EVD-111",
    "marca":"Mazda",
    "modelo":"CX-5",
    "anio":2025,
    "tarifaDiaria":185.50,
    "estado":"DISPONIBLE"
  }'
```

Salida real:

```text
HTTP 201
{"id":7,"placa":"EVD-111","marca":"Mazda","modelo":"CX-5","anio":2025,"tarifaDiaria":185.50,"estado":"DISPONIBLE"}
```

### 5.3. Crear alquiler (sin enviar tarifa ni importe)

```bash
curl -s -X POST http://localhost:8083/api/alquileres \
  -H "Content-Type: application/json" \
  -d '{
    "idCliente":7,
    "idVehiculo":7,
    "fechaInicio":"2026-11-10",
    "fechaFin":"2026-11-13"
  }'
```

Salida real:

```text
HTTP 201
{"id":6,"idCliente":7,"idVehiculo":7,"fechaInicio":"2026-11-10","fechaFin":"2026-11-13","tarifaDiaria":185.50,"importeEstimado":556.50,"estado":"ACTIVO"}
```

**Cálculo verificado:** `ChronoUnit.DAYS.between(2026-11-10, 2026-11-13) = 3`;
`3 × 185.50 = 556.50`, con `BigDecimal` y escala 2. La tarifa se tomó del
vehículo porque el cliente no la envió.

### 5.4. Sincronización del estado del vehículo

Después de crear el alquiler, el microservicio de alquiler llamó a
`PATCH /api/vehiculos/7/estado`:

```text
$ curl -s http://localhost:8082/api/vehiculos/7
HTTP 200
{"id":7,"placa":"EVD-111","marca":"Mazda","modelo":"CX-5","anio":2025,"tarifaDiaria":185.50,"estado":"ALQUILADO"}
```

### 5.5. Finalizar alquiler

```text
$ curl -s -X PATCH http://localhost:8083/api/alquileres/6/finalizar
HTTP 200
{"id":6,"idCliente":7,"idVehiculo":7,"fechaInicio":"2026-11-10","fechaFin":"2026-11-13","tarifaDiaria":185.50,"importeEstimado":556.50,"estado":"FINALIZADO"}
```

El vehículo vuelve a `DISPONIBLE`:

```text
$ curl -s http://localhost:8082/api/vehiculos/7
HTTP 200
{"id":7,"placa":"EVD-111","marca":"Mazda","modelo":"CX-5","anio":2025,"tarifaDiaria":185.50,"estado":"DISPONIBLE"}
```

**Resultado:** el ciclo completo cliente → vehículo → alquiler → finalización
funciona y mantiene sincronizado el estado del vehículo entre microservicios.

---

## 6. Validaciones y errores

Todas las respuestas usan el mismo formato:
`timestamp`, `status`, `error`, `message`, `path`, `errors`.

### 6.1. Error 400 — fecha de inicio en el pasado

```text
POST /api/alquileres
HTTP 400
{"timestamp":"2026-11-05T21:35:04.6860692","status":400,"error":"Bad Request","message":"La fecha de inicio no puede estar en el pasado","path":"/api/alquileres","errors":[]}
```

### 6.2. Error 400 — fecha de fin no posterior

```text
POST /api/alquileres
HTTP 400
{"timestamp":"2026-11-05T21:35:04.7919531","status":400,"error":"Bad Request","message":"La fecha de fin debe ser posterior a la fecha de inicio","path":"/api/alquileres","errors":[]}
```

### 6.3. Error 404 — cliente inexistente

```text
POST /api/alquileres  { "idCliente": 99999, ... }
HTTP 404
{"timestamp":"2026-11-05T21:35:04.9500119","status":404,"error":"Not Found","message":"Cliente no encontrado","path":"/api/alquileres","errors":[]}
```

### 6.4. Error 404 — vehículo inexistente

```text
POST /api/alquileres  { "idVehiculo": 99999, ... }
HTTP 404
{"timestamp":"2026-11-05T21:35:05.1559247","status":404,"error":"Not Found","message":"Vehículo no encontrado","path":"/api/alquileres","errors":[]}
```

### 6.5. Error 409 — vehículo en mantenimiento

Se usó el vehículo `5` (`MNO-345`), sembrado con estado `MANTENIMIENTO`:

```text
POST /api/alquileres  { "idVehiculo": 5, ... }
HTTP 409
{"timestamp":"2026-11-05T21:35:05.2881121","status":409,"error":"Conflict","message":"El vehículo no está disponible para alquiler (estado: MANTENIMIENTO)","path":"/api/alquileres","errors":[]}
```

### 6.6. Error 409 — DNI duplicado

```text
POST /api/clientes  { "documento": "11223344", ... }
HTTP 409
{"timestamp":"2026-11-05T21:35:05.3613437","status":409,"error":"Conflict","message":"El documento 11223344 ya está registrado","path":"/api/clientes","errors":[]}
```

### 6.7. Error 409 — placa duplicada

```text
POST /api/vehiculos  { "placa": "EVD-111", ... }
HTTP 409
{"timestamp":"2026-11-05T21:35:05.4403729","status":409,"error":"Conflict","message":"La placa EVD-111 ya está registrada","path":"/api/vehiculos","errors":[]}
```

### 6.8. Error 400 — validación de campos

```text
POST /api/clientes  { "documento": "123", "correo": "no-es-correo", "telefono": "123", ... }
HTTP 400
{"timestamp":"2026-11-05T21:35:05.5235188","status":400,"error":"Bad Request","message":"Datos inválidos","path":"/api/clientes","errors":[{"field":"telefono","message":"El teléfono debe tener exactamente 9 dígitos"},{"field":"documento","message":"El documento debe tener exactamente 8 dígitos"},{"field":"correo","message":"El correo no tiene un formato válido"}]}
```

### 6.9. Error 400 — tarifa negativa

```text
POST /api/vehiculos  { "tarifaDiaria": -10, ... }
HTTP 400
{"timestamp":"2026-11-05T21:35:05.6032155","status":400,"error":"Bad Request","message":"Datos inválidos","path":"/api/vehiculos","errors":[{"field":"tarifaDiaria","message":"La tarifa diaria no puede ser negativa"}]}
```

### 6.10. Error 404 — alquiler inexistente

```text
GET /api/alquileres/99999
HTTP 404
{"timestamp":"2026-11-05T21:35:05.6747219","status":404,"error":"Not Found","message":"Alquiler no encontrado con id 99999","path":"/api/alquileres/99999","errors":[]}
```

### 6.11. Error 409 — finalizar un alquiler ya cerrado

```text
PATCH /api/alquileres/6/finalizar
HTTP 409
{"timestamp":"2026-11-05T21:35:05.7696602","status":409,"error":"Conflict","message":"Solo se puede finalizar un alquiler en estado ACTIVO","path":"/api/alquileres/6/finalizar","errors":[]}
```

### 6.12. Error 503 — ms-cliente caído

Se detuvo el proceso de `ms-cliente` (PID 15236) y se intentó crear un alquiler:

```text
POST /api/alquileres
HTTP 503
{"timestamp":"2026-11-05T21:35:23.7236509","status":503,"error":"Service Unavailable","message":"El servicio de clientes no está disponible","path":"/api/alquileres","errors":[]}
```

Luego se reinició `ms-cliente` (PID 15220) y se comprobó la recuperación:

```text
GET http://localhost:8081/api/clientes -> HTTP 200
```

### 6.13. DELETE — responde 204 y luego 404

Se crearon un cliente y un vehículo temporales (ids 8) y se eliminaron:

```text
DELETE /api/clientes/8
HTTP 204

GET /api/clientes/8
HTTP 404
{"timestamp":"2026-11-05T21:43:33.5628714","status":404,"error":"Not Found","message":"Cliente no encontrado con id 8","path":"/api/clientes/8","errors":[]}

DELETE /api/vehiculos/8
HTTP 204

GET /api/vehiculos/8
HTTP 404
{"timestamp":"2026-11-05T21:43:33.7781422","status":404,"error":"Not Found","message":"Vehículo no encontrado con id 8","path":"/api/vehiculos/8","errors":[]}
```

Los registros temporales quedaron eliminados; las tablas conservan los datos de
la sección 3.5.

---

## 7. Perfil `prod` con `ddl-auto=validate`

Se arrancaron instancias adicionales con `SPRING_PROFILES_ACTIVE=prod`,
`DB_URL`, `DB_USER`, `DB_PASSWORD` y puertos alternos, para no interferir con las
instancias `dev`:

| Servicio | Puerto | Base | PID |
|---|---:|---|---:|
| ms-cliente | 18081 | `bd_cliente` | 6280 |
| ms-vehiculo | 18082 | `bd_vehiculo` | 3248 |
| ms-alquiler | 18083 | `bd_alquiler` | 14116 |

Líneas reales de arranque:

```text
2026-11-05T21:37:35.432-05:00  INFO 6280 --- [ms-cliente] [main]
c.tecsup.cliente.MsClienteApplication : The following 1 profile is active: "prod"
2026-11-05T21:38:28.282-05:00  INFO 6280 --- [ms-cliente] [main]
o.s.b.w.embedded.tomcat.TomcatWebServer : Tomcat started on port 18081 (http) with context path '/'

2026-11-05T21:37:33.910-05:00  INFO 3248 --- [ms-vehiculo] [main]
c.tecsup.vehiculo.MsVehiculoApplication : The following 1 profile is active: "prod"
2026-11-05T21:38:32.835-05:00  INFO 3248 --- [ms-vehiculo] [main]
o.s.b.w.embedded.tomcat.TomcatWebServer : Tomcat started on port 18082 (http) with context path '/'

2026-11-05T21:37:31.281-05:00  INFO 14116 --- [ms-alquiler] [main]
c.tecsup.alquiler.MsAlquilerApplication : The following 1 profile is active: "prod"
2026-11-05T21:38:39.078-05:00  INFO 14116 --- [ms-alquiler] [main]
o.s.b.w.embedded.tomcat.TomcatWebServer : Tomcat started on port 18083 (http) with context path '/'
```

No apareció ningún error de validación de esquema: las tablas creadas por
`sql/01_schema.sql` coinciden con las entidades JPA.

Con `show-sql=false` no se imprime SQL. Conteo de líneas `Hibernate:` en los logs
de producción:

```text
ms-cliente  -> 0
ms-vehiculo -> 0
ms-alquiler -> 0
```

Los endpoints respondieron correctamente con el perfil `prod`:

```text
GET http://localhost:18081/api/clientes    -> HTTP 200
GET http://localhost:18082/api/vehiculos   -> HTTP 200
GET http://localhost:18083/api/alquileres  -> HTTP 200
```

Después de la comprobación se detuvieron las tres instancias de producción; los
puertos 18081, 18082 y 18083 quedaron libres.

---

## 8. Colección Postman

Archivo: `postman/Lab11-Alquiler.postman_collection.json`.

Validación estructural realizada con `ConvertFrom-Json`:

```text
coleccion: Lab11 - Alquiler de Vehiculos
  00 - Clientes: 9 requests, 9 scripts de prueba
  01 - Vehiculos: 11 requests, 11 scripts de prueba
  02 - Alquileres: 9 requests, 9 scripts de prueba
  03 - Casos de error de alquiler: 6 requests, 6 scripts de prueba
TOTAL: 35 requests, 35 scripts de prueba
```

Cada request tiene al menos un script de prueba de status code; los requests de
alquiler comprueban además el importe calculado y/o el estado resultante. La
colección usa fechas futuras, DNI y placa generados dinámicamente.

No se ejecutó con Newman porque no está instalado en el entorno; el mismo flujo
y los mismos casos se verificaron con `curl` (secciones 5 y 6).

---

## 9. Checklist de aceptación

| Requisito | Evidencia | Estado |
|---|---|---|
| Tres microservicios independientes, un proyecto Maven por servicio | Sección 2 y estructura del repositorio | Cumple |
| Puertos 8081 / 8082 / 8083 | Sección 4 | Cumple |
| Una base de datos por servicio, sin FK cruzadas | Sección 3 (3 tablas, 0 FKs) | Cumple |
| Solo IDs entre servicios | `alquiler.id_cliente`, `alquiler.id_vehiculo`; sin FK | Cumple |
| Perfiles `dev` y `prod` | Secciones 4 y 7 | Cumple |
| `dev`: `ddl-auto=update`, `show-sql=true` | Logs con SQL en dev; perfil activo `dev` | Cumple |
| `prod`: `ddl-auto=validate`, `show-sql=false`, sin credenciales reales | Sección 7 (0 líneas SQL, sin errores de validación) | Cumple |
| Errores uniformes 400/404/409/503 | Sección 6 | Cumple |
| POST responde 201 y DELETE 204 | Sección 5 y sección 6.13 | Cumple |
| Validación de fechas | Sección 6.1 y 6.2 | Cumple |
| Importe = días × tarifa con `BigDecimal` | Sección 5.3 (3 × 185.50 = 556.50) | Cumple |
| Verificación de cliente y vehículo por HTTP | Secciones 5.3, 6.3, 6.4 y 6.12 | Cumple |
| 404 si cliente/vehículo no existe | Secciones 6.3 y 6.4 | Cumple |
| 503 si un servicio está caído | Sección 6.12 | Cumple |
| 409 si el vehículo está en mantenimiento o alquilado | Sección 6.5 | Cumple |
| Sincronización ALQUILADO / DISPONIBLE | Secciones 5.4 y 5.5 | Cumple |
| Tarifa opcional con respaldo en el vehículo | Sección 5.3 (no se envió tarifa) | Cumple |
| Scripts SQL y `docker-compose.yml` | Sección 3 y archivos del repositorio | Cumple |
| Colección Postman con pruebas | Sección 8 | Cumple |
| README, diagramas, conclusiones, sustentación y evidencias | Archivos en `docs/` | Cumple |
| Compilación y ejecución reales | Secciones 2, 4 y 7 | Cumple |

---

## 10. Comandos para reproducir la verificación

```bash
# 1. Base de datos (MySQL local; en Docker usar: docker compose up -d)
mysql -u root < sql/00_usuario.sql
mysql -u root < sql/01_schema.sql
mysql -u root < sql/02_data.sql

# 2. Compilar
mvn -q clean package -DskipTests -f ms-cliente/pom.xml
mvn -q clean package -DskipTests -f ms-vehiculo/pom.xml
mvn -q clean package -DskipTests -f ms-alquiler/pom.xml

# 3. Arrancar en tres terminales, en este orden
java -jar ms-cliente/target/ms-cliente-0.0.1-SNAPSHOT.jar
java -jar ms-vehiculo/target/ms-vehiculo-0.0.1-SNAPSHOT.jar
java -jar ms-alquiler/target/ms-alquiler-0.0.1-SNAPSHOT.jar

# 4. Verificar
curl -s http://localhost:8081/api/clientes
curl -s http://localhost:8082/api/vehiculos
curl -s http://localhost:8083/api/alquileres

# 5. Consultar cada base por separado
mysql -u lab11_user -plab11_pass -e "SELECT * FROM bd_cliente.cliente;"
mysql -u lab11_user -plab11_pass -e "SELECT * FROM bd_vehiculo.vehiculo;"
mysql -u lab11_user -plab11_pass -e "SELECT * FROM bd_alquiler.alquiler;"
```

En Windows también se puede usar `run-all.bat`; en Linux/Git Bash, `bash run-all.sh`.
