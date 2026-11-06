# Conclusiones — Laboratorio 11

**Carlos Fernando Junco Santiago — Sección D**

## 1. Separar por bases de datos obliga a diseñar las referencias

Entendí que "database per service" no significa solo crear tres bases con nombres
distintos. En `bd_alquiler` tuve que guardar `id_cliente` e `id_vehiculo` como
columnas `BIGINT` sin llave foránea, porque MySQL no puede validar una FK contra una
base que pertenece a otro microservicio. La integridad la terminé resolviendo en
`AlquilerService`: antes de guardar consulto a ms-cliente y a ms-vehiculo por HTTP.
Esto también me hizo ver por qué el `ddl-auto=validate` del perfil `prod` es útil:
si la entidad y el script SQL se separan, el servicio no arranca y el error aparece
temprano.

## 2. RestClient es suficiente para comunicar servicios sin infraestructura extra

Al principio pensé que necesitaba Eureka o un Gateway para que ms-alquiler encontrara
a los otros servicios, pero el laboratorio pedía justamente lo contrario. Con
`RestClient` y dos propiedades (`clientes.url` y `vehiculos.url`) pude hacer las
llamadas `GET` y `PATCH`. Lo importante fue traducir los errores: un 404 remoto se
convierte en `ResourceNotFoundException` local, y una conexión rechazada se convierte
en `ExternalServiceException`, que responde 503. Así el usuario de la API no recibe
un error 500 genérico cuando un servicio vecino está caído.

## 3. El cálculo del importe debe quedar en el servicio, no en el cliente

Implementé `importeEstimado = ChronoUnit.DAYS.between(fechaInicio, fechaFin) × tarifaDiaria`
dentro de `AlquilerService.calcularImporte`, usando `BigDecimal` con escala 2 y
`RoundingMode.HALF_UP`. El DTO no tiene el campo `importeEstimado`, así que el cliente
no puede manipularlo. También aprendí que `ChronoUnit.DAYS.between` puede dar 0 si las
fechas son iguales, por eso la validación exige que `fechaFin` sea posterior y además
dejé un mínimo de 1 día como protección. La tarifa es opcional: si no llega en el
JSON, se toma la del vehículo consultado.

## 4. Las validaciones del DTO y el handler global evitan repetir código

Usé `@NotBlank`, `@Pattern`, `@Email`, `@DecimalMin` y `@NotNull` en los DTO. Eso
produce un `MethodArgumentNotValidException` que atrapo una sola vez en
`GlobalExceptionHandler` y convierto en una lista de errores por campo. Gracias a eso,
los tres servicios responden con el mismo JSON (`timestamp`, `status`, `error`,
`message`, `path`, `errors`) y el frontend o Postman pueden mostrar el campo exacto
que falló. Separé las excepciones por intención: `BadRequestException` para 400,
`BusinessException` para 409, `ResourceNotFoundException` para 404 y
`ExternalServiceException` para 503.

## 5. El estado del vehículo es una máquina de estados compartida por dos servicios

El alquiler no solo inserta una fila: también cambia el estado del vehículo. Al crear
un alquiler, ms-alquiler llama a `PATCH /api/vehiculos/{id}/estado` con `ALQUILADO`;
al finalizar, cancelar o eliminar un alquiler activo, lo devuelve a `DISPONIBLE`.
Esto me obligó a pensar en el orden de las operaciones y en las transacciones. Si el
vehículo está en `MANTENIMIENTO` o `ALQUILADO`, el servicio responde 409 antes de
guardar. Y si ms-vehiculo no responde durante el `PATCH`, la excepción hace rollback
de la transacción y el alquiler no queda persistido.

## Dificultad encontrada y solución

La dificultad más concreta fue mantener coherentes dos bases distintas cuando se crea
un alquiler. Mi primera versión guardaba el alquiler y después intentaba marcar el
vehículo; si la segunda llamada fallaba, quedaba un alquiler `ACTIVO` con un vehículo
que seguía `DISPONIBLE`. Lo resolví dejando todo el método `crear` dentro de
`@Transactional`: guardo el alquiler, llamo inmediatamente al `PATCH` y, si el
`RestClient` lanza `ExternalServiceException`, Spring hace rollback del `INSERT`.
Además probé el caso real deteniendo ms-cliente: la API respondió 503 con
`"El servicio de clientes no está disponible"` y no se creó ningún alquiler. No es
una solución de consistencia distribuida perfecta —para eso harían falta patrones como
Saga o una cola—, pero para el alcance del laboratorio deja el flujo principal
controlado y explicable.
