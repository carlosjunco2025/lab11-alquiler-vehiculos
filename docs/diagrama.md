# Diagramas del Laboratorio 11

## 1. Arquitectura de microservicios

```mermaid
flowchart LR
    Usuario["Cliente HTTP / Postman<br/>curl"]

    subgraph Cliente["ms-cliente — puerto 8081"]
        direction TB
        CC["ClienteController<br/>/api/clientes"]
        CS["ClienteService<br/>validaciones y DNI único"]
        CR["ClienteRepository<br/>JpaRepository"]
        DB1[("bd_cliente<br/>tabla cliente")]
        CC --> CS --> CR --> DB1
    end

    subgraph Vehiculo["ms-vehiculo — puerto 8082"]
        direction TB
        VC["VehiculoController<br/>/api/vehiculos"]
        VS["VehiculoService<br/>placa única y estados"]
        VR["VehiculoRepository<br/>JpaRepository"]
        DB2[("bd_vehiculo<br/>tabla vehiculo")]
        VC --> VS --> VR --> DB2
    end

    subgraph Alquiler["ms-alquiler — puerto 8083"]
        direction TB
        AC["AlquilerController<br/>/api/alquileres"]
        AS["AlquilerService<br/>fechas, importe y estados"]
        AR["AlquilerRepository<br/>JpaRepository"]
        DB3[("bd_alquiler<br/>tabla alquiler")]
        AC --> AS --> AR --> DB3
    end

    Usuario -->|"CRUD clientes"| CC
    Usuario -->|"CRUD vehículos"| VC
    Usuario -->|"CRUD alquileres"| AC

    AS -->|"GET /api/clientes/{id}<br/>verifica existencia"| CC
    AS -->|"GET /api/vehiculos/{id}<br/>verifica existencia y tarifa"| VC
    AS -->|"PATCH /api/vehiculos/{id}/estado<br/>ALQUILADO / DISPONIBLE"| VC
```

**Responsabilidades y límites:**

| Servicio | Responsabilidad | Datos que posee | No posee |
|---|---|---|---|
| ms-cliente | Datos personales y estado del cliente | `bd_cliente.cliente` | Vehículos ni alquileres |
| ms-vehiculo | Catálogo, tarifa y estado del vehículo | `bd_vehiculo.vehiculo` | Clientes ni alquileres |
| ms-alquiler | Contrato de alquiler y cálculo del importe | `bd_alquiler.alquiler` | Datos personales ni datos del vehículo |

La comunicación es **solo por HTTP con IDs**. No hay llaves foráneas entre las tres
bases y no existe una tabla compartida.

---

## 2. Diagrama ER — bd_cliente

```mermaid
erDiagram
    CLIENTE {
        bigint id PK
        varchar nombres
        varchar apellidos
        varchar documento UK "8 dígitos, único"
        varchar correo
        varchar telefono "9 dígitos"
        varchar estado "ACTIVO o INACTIVO"
    }
```

- `id` es `BIGINT AUTO_INCREMENT`.
- `documento` tiene índice `UNIQUE` (`uk_cliente_documento`).
- `estado` se guarda como `VARCHAR(20)`.

---

## 3. Diagrama ER — bd_vehiculo

```mermaid
erDiagram
    VEHICULO {
        bigint id PK
        varchar placa UK "única"
        varchar marca
        varchar modelo
        int anio
        decimal tarifa_diaria
        varchar estado "DISPONIBLE, ALQUILADO o MANTENIMIENTO"
    }
```

- `placa` tiene índice `UNIQUE` (`uk_vehiculo_placa`).
- `tarifa_diaria` es `DECIMAL(10,2)`.
- `estado` es `VARCHAR(20)` y se indexa para consultas por disponibilidad.

---

## 4. Diagrama ER — bd_alquiler

```mermaid
erDiagram
    ALQUILER {
        bigint id PK
        bigint id_cliente "referencia lógica a bd_cliente.cliente.id"
        bigint id_vehiculo "referencia lógica a bd_vehiculo.vehiculo.id"
        date fecha_inicio
        date fecha_fin
        decimal tarifa_diaria
        decimal importe_estimado "días x tarifa"
        varchar estado "ACTIVO, FINALIZADO o CANCELADO"
    }
```

- **No hay FK** hacia `bd_cliente` ni `bd_vehiculo`: son bases distintas.
- `id_cliente` e `id_vehiculo` son referencias lógicas que se validan por HTTP antes
  de guardar.
- `importe_estimado` es `DECIMAL(10,2)` y lo calcula `AlquilerService`.

---

## 5. Flujo de estados entre alquiler y vehículo

```mermaid
stateDiagram-v2
    [*] --> DISPONIBLE
    DISPONIBLE --> ALQUILADO: POST /api/alquileres
    ALQUILADO --> DISPONIBLE: PATCH /alquileres/{id}/finalizar
    ALQUILADO --> DISPONIBLE: PATCH /alquileres/{id}/cancelar
    ALQUILADO --> DISPONIBLE: DELETE /alquileres/{id}
    DISPONIBLE --> MANTENIMIENTO: PATCH /vehiculos/{id}/estado
    MANTENIMIENTO --> DISPONIBLE: PATCH /vehiculos/{id}/estado
    DISPONIBLE --> ALQUILADO: alquiler creado
```

El estado del alquiler también cambia:

```mermaid
stateDiagram-v2
    [*] --> ACTIVO: POST
    ACTIVO --> FINALIZADO: PATCH /finalizar
    ACTIVO --> CANCELADO: PATCH /cancelar
```

---

## 6. Secuencia de creación de un alquiler

```mermaid
sequenceDiagram
    actor U as Usuario
    participant A as ms-alquiler
    participant C as ms-cliente
    participant V as ms-vehiculo
    participant DB as bd_alquiler

    U->>A: POST /api/alquileres
    A->>A: valida fechas
    A->>C: GET /api/clientes/{idCliente}
    alt cliente no existe
        C-->>A: 404
        A-->>U: 404 "Cliente no encontrado"
    else cliente existe
        C-->>A: 200
        A->>V: GET /api/vehiculos/{idVehiculo}
        alt vehículo no existe
            V-->>A: 404
            A-->>U: 404 "Vehículo no encontrado"
        else vehículo existe pero no está DISPONIBLE
            V-->>A: 200 con estado MANTENIMIENTO/ALQUILADO
            A-->>U: 409
        else vehículo DISPONIBLE
            V-->>A: 200 con tarifa
            A->>A: importe = días × tarifa
            A->>DB: INSERT alquiler ACTIVO
            A->>V: PATCH estado = ALQUILADO
            V-->>A: 200
            A-->>U: 201 con importe calculado
        end
    end
```

Si `ms-cliente` o `ms-vehiculo` no están disponibles, el `RestClient` lanza una
`ExternalServiceException` y el handler responde **503**.
