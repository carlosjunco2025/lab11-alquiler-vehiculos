# Laboratorio 11 — Gestión de alquiler de vehículos

**Curso:** Desarrollo de Aplicaciones Web (Tecsup)  
**Tema:** Microservicios  
**Estudiante:** Carlos Fernando Junco Santiago  
**Sección:** D

Sistema compuesto por tres microservicios independientes. Cada uno tiene su propio
puerto, su propio proyecto Maven y **su propia base de datos**. No se comparten tablas
ni llaves foráneas entre bases: las referencias se hacen únicamente con `idCliente` e
`idVehiculo`.

---

## 1. Arquitectura

```text
                         ┌──────────────────────┐
      HTTP :8081         │      ms-cliente      │
      ──────────────────▶│  /api/clientes       │──▶ bd_cliente
                         └──────────────────────┘

                         ┌──────────────────────┐
      HTTP :8082         │     ms-vehiculo      │
      ──────────────────▶│  /api/vehiculos      │──▶ bd_vehiculo
                         └──────────────────────┘
                                    ▲
                                    │ RestClient (PATCH estado)
                         ┌──────────┴───────────┐
      HTTP :8083         │     ms-alquiler      │
      ──────────────────▶│  /api/alquileres     │──▶ bd_alquiler
                         └──────────┬───────────┘
                                    │ RestClient (GET cliente/vehículo)
                                    ▼
                         ms-cliente y ms-vehiculo
```

- **ms-cliente:** administra los datos personales de los clientes.
- **ms-vehiculo:** administra el catálogo y el estado de los vehículos.
- **ms-alquiler:** registra los alquileres y coordina la verificación del cliente y
  del vehículo mediante llamadas HTTP. También sirve el frontend web en `/`.
- **frontend web:** panel en HTML, CSS y JavaScript vanilla, disponible en
  `http://localhost:8083/`, que consume las tres APIs con CORS.
- No se usa Eureka, Gateway ni Config Server. Las URLs de los otros servicios se
  configuran en `application.yml` (`clientes.url`, `vehiculos.url`) y pueden
  sobrescribirse con variables de entorno.

El diagrama Mermaid completo y los diagramas ER están en
[`docs/diagrama.md`](docs/diagrama.md).

---

## 2. Requisitos

| Herramienta | Versión mínima | Uso |
|---|---|---|
| Java | 17 | Compilar y ejecutar Spring Boot 3.3.5 |
| Maven | 3.9 | Construir los tres proyectos |
| MySQL | 8.0 | Base de datos local |
| Docker + Docker Compose | Opcional | Alternativa para levantar MySQL |
| Postman | Opcional | Ejecutar la colección de pruebas |

Puertos que deben estar libres: **3306**, **8081**, **8082** y **8083**.

---

## 3. Puertos y bases de datos

| Microservicio | Puerto | Base de datos | Tabla | URL base |
|---|---:|---|---|---|
| ms-cliente | 8081 | `bd_cliente` | `cliente` | `http://localhost:8081` |
| ms-vehiculo | 8082 | `bd_vehiculo` | `vehiculo` | `http://localhost:8082` |
| ms-alquiler | 8083 | `bd_alquiler` | `alquiler` | `http://localhost:8083` |

Cada proyecto tiene exactamente la misma estructura de paquetes:

```text
com.tecsup.<servicio>
├── model        Entidades JPA y enums
├── dto          Objetos de entrada y salida
├── repository   Interfaces JpaRepository
├── services     Reglas de negocio y clientes HTTP
├── controller   Endpoints REST
└── exception    Excepciones propias y @RestControllerAdvice
```

---

## 4. Perfiles `dev` y `prod`

El perfil activo por defecto es `dev`. Se define en `application.yml` con
`spring.profiles.active: ${SPRING_PROFILES_ACTIVE:dev}`.

| Aspecto | `dev` | `prod` |
|---|---|---|
| Activación | Por defecto | `SPRING_PROFILES_ACTIVE=prod` |
| `ddl-auto` | `update` | `validate` |
| `show-sql` | `true` | `false` |
| URL JDBC | `jdbc:mysql://localhost:3306/bd_x` con host/puerto por variable | Obligatoria en `DB_URL` |
| Usuario | `DB_USER` con valor por defecto `lab11_user` | Obligatorio en `DB_USER` |
| Clave | `DB_PASSWORD` con valor por defecto `lab11_pass` | Obligatorio en `DB_PASSWORD` |
| Logging | `DEBUG` para el paquete del servicio y SQL | `INFO` |
| Esquema | Hibernate lo crea/actualiza | Debe existir; Hibernate solo valida |
| Credenciales reales | No | No se guardan en el repositorio |

### Variables de entorno

| Variable | Valor por defecto en dev | Uso |
|---|---|---|
| `SPRING_PROFILES_ACTIVE` | `dev` | Selecciona perfil |
| `DB_HOST` | `localhost` | Host MySQL en dev |
| `DB_PORT` | `3306` | Puerto MySQL en dev |
| `DB_USER` | `lab11_user` | Usuario de aplicación |
| `DB_PASSWORD` | `lab11_pass` | Clave de desarrollo |
| `DB_URL` | — | URL JDBC completa en prod |
| `PORT` | 8081 / 8082 / 8083 | Puerto HTTP del servicio |
| `MS_CLIENTE_URL` | `http://localhost:8081` | URL de ms-cliente para ms-alquiler |
| `MS_VEHICULO_URL` | `http://localhost:8082` | URL de ms-vehiculo para ms-alquiler |

> `lab11_pass` es una clave **de desarrollo**, no una credencial real. En un
> despliegue real se debe cambiar y entregar por variables de entorno.

Ejemplo de ejecución en modo `prod` (PowerShell, un servicio a la vez):

```powershell
$env:SPRING_PROFILES_ACTIVE = "prod"
$env:DB_URL = "jdbc:mysql://localhost:3306/bd_cliente?useSSL=false&serverTimezone=America/Lima&allowPublicKeyRetrieval=true"
$env:DB_USER = "lab11_user"
$env:DB_PASSWORD = "lab11_pass"
java -jar ms-cliente/target/ms-cliente-0.0.1-SNAPSHOT.jar
```

En `prod` el esquema debe existir antes de arrancar, porque `ddl-auto=validate`
no crea tablas. Ejecute primero los scripts de `/sql`.

---

## 5. Puesta en marcha

### 5.1. Opción A — MySQL con Docker (recomendada)

```bash
docker compose up -d
docker compose ps
```

El contenedor se llama `lab11-mysql`, usa `mysql:8.0`, un volumen persistente y un
healthcheck. La carpeta `./sql` se monta en `/docker-entrypoint-initdb.d`, por lo que
los scripts se ejecutan automáticamente **la primera vez** que se crea el volumen.
Espere hasta que el estado sea `healthy`:

```bash
docker inspect -f "{{.State.Health.Status}}" lab11-mysql
```

Clave de root por defecto para desarrollo: `lab11_root` (configurable con
`MYSQL_ROOT_PASSWORD`). La aplicación **no** usa root: usa `lab11_user`.

### 5.2. Opción B — MySQL local

Si ya tiene MySQL 8 o MariaDB instalado y escuchando en `3306`:

```bash
mysql -u root -p < sql/00_usuario.sql
mysql -u root -p < sql/01_schema.sql
mysql -u root -p < sql/02_data.sql
```

Si el usuario root no tiene clave, omita `-p`. Los scripts crean las tres bases,
las tablas, el usuario `lab11_user` y los datos de prueba.

Verificación rápida:

```bash
mysql -u lab11_user -plab11_pass -e "SHOW DATABASES;"
```

### 5.3. Compilar

Desde la raíz, en tres terminales o de forma secuencial:

```bash
mvn -q clean package -DskipTests -f ms-cliente/pom.xml
mvn -q clean package -DskipTests -f ms-vehiculo/pom.xml
mvn -q clean package -DskipTests -f ms-alquiler/pom.xml
```

Cada comando genera un JAR ejecutable en `target/`.

### 5.4. Arrancar en orden

El orden recomendado es **cliente → vehículo → alquiler**, porque al crear un
alquiler se consultan los otros dos servicios.

**Terminal 1:**

```bash
java -jar ms-cliente/target/ms-cliente-0.0.1-SNAPSHOT.jar
```

**Terminal 2** (cuando el 8081 esté arriba):

```bash
java -jar ms-vehiculo/target/ms-vehiculo-0.0.1-SNAPSHOT.jar
```

**Terminal 3** (cuando el 8082 esté arriba):

```bash
java -jar ms-alquiler/target/ms-alquiler-0.0.1-SNAPSHOT.jar
```

También puede usar los scripts incluidos:

```bash
# Windows
run-all.bat
```

```bash
# Linux / Git Bash
bash run-all.sh
```

Los scripts levantan MySQL con Docker si está disponible; si no, asumen MySQL local y
aplican los scripts SQL. `run-all.sh` guarda logs y PID en `logs/`.

### 5.5. Abrir el frontend web

Con los tres servicios activos, abra:

**http://localhost:8083/**

El panel se sirve desde `ms-alquiler/src/main/resources/static` y consume las tres
APIs (`8081`, `8082` y `8083`). Incluye:

- Tablero con indicadores y estado de los tres servicios.
- Gestión de clientes y vehículos con búsqueda, filtros y acciones.
- Alta, finalización, cancelación y eliminación de alquileres.
- Formularios modales y vista previa del importe calculado.
- Enlaces directos: `#dashboard`, `#clientes`, `#vehiculos` y `#alquileres`.

El perfil `dev` es suficiente para usar el panel. Los datos se cargan en tiempo real
desde las APIs; si un servicio está caído, el panel lo indica y muestra el error.

---

## 6. Endpoints

### 6.1. ms-cliente — `http://localhost:8081/api/clientes`

| Método | Ruta | Descripción | Códigos |
|---|---|---|---|
| GET | `/api/clientes` | Lista clientes | 200 |
| GET | `/api/clientes/{id}` | Busca por ID | 200, 404 |
| POST | `/api/clientes` | Crea cliente | 201, 400, 409 |
| PUT | `/api/clientes/{id}` | Actualiza cliente | 200, 400, 404, 409 |
| DELETE | `/api/clientes/{id}` | Elimina cliente | 204, 404 |

Validaciones: nombres y apellidos obligatorios, DNI de 8 dígitos y único, correo
válido, teléfono de 9 dígitos. DNI duplicado → **409**.

**POST de ejemplo**

```json
{
  "nombres": "Carlos Fernando",
  "apellidos": "Junco Santiago",
  "documento": "87654321",
  "correo": "carlos.junco@example.com",
  "telefono": "987111222",
  "estado": "ACTIVO"
}
```

Respuesta `201`:

```json
{
  "id": 6,
  "nombres": "Carlos Fernando",
  "apellidos": "Junco Santiago",
  "documento": "87654321",
  "correo": "carlos.junco@example.com",
  "telefono": "987111222",
  "estado": "ACTIVO"
}
```

### 6.2. ms-vehiculo — `http://localhost:8082/api/vehiculos`

| Método | Ruta | Descripción | Códigos |
|---|---|---|---|
| GET | `/api/vehiculos` | Lista vehículos | 200 |
| GET | `/api/vehiculos/{id}` | Busca por ID | 200, 404 |
| POST | `/api/vehiculos` | Crea vehículo | 201, 400, 409 |
| PUT | `/api/vehiculos/{id}` | Actualiza vehículo | 200, 400, 404, 409 |
| PATCH | `/api/vehiculos/{id}/estado` | Cambia solo el estado | 200, 400, 404 |
| DELETE | `/api/vehiculos/{id}` | Elimina vehículo | 204, 404 |

Estados: `DISPONIBLE`, `ALQUILADO`, `MANTENIMIENTO`. La placa es única: duplicado →
**409**. El año debe estar entre 1900 y 2100 y la tarifa no puede ser negativa.

**POST de ejemplo**

```json
{
  "placa": "TST-999",
  "marca": "Mitsubishi",
  "modelo": "L200",
  "anio": 2024,
  "tarifaDiaria": 150.00,
  "estado": "DISPONIBLE"
}
```

**PATCH de estado**

```http
PATCH /api/vehiculos/6/estado
Content-Type: application/json

{ "estado": "MANTENIMIENTO" }
```

### 6.3. ms-alquiler — `http://localhost:8083/api/alquileres`

| Método | Ruta | Descripción | Códigos |
|---|---|---|---|
| GET | `/api/alquileres` | Lista alquileres | 200 |
| GET | `/api/alquileres/{id}` | Busca por ID | 200, 404 |
| GET | `/api/alquileres/cliente/{idCliente}` | Lista por cliente | 200 |
| POST | `/api/alquileres` | Crea alquiler | 201, 400, 404, 409, 503 |
| PUT | `/api/alquileres/{id}` | Actualiza alquiler ACTIVO | 200, 400, 404, 409, 503 |
| PATCH | `/api/alquileres/{id}/finalizar` | Finaliza alquiler | 200, 404, 409, 503 |
| PATCH | `/api/alquileres/{id}/cancelar` | Cancela alquiler | 200, 404, 409, 503 |
| DELETE | `/api/alquileres/{id}` | Elimina alquiler | 204, 404, 503 |

**POST de ejemplo** (sin `tarifaDiaria`, se toma la del vehículo):

```json
{
  "idCliente": 6,
  "idVehiculo": 6,
  "fechaInicio": "2026-11-06",
  "fechaFin": "2026-11-09"
}
```

Respuesta `201` — 3 días × 150.00:

```json
{
  "id": 4,
  "idCliente": 6,
  "idVehiculo": 6,
  "fechaInicio": "2026-11-06",
  "fechaFin": "2026-11-09",
  "tarifaDiaria": 150.00,
  "importeEstimado": 450.00,
  "estado": "ACTIVO"
}
```

> Las fechas de ejemplo son futuras respecto de la fecha de verificación del
> laboratorio. Al probar después, use fechas de hoy en adelante: el servicio rechaza
> una `fechaInicio` en el pasado.

### 6.4. Formato uniforme de error

Los tres servicios responden con la misma estructura:

```json
{
  "timestamp": "2026-11-05T21:12:57.4232091",
  "status": 400,
  "error": "Bad Request",
  "message": "Datos inválidos",
  "path": "/api/clientes",
  "errors": [
    {
      "field": "documento",
      "message": "El documento debe tener exactamente 8 dígitos"
    }
  ]
}
```

| Código | Situación |
|---|---|
| 400 | Datos inválidos, JSON mal formado, fechas incoherentes |
| 404 | Cliente, vehículo o alquiler inexistente |
| 409 | DNI/placa duplicados, vehículo no disponible, alquiler ya cerrado |
| 503 | ms-cliente o ms-vehiculo no responde |
| 500 | Error interno no controlado |

---

## 7. Reglas de negocio del alquiler

1. `idCliente`, `idVehiculo`, `fechaInicio` y `fechaFin` son obligatorios.
2. `fechaInicio` no puede ser anterior a hoy.
3. `fechaFin` debe ser estrictamente posterior a `fechaInicio`.
4. Se consulta a **ms-cliente** que el cliente exista → si no, 404
   `"Cliente no encontrado"`.
5. Se consulta a **ms-vehiculo** que el vehículo exista → si no, 404
   `"Vehículo no encontrado"`.
6. Si el vehículo está `MANTENIMIENTO` o `ALQUILADO` → 409.
7. `tarifaDiaria` es opcional en el DTO. Si no se envía, se usa la del vehículo.
8. `dias = ChronoUnit.DAYS.between(fechaInicio, fechaFin)` con mínimo 1.
9. `importeEstimado = dias × tarifaDiaria`, con `BigDecimal` y escala 2.
   El cliente **no** puede enviar el importe.
10. Al crear el alquiler se marca el vehículo como `ALQUILADO` mediante
    `PATCH /api/vehiculos/{id}/estado`.
11. Al finalizar o cancelar se vuelve a marcar `DISPONIBLE`.
12. Si un servicio externo no responde → 503 con mensaje claro.

---

## 8. Cómo probar con Postman

1. Importe `postman/Lab11-Alquiler.postman_collection.json`.
2. Verifique las variables de colección: `baseUrlCliente`, `baseUrlVehiculo`,
   `baseUrlAlquiler` (por defecto `localhost` en 8081, 8082 y 8083).
3. Ejecute la colección completa con **Collection Runner** respetando el orden:
   `00 - Clientes`, `01 - Vehiculos`, `02 - Alquileres`,
   `03 - Casos de error de alquiler`.
4. La colección crea un cliente y un vehículo con datos únicos, guarda sus IDs en
   variables y usa esos IDs para el alquiler. También prueba los casos de error.
5. Cada request tiene tests básicos de status code; algunos comprueban además el
   cálculo del importe y el estado resultante.

Datos sembrados útiles:

| Dato | Valor |
|---|---|
| Cliente existente | id `1` |
| Vehículo disponible | id `1` (ABC-123, tarifa 120.00) |
| Vehículo en mantenimiento | id `5` (MNO-345) |
| Alquiler activo | id `3` |

Si ejecuta un request aislado, revise que los IDs de las variables sigan existiendo.

---

## 9. Base de datos

### 9.1. Scripts

| Archivo | Contenido |
|---|---|
| `sql/00_usuario.sql` | Crea `lab11_user` con permisos solo sobre `bd_cliente`, `bd_vehiculo` y `bd_alquiler` |
| `sql/01_schema.sql` | Crea las 3 bases (utf8mb4) y las tablas con PK, índices y UNIQUE |
| `sql/02_data.sql` | 5 clientes, 5 vehículos (uno en mantenimiento) y 3 alquileres coherentes |

### 9.2. Levantar MySQL con Docker

```bash
docker compose up -d
docker compose ps
docker logs lab11-mysql
```

El healthcheck consulta `mysqladmin ping`. El volumen persistente se llama
`lab11_mysql_data`. Los scripts solo se ejecutan cuando el volumen está vacío.

Para reiniciar desde cero y volver a ejecutar los scripts:

```bash
docker compose down -v
docker compose up -d
```

### 9.3. MySQL local

```bash
mysql -u root -p < sql/00_usuario.sql
mysql -u root -p < sql/01_schema.sql
mysql -u root -p < sql/02_data.sql
```

### 9.4. Usuario de ejemplo

| Usuario | Clave | Permisos |
|---|---|---|
| `lab11_user` | `lab11_pass` | Solo las tres bases del laboratorio |

La aplicación nunca se conecta como `root`. En producción, `DB_USER` y
`DB_PASSWORD` deben venir del entorno.

### 9.5. Consultas de verificación

```sql
SHOW DATABASES;

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema IN ('bd_cliente', 'bd_vehiculo', 'bd_alquiler');

SELECT COUNT(*) FROM bd_cliente.cliente;
SELECT COUNT(*) FROM bd_vehiculo.vehiculo;
SELECT COUNT(*) FROM bd_alquiler.alquiler;
```

Debe haber **una sola tabla por base**: `cliente`, `vehiculo` y `alquiler`.
No debe existir ninguna tabla de alquileres dentro de `bd_cliente` ni viceversa.

### 9.6. Limpiar todo

```bash
docker compose down -v
```

Esto elimina el contenedor y el volumen de datos. Para MySQL local:

```sql
DROP DATABASE bd_cliente;
DROP DATABASE bd_vehiculo;
DROP DATABASE bd_alquiler;
DROP USER 'lab11_user'@'localhost';
DROP USER 'lab11_user'@'%';
```

---

## 10. Estructura del repositorio

```text
lab11-alquiler-vehiculos/
├── README.md
├── .gitignore
├── docker-compose.yml
├── run-all.bat
├── run-all.sh
├── sql/
│   ├── 00_usuario.sql
│   ├── 01_schema.sql
│   └── 02_data.sql
├── postman/
│   └── Lab11-Alquiler.postman_collection.json
├── docs/
│   ├── Documentacion-Lab11.docx   Documento técnico con capturas
│   ├── img/                      Capturas del código y del frontend
│   ├── diagrama.md
│   ├── CONCLUSIONES.md
│   ├── SUSTENTACION.md
│   └── EVIDENCIAS.md
├── ms-cliente/
│   ├── pom.xml
│   └── src/main/java/com/tecsup/cliente/...
├── ms-vehiculo/
│   ├── pom.xml
│   └── src/main/java/com/tecsup/vehiculo/...
└── ms-alquiler/
    ├── pom.xml
    └── src/main/
        ├── java/com/tecsup/alquiler/...
        └── resources/
            ├── static/            index.html, css/styles.css, js/app.js
            └── application*.yml
```

---

## 11. Verificación realizada

Este laboratorio se compiló y ejecutó en un entorno Windows sin Docker. Se usó
MySQL 8.0.44 local, Java 17.0.20.1 y Maven 3.9.9. Se verificó:

- `mvn -q clean package -DskipTests` en los tres proyectos.
- Arranque de los tres servicios contra MySQL con perfil `dev`.
- Flujo cliente → vehículo → alquiler con importe 450.00 (3 × 150.00).
- Errores 400, 404, 409 y 503.
- Perfil `prod` con `ddl-auto=validate` en los tres servicios.
- Consultas directas en MySQL: cada tabla en su base, sin tablas cruzadas.
- Frontend en `http://localhost:8083/` con los tres servicios en línea y sin errores
  en la consola del navegador.
- CORS verificado con `Origin: http://localhost:8083` en las APIs de clientes,
  vehículos y alquileres.

Las salidas reales están en [`docs/EVIDENCIAS.md`](docs/EVIDENCIAS.md). La
documentación técnica con capturas del código, de los servicios y del frontend está
en [`docs/Documentacion-Lab11.docx`](docs/Documentacion-Lab11.docx).

---

## 12. Solución de problemas

| Problema | Causa probable | Solución |
|---|---|---|
| `Port 8081 was already in use` | Otro proceso ocupa el puerto | Detenga ese proceso o use `PORT=...` |
| `Access denied for user 'lab11_user'` | No se ejecutó `00_usuario.sql` | Ejecute el script como root |
| `Unknown database 'bd_cliente'` | No se ejecutó `01_schema.sql` | Ejecute schema y data |
| `Schema-validation: missing table` en prod | `validate` no crea tablas | Ejecute los scripts SQL antes de arrancar |
| 503 al crear alquiler | ms-cliente o ms-vehiculo está caído | Arranque los servicios en orden |
| Docker no está instalado | Entorno sin Docker | Use MySQL local y los scripts de `/sql` |
