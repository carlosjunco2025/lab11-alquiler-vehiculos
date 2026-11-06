# Guía de sustentación — Laboratorio 11

**Duración objetivo: 6 a 8 minutos**  
**Estudiante:** Carlos Fernando Junco Santiago — Sección D

---

## Guion por tiempos

| Tiempo | Tema | Qué decir / mostrar |
|---|---|---|
| 0:00 – 1:00 | Por qué tres servicios | Separé el dominio por responsabilidad: clientes, vehículos y alquileres. Cada uno tiene su base y su puerto. |
| 1:00 – 2:00 | Persistencia | JPA/Hibernate, entidades, repositorios, MySQL y perfiles dev/prod. |
| 2:00 – 3:00 | Datos inválidos | Validaciones del DTO, excepciones propias, handler global y códigos 400/404/409/503. |
| 3:00 – 4:30 | Comunicación | RestClient, URLs configurables, validación de cliente/vehículo y cambio de estado del vehículo. |
| 4:30 – 6:00 | Capas | Explicar Entity, Repository, Service, Controller y manejo de errores con archivos concretos. |
| 6:00 – 7:00 | Cambios en vivo | Campo nuevo, endpoint nuevo y validación nueva, indicando archivo y método. |
| 7:00 – 8:00 | Demo | Flujo cliente → vehículo → alquiler y un caso de error. |

---

## 1. ¿Por qué separé el sistema en estos servicios? (1 minuto)

El dominio tiene tres responsabilidades claras:

- **ms-cliente** es el dueño de los datos personales. No necesita saber nada de
  vehículos ni de alquileres.
- **ms-vehiculo** es el dueño del catálogo, la tarifa y el estado físico del vehículo
  (`DISPONIBLE`, `ALQUILADO`, `MANTENIMIENTO`).
- **ms-alquiler** es el dueño del contrato: fechas, tarifa aplicada e importe. Para
  validar el cliente y el vehículo no copia sus datos: solo guarda `idCliente` e
  `idVehiculo`.

Cada servicio tiene su propia base (`bd_cliente`, `bd_vehiculo`, `bd_alquiler`) y su
propio puerto (8081, 8082, 8083). No hay tablas compartidas ni llaves foráneas entre
bases. Eso permite desplegar o reiniciar un servicio sin tocar la base de los otros,
aunque obliga a validar las referencias por HTTP.

---

## 2. ¿Cómo persisten los datos? (1 minuto)

Cada proyecto usa Spring Data JPA con Hibernate y el driver de MySQL.

- **Entidad:** `Cliente.java`, `Vehiculo.java` y `Alquiler.java` están anotadas con
  `@Entity` y `@Table`. Cada campo se mapea a una columna con `@Column`. Los enums se
  guardan como texto con `@Enumerated(EnumType.STRING)`.
- **Repositorio:** `ClienteRepository`, `VehiculoRepository` y `AlquilerRepository`
  extienden `JpaRepository`. Spring genera la implementación de `save`, `findById`,
  `findAll` y `delete`. Los métodos `existsByDocumento` y `existsByPlaca` se usan para
  detectar duplicados.
- **Base de datos:** los scripts de `sql/` crean las tablas con `BIGINT`,
  `VARCHAR`, `DATE` y `DECIMAL(10,2)`. El perfil `dev` usa `ddl-auto=update` y el
  perfil `prod` usa `ddl-auto=validate`.
- **Perfiles:** `application.yml` deja `dev` por defecto. `application-dev.yml` usa
  `localhost` y muestra SQL. `application-prod.yml` toma `DB_URL`, `DB_USER` y
  `DB_PASSWORD` del entorno, no muestra SQL y valida el esquema.

Puedo mostrar en MySQL:

```sql
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema IN ('bd_cliente','bd_vehiculo','bd_alquiler');
```

Y se ve una tabla por base: `cliente`, `vehiculo` y `alquiler`.

---

## 3. ¿Qué ocurre cuando la API recibe información inválida? (1 minuto)

Hay tres niveles:

1. **Validación del DTO:** `ClienteRequest`, `VehiculoRequest` y `AlquilerRequest`
   tienen anotaciones como `@NotBlank`, `@Pattern`, `@Email`, `@NotNull`,
   `@DecimalMin` y `@Digits`. El controlador recibe el DTO con `@Valid`.
2. **Reglas de negocio:** `AlquilerService.validarFechas` rechaza fechas pasadas o una
   fecha fin que no sea posterior. `validarDisponibilidad` rechaza vehículos en
   mantenimiento o ya alquilados. `ClienteService` y `VehiculoService` verifican
   duplicados antes de guardar.
3. **Handler global:** `GlobalExceptionHandler` atrapa la excepción y devuelve un JSON
   uniforme con `timestamp`, `status`, `error`, `message`, `path` y `errors`.
   Las validaciones producen una lista de errores por campo.

Ejemplo real de respuesta 400 por DNI inválido:

```json
{
  "status": 400,
  "error": "Bad Request",
  "message": "Datos inválidos",
  "path": "/api/clientes",
  "errors": [
    { "field": "documento", "message": "El documento debe tener exactamente 8 dígitos" }
  ]
}
```

Códigos usados: **400** datos inválidos, **404** recurso inexistente, **409**
conflicto (DNI/placa duplicados, vehículo no disponible), **503** servicio externo
caído y **500** error genérico. POST devuelve **201** y DELETE **204**.

---

## 4. ¿Cómo se comunican los microservicios? (1.5 minutos)

Solo `ms-alquiler` necesita hablar con los otros dos. Lo hace con **RestClient**,
configurado con las propiedades:

```yaml
clientes:
  url: ${MS_CLIENTE_URL:http://localhost:8081}
vehiculos:
  url: ${MS_VEHICULO_URL:http://localhost:8082}
```

Clases concretas:

- `services/ClienteClientService.java`: hace `GET /api/clientes/{id}`. Si el otro
  servicio responde 404, lanza `ResourceNotFoundException` y la API responde 404
  `"Cliente no encontrado"`. Si no hay conexión, lanza `ExternalServiceException` y
  responde 503.
- `services/VehiculoClientService.java`: hace `GET /api/vehiculos/{id}` y
  `PATCH /api/vehiculos/{id}/estado` con el nuevo estado.
- `AlquilerService.crear`: valida fechas, consulta cliente, consulta vehículo,
  verifica que esté `DISPONIBLE`, calcula el importe, guarda el alquiler y recién ahí
  marca el vehículo como `ALQUILADO`.
- `finalizar` y `cancelar`: vuelven a marcar el vehículo como `DISPONIBLE`.

El cálculo está en `AlquilerService.calcularImporte` (línea 201):

```java
long dias = ChronoUnit.DAYS.between(inicio, fin);
if (dias < 1) dias = 1;
return tarifa.multiply(BigDecimal.valueOf(dias)).setScale(2, RoundingMode.HALF_UP);
```

El `importeEstimado` no existe en `AlquilerRequest`, así que el cliente no puede
enviarlo ni manipularlo.

---

## 5. Explicación breve de las capas (1.5 minutos)

Usaré `ms-cliente` como ejemplo, pero la estructura se repite en los tres servicios.

### Entity — `model/Cliente.java`

Representa la tabla `cliente`. Tiene `@Entity`, `@Table(name = "cliente")`, `@Id` con
`@GeneratedValue(strategy = IDENTITY)` y `@Column` en cada campo. `estado` es un enum
`EstadoCliente` guardado como `VARCHAR` gracias a `@Enumerated(EnumType.STRING)`.

### Repository — `repository/ClienteRepository.java`

Es una interfaz que extiende `JpaRepository<Cliente, Long>`. No escribo SQL para el
CRUD: Spring Data genera `save`, `findAll`, `findById` y `delete`. Agrego
`existsByDocumento` y `existsByDocumentoAndIdNot` para validar el DNI único.

### Service — `services/ClienteService.java`

Contiene las reglas de negocio: listar, obtener, crear, actualizar y eliminar. Antes de
crear verifica el DNI duplicado y lanza `BusinessException` (409). Si no encuentra un
ID lanza `ResourceNotFoundException` (404). Está anotado con `@Service` y usa
`@Transactional` para las operaciones de escritura.

### Controller — `controller/ClienteController.java`

Solo recibe HTTP y delega al servicio. Tiene `@RestController` y
`@RequestMapping("/api/clientes")`. Usa `@GetMapping`, `@PostMapping`,
`@PutMapping` y `@DeleteMapping`. El POST devuelve
`ResponseEntity.status(HttpStatus.CREATED)` y el DELETE devuelve 204.

### Errores — `exception/GlobalExceptionHandler.java`

Está anotado con `@RestControllerAdvice`. Cada método tiene `@ExceptionHandler` para
un tipo de excepción y construye el mismo `ErrorResponse`. Ahí se concentra la
traducción de excepciones a códigos HTTP, sin repetir `try/catch` en cada controlador.

---

## 6. Cambios pequeños que el profesor podría pedir en vivo

### A. Agregar el campo `direccion` a Cliente

Archivos exactos:

1. `sql/01_schema.sql`: agregar `direccion VARCHAR(150) NULL` a la tabla `cliente`.
   En `dev`, Hibernate también lo crea con `update`; en `prod` hay que ejecutar el
   `ALTER TABLE` o volver a correr el script.
2. `ms-cliente/src/main/java/com/tecsup/cliente/model/Cliente.java`: agregar el
   atributo `private String direccion;` con `@Column(length = 150)` y sus getters y
   setters.
3. `ms-cliente/src/main/java/com/tecsup/cliente/dto/ClienteRequest.java`: agregar
   `private String direccion;` con `@Size(max = 150)`.
4. `ms-cliente/src/main/java/com/tecsup/cliente/dto/ClienteResponse.java`: agregar el
   campo, sus getters/setters y la línea `dto.setDireccion(cliente.getDireccion());`
   dentro de `from`.
5. `ms-cliente/src/main/java/com/tecsup/cliente/services/ClienteService.java`:
   agregar `cliente.setDireccion(request.getDireccion());` en `aplicarDatos`.

### B. Agregar `GET /api/vehiculos/disponibles`

1. `ms-vehiculo/.../repository/VehiculoRepository.java`:
   `List<Vehiculo> findByEstadoOrderByIdAsc(EstadoVehiculo estado);`
2. `ms-vehiculo/.../services/VehiculoService.java`: nuevo método
   `listarDisponibles()` que llame a
   `vehiculoRepository.findByEstadoOrderByIdAsc(EstadoVehiculo.DISPONIBLE)` y mapee a
   `VehiculoResponse`.
3. `ms-vehiculo/.../controller/VehiculoController.java`: agregar
   `@GetMapping("/disponibles")` antes o después de `/{id}` (Spring prioriza la ruta
   literal) y llamar a `vehiculoService.listarDisponibles()`.

### C. Agregar una validación de formato de placa

En `ms-vehiculo/.../dto/VehiculoRequest.java`, sobre el campo `placa`:

```java
@Pattern(regexp = "[A-Z]{3}-\\d{3}", message = "La placa debe tener el formato ABC-123")
```

Hay que agregar el import `jakarta.validation.constraints.Pattern`. El
`GlobalExceptionHandler` ya devuelve el error por campo automáticamente, sin tocar
nada más.

### D. Cambiar la regla del importe

En `ms-alquiler/.../services/AlquilerService.java`, método `calcularImporte`
(línea 201). Por ejemplo, para un recargo del 10 %:

```java
BigDecimal subtotal = tarifa.multiply(BigDecimal.valueOf(dias));
return subtotal.multiply(new BigDecimal("1.10")).setScale(2, RoundingMode.HALF_UP);
```

No hay que cambiar el DTO ni la tabla: el importe se sigue calculando en el servicio.

### E. Agregar una regla de mínimo de días

En el mismo `calcularImporte`, después de obtener `dias`:

```java
if (dias < 2) {
    throw new BadRequestException("El alquiler debe tener al menos 2 días");
}
```

`BadRequestException` ya está manejada como 400.

---

## 7. Demo sugerida (1 minuto)

1. Mostrar los tres servicios arriba y las tres bases en MySQL.
2. `POST /api/clientes` con DNI nuevo → 201.
3. `POST /api/vehiculos` con placa nueva y tarifa 150 → 201.
4. `POST /api/alquileres` del 6 al 9 de noviembre → 201 e importe **450.00**.
5. `GET /api/vehiculos/{id}` → estado `ALQUILADO`.
6. Repetir el POST con el vehículo en mantenimiento (id 5) → **409**.
7. Enviar fechas pasadas → **400**.
8. Detener ms-cliente y crear un alquiler → **503**.
9. Reiniciar ms-cliente, finalizar el alquiler → 200 y el vehículo vuelve a
   `DISPONIBLE`.

Con eso se cubren comunicación, persistencia, cálculo, validación y manejo de errores.
