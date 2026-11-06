# Genera docs\Documentacion-Lab11.docx con Word COM.
# Requiere Microsoft Word instalado.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$imgDir = Join-Path $root 'docs\img'
$outPath = Join-Path $root 'docs\Documentacion-Lab11.docx'
$logPath = Join-Path $root 'docs\word-generacion.txt'

Add-Type -AssemblyName Microsoft.VisualBasic

function RGB([int]$r, [int]$g, [int]$b) { return $r + ($g * 256) + ($b * 65536) }

$dark = RGB 15 23 42
$primary = RGB 37 99 235
$primaryDark = RGB 29 78 216
$teal = RGB 13 148 136
$muted = RGB 100 116 139
$gray = RGB 148 163 184
$white = RGB 255 255 255
$codeBg = RGB 241 245 249
$rowBg = RGB 248 250 252

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$word.Options.BackgroundSave = $false
$word.Options.SaveInterval = 0

$doc = $word.Documents.Add()
$sel = $word.Selection
$script:fig = 0
$script:tab = 0

# ---------- Configuracion de pagina y estilos ----------
$ps = $doc.PageSetup
$ps.PageWidth = $word.CentimetersToPoints(21)
$ps.PageHeight = $word.CentimetersToPoints(29.7)
$ps.TopMargin = $word.CentimetersToPoints(2.2)
$ps.BottomMargin = $word.CentimetersToPoints(2.0)
$ps.LeftMargin = $word.CentimetersToPoints(2.2)
$ps.RightMargin = $word.CentimetersToPoints(2.2)
$ps.DifferentFirstPageHeaderFooter = -1

$normal = $doc.Styles.Item(-1)
$normal.Font.Name = 'Segoe UI'
$normal.Font.Size = 10.5
$normal.Font.Color = $dark
$normal.ParagraphFormat.SpaceAfter = 6
$normal.ParagraphFormat.LineSpacingRule = 0

$h1 = $doc.Styles.Item(-2)
$h1.Font.Name = 'Segoe UI'
$h1.Font.Size = 18
$h1.Font.Bold = $true
$h1.Font.Color = $primaryDark
$h1.ParagraphFormat.SpaceBefore = 16
$h1.ParagraphFormat.SpaceAfter = 8
$h1.ParagraphFormat.KeepWithNext = $true

$h2 = $doc.Styles.Item(-3)
$h2.Font.Name = 'Segoe UI'
$h2.Font.Size = 13.5
$h2.Font.Bold = $true
$h2.Font.Color = $dark
$h2.ParagraphFormat.SpaceBefore = 12
$h2.ParagraphFormat.SpaceAfter = 5
$h2.ParagraphFormat.KeepWithNext = $true

$h3 = $doc.Styles.Item(-4)
$h3.Font.Name = 'Segoe UI'
$h3.Font.Size = 11.5
$h3.Font.Bold = $true
$h3.Font.Color = $teal
$h3.ParagraphFormat.SpaceBefore = 10
$h3.ParagraphFormat.SpaceAfter = 4
$h3.ParagraphFormat.KeepWithNext = $true

# ---------- Funciones auxiliares ----------
function Reset-Format {
    $script:sel.Style = $script:doc.Styles.Item(-1)
    $f = $script:sel.Font
    $f.Name = 'Segoe UI'; $f.Size = 10.5; $f.Bold = $false; $f.Italic = $false; $f.Color = $script:dark
    $p = $script:sel.ParagraphFormat
    $p.Alignment = 3; $p.SpaceBefore = 0; $p.SpaceAfter = 6
    $p.LeftIndent = 0; $p.FirstLineIndent = 0
    $p.LineSpacingRule = 0
    $p.Shading.BackgroundPatternColor = $script:white
}

function Add-Body([string]$text) {
    Reset-Format
    $script:sel.TypeText($text)
    $script:sel.TypeParagraph()
}

function Add-Heading([string]$text, [int]$level) {
    $styleId = -2 - ($level - 1)
    $script:sel.Style = $script:doc.Styles.Item($styleId)
    $script:sel.TypeText($text)
    $script:sel.TypeParagraph()
}

function Add-Bullet([string]$text) {
    Reset-Format
    $p = $script:sel.ParagraphFormat
    $p.Alignment = 0
    $p.LeftIndent = $script:word.CentimetersToPoints(0.75)
    $p.FirstLineIndent = $script:word.CentimetersToPoints(-0.35)
    $script:sel.TypeText([string][char]0x2022 + '  ' + $text)
    $script:sel.TypeParagraph()
}

function Add-Numbered([int]$n, [string]$text) {
    Reset-Format
    $p = $script:sel.ParagraphFormat
    $p.Alignment = 0
    $p.LeftIndent = $script:word.CentimetersToPoints(0.85)
    $p.FirstLineIndent = $script:word.CentimetersToPoints(-0.45)
    $script:sel.TypeText("$n.  $text")
    $script:sel.TypeParagraph()
}

function Add-Spacer([double]$cm = 0.3) {
    Reset-Format
    $script:sel.ParagraphFormat.SpaceAfter = 0
    $script:sel.TypeParagraph()
}

function Add-PageBreak {
    $script:sel.InsertBreak(7)
}

function Add-MonoBlock([string[]]$lines) {
    Reset-Format
    $f = $script:sel.Font
    $f.Name = 'Consolas'; $f.Size = 8.5; $f.Color = $script:dark
    $p = $script:sel.ParagraphFormat
    $p.Alignment = 0
    $p.SpaceBefore = 0; $p.SpaceAfter = 0
    $p.LeftIndent = $script:word.CentimetersToPoints(0.45)
    $p.FirstLineIndent = 0
    $p.Shading.BackgroundPatternColor = $script:codeBg
    foreach ($line in $lines) {
        $script:sel.TypeText($line)
        $script:sel.TypeParagraph()
    }
    Reset-Format
    $script:sel.TypeParagraph()
}

function Add-Figure([string]$relativePath, [string]$caption, [double]$widthCm = 15.5) {
    $path = Join-Path $script:root $relativePath
    if (-not (Test-Path $path)) { throw "No existe la imagen $path" }
    Reset-Format
    $p = $script:sel.ParagraphFormat
    $p.Alignment = 1
    $p.SpaceBefore = 6; $p.SpaceAfter = 2
    $p.KeepWithNext = $true
    $shape = $script:sel.InlineShapes.AddPicture($path, $false, $true)
    $shape.LockAspectRatio = -1
    $shape.Width = $script:word.CentimetersToPoints($widthCm)
    $script:sel.TypeParagraph()
    $script:fig++
    Reset-Format
    $p = $script:sel.ParagraphFormat
    $p.Alignment = 1; $p.SpaceAfter = 10
    $script:sel.Font.Size = 8.5
    $script:sel.Font.Italic = $true
    $script:sel.Font.Color = $script:muted
    $script:sel.TypeText("Figura $($script:fig). $caption")
    $script:sel.TypeParagraph()
    Reset-Format
}

function Add-Table([string]$caption, [string[]]$headers, [object[]]$rows, [double[]]$widths) {
    $script:tab++
    Reset-Format
    $script:sel.ParagraphFormat.Alignment = 0
    $script:sel.ParagraphFormat.SpaceBefore = 4
    $script:sel.ParagraphFormat.SpaceAfter = 3
    $script:sel.Font.Size = 8.5
    $script:sel.Font.Italic = $true
    $script:sel.Font.Color = $script:muted
    $script:sel.TypeText("Tabla $($script:tab). $caption")
    $script:sel.TypeParagraph()

    $table = $script:doc.Tables.Add($script:sel.Range, $rows.Count + 1, $headers.Count)
    $table.Borders.Enable = $true
    $table.Borders.OutsideLineStyle = 1
    $table.Borders.InsideLineStyle = 1
    $table.Borders.OutsideColor = $script:gray
    $table.Borders.InsideColor = $script:gray
    $table.AllowAutoFit = $false
    $table.Range.Font.Name = 'Segoe UI'
    $table.Range.Font.Size = 8.5
    $table.Range.ParagraphFormat.SpaceAfter = 1
    $table.Range.ParagraphFormat.SpaceBefore = 1
    $table.Range.ParagraphFormat.LineSpacingRule = 0

    for ($c = 1; $c -le $headers.Count; $c++) {
        $cell = $table.Cell(1, $c)
        $cell.Range.Text = $headers[$c - 1]
        $cell.Range.Font.Bold = $true
        $cell.Range.Font.Color = $script:white
        $cell.Shading.BackgroundPatternColor = $script:primary
    }
    $table.Rows.Item(1).HeadingFormat = $true

    for ($r = 0; $r -lt $rows.Count; $r++) {
        for ($c = 0; $c -lt $headers.Count; $c++) {
            $cell = $table.Cell($r + 2, $c + 1)
            $cell.Range.Text = [string]$rows[$r][$c]
            if ($r % 2 -eq 1) { $cell.Shading.BackgroundPatternColor = $script:rowBg }
        }
    }

    for ($c = 1; $c -le $widths.Count; $c++) {
        $table.Columns.Item($c).Width = $script:word.CentimetersToPoints($widths[$c - 1])
    }

    $script:sel.EndKey(6) | Out-Null
    Reset-Format
    $script:sel.TypeParagraph()
}

# ---------- Encabezado y pie ----------
$header = $doc.Sections.Item(1).Headers.Item(1)
$header.Range.Text = "Laboratorio 11  ·  Sistema de alquiler de vehículos"
$header.Range.Font.Name = 'Segoe UI'
$header.Range.Font.Size = 8
$header.Range.Font.Color = $gray
$header.Range.ParagraphFormat.Alignment = 2

$footer = $doc.Sections.Item(1).Footers.Item(1)
$footer.Range.Text = "Documentación técnica  ·  Página "
$footer.Range.Font.Name = 'Segoe UI'
$footer.Range.Font.Size = 8
$footer.Range.Font.Color = $gray
$footer.Range.ParagraphFormat.Alignment = 1
$footer.Range.Collapse(0)
$footer.Range.Fields.Add($footer.Range, 33) | Out-Null

try {
    # ================= PORTADA =================
    Reset-Format
    $sel.ParagraphFormat.Alignment = 0
    $sel.ParagraphFormat.SpaceAfter = 0
    $sel.ParagraphFormat.Shading.BackgroundPatternColor = $primary
    $sel.Font.Name = 'Segoe UI'; $sel.Font.Size = 10; $sel.Font.Bold = $true; $sel.Font.Color = $white
    $sel.TypeText("   LABORATORIO 11   ·   MICROSERVICIOS")
    $sel.TypeParagraph()

    Reset-Format
    $sel.ParagraphFormat.SpaceAfter = 0
    $sel.TypeParagraph()
    $sel.TypeParagraph()

    $sel.Font.Name = 'Segoe UI'; $sel.Font.Size = 31; $sel.Font.Bold = $true; $sel.Font.Color = $dark
    $sel.ParagraphFormat.Alignment = 0
    $sel.ParagraphFormat.SpaceAfter = 8
    $sel.TypeText("Sistema de alquiler de vehículos")
    $sel.TypeParagraph()

    $sel.Font.Size = 14; $sel.Font.Bold = $false; $sel.Font.Color = $muted
    $sel.ParagraphFormat.SpaceAfter = 2
    $sel.TypeText("Arquitectura de microservicios con Spring Boot, MySQL y frontend web")
    $sel.TypeParagraph()

    $sel.Font.Size = 10.5; $sel.Font.Color = $primary
    $sel.TypeText("Tres servicios independientes  ·  una base de datos por servicio  ·  panel web integrado")
    $sel.TypeParagraph()

    $sel.TypeParagraph()

    $meta = $doc.Tables.Add($sel.Range, 6, 2)
    $meta.Borders.Enable = $false
    $meta.AllowAutoFit = $false
    $meta.Columns.Item(1).Width = $word.CentimetersToPoints(4.2)
    $meta.Columns.Item(2).Width = $word.CentimetersToPoints(12.2)
    $metaData = @(
        @('Estudiante', 'Carlos Fernando Junco Santiago'),
        @('Sección', 'D'),
        @('Proyecto', 'lab11-alquiler-vehiculos'),
        @('Tecnologías', 'Java 17 · Spring Boot 3.3.5 · MySQL 8 · HTML, CSS y JavaScript'),
        @('Servicios', 'ms-cliente :8081 · ms-vehiculo :8082 · ms-alquiler :8083'),
        @('Fecha', 'Noviembre de 2026')
    )
    for ($r = 0; $r -lt $metaData.Count; $r++) {
        $c1 = $meta.Cell($r + 1, 1)
        $c1.Range.Text = $metaData[$r][0]
        $c1.Range.Font.Bold = $true
        $c1.Range.Font.Size = 9.5
        $c1.Range.Font.Color = $muted
        $c2 = $meta.Cell($r + 1, 2)
        $c2.Range.Text = $metaData[$r][1]
        $c2.Range.Font.Size = 9.5
        $c2.Range.Font.Color = $dark
    }

    $sel.EndKey(6) | Out-Null
    $sel.TypeParagraph()
    $sel.ParagraphFormat.Alignment = 1
    $cover = $sel.InlineShapes.AddPicture((Join-Path $imgDir 'dashboard.png'), $false, $true)
    $cover.LockAspectRatio = -1
    $cover.Width = $word.CentimetersToPoints(13.2)
    $sel.TypeParagraph()

    Add-PageBreak

    # ================= CONTENIDO =================
    Reset-Format
    $sel.ParagraphFormat.Alignment = 0
    $sel.Font.Size = 22; $sel.Font.Bold = $true; $sel.Font.Color = $primaryDark
    $sel.ParagraphFormat.SpaceAfter = 10
    $sel.TypeText("Contenido")
    $sel.TypeParagraph()

    $toc = $doc.TablesOfContents.Add($sel.Range, $true, 1, 3)
    $sel.EndKey(6) | Out-Null
    Add-PageBreak

    # ================= 1. INTRODUCCION =================
    Add-Heading "1. Introducción" 1
    Add-Body "El presente documento describe el diseño, la implementación y la verificación del Laboratorio 11, un sistema de gestión de alquiler de vehículos construido con tres microservicios independientes desarrollados en Spring Boot 3.3.5 sobre Java 17, una base de datos MySQL 8 por servicio y un panel web que integra las tres APIs."
    Add-Body "El backend ya se encuentra compilado, ejecutándose y verificado de punta a punta. Sobre esa base se incorporó un frontend sencillo, servido por el propio microservicio de alquileres, que permite operar el sistema sin herramientas externas: registrar clientes, administrar vehículos, crear alquileres y controlar su ciclo de vida."

    Add-Heading "1.1. Objetivo" 2
    Add-Body "Documentar la arquitectura, las responsabilidades de cada microservicio, las carpetas relevantes, el código con las reglas de negocio más importantes y la evidencia real de funcionamiento del sistema, incluyendo capturas del frontend terminado."

    Add-Heading "1.2. Alcance" 2
    Add-Body "El sistema cubre el ciclo completo de un alquiler:"
    Add-Bullet "Registro, edición, consulta y eliminación de clientes."
    Add-Bullet "Registro, edición, consulta y eliminación de vehículos, con control de disponibilidad."
    Add-Bullet "Creación de alquileres con validación de cliente y vehículo, y cálculo automático del importe en el backend."
    Add-Bullet "Finalización, cancelación y eliminación de alquileres, liberando el vehículo cuando corresponde."
    Add-Bullet "Manejo uniforme de errores 400, 404, 409 y 503."
    Add-Bullet "Panel web con tablero, tablas, búsqueda, filtros, formularios modales y mensajes de confirmación."

    # ================= 2. ARQUITECTURA =================
    Add-Heading "2. Arquitectura de la solución" 1
    Add-Heading "2.1. Vista general" 2
    Add-Body "La solución sigue el patrón de microservicios: cada servicio es un proyecto Maven autónomo, con su propio puerto, su propia base de datos y su propio ciclo de despliegue. El frontend se sirve desde ms-alquiler y consume las tres APIs por HTTP."
    Add-MonoBlock @(
        '                 +----------------------------------+',
        '                 |  Navegador - frontend web        |',
        '                 |  http://localhost:8083/          |',
        '                 +----------------+-----------------+',
        '                                  | HTTP/JSON + CORS',
        '                 +----------------v-----------------+',
        '                 |  ms-alquiler  :8083              |',
        '                 |  /api/alquileres                 |',
        '                 |  bd_alquiler                     |',
        '                 +-------+----------------+---------+',
        '                         |                |',
        '          GET cliente    |                |  GET / PATCH vehiculo',
        '                         v                v',
        '              +------------------+  +-------------------+',
        '              | ms-cliente :8081 |  | ms-vehiculo :8082 |',
        '              | bd_cliente       |  | bd_vehiculo       |',
        '              +------------------+  +-------------------+'
    )

    Add-Heading "2.2. Comunicación entre servicios" 2
    Add-Body "La comunicación es síncrona y se realiza con RestClient de Spring. El microservicio de alquileres no comparte tablas con los otros servicios: únicamente guarda los identificadores idCliente e idVehiculo. Antes de crear un contrato consulta el cliente y el vehículo por HTTP; si el vehículo está disponible, lo marca como ALQUILADO y, al finalizar o cancelar, lo devuelve a DISPONIBLE."
    Add-Bullet "Frontend hacia ms-cliente, ms-vehiculo y ms-alquiler: peticiones fetch con CORS habilitado."
    Add-Bullet "ms-alquiler hacia ms-cliente: GET /api/clientes/{id} para validar la existencia del cliente."
    Add-Bullet "ms-alquiler hacia ms-vehiculo: GET /api/vehiculos/{id} y PATCH /api/vehiculos/{id}/estado."
    Add-Bullet "Un 404 remoto se traduce en 404 local; un fallo de conexión se traduce en 503; una regla incumplida responde 409."

    Add-Heading "2.3. Puertos y bases de datos" 2
    Add-Table "Distribución de servicios, puertos y bases de datos." @('Servicio', 'Puerto', 'Base de datos', 'Responsabilidad') @(
        @('ms-cliente', '8081', 'bd_cliente', 'CRUD y validación de clientes'),
        @('ms-vehiculo', '8082', 'bd_vehiculo', 'CRUD, tarifas y estado de la flota'),
        @('ms-alquiler', '8083', 'bd_alquiler', 'Contratos, cálculo de importes y coordinación'),
        @('MySQL 8', '3306', 'Tres esquemas', 'Persistencia independiente por servicio')
    ) @(3.2, 1.8, 3.4, 8.2)

    # ================= 3. MICROSERVICIOS =================
    Add-Heading "3. Descripción de los microservicios" 1

    Add-Heading "3.1. ms-cliente (puerto 8081)" 2
    Add-Body "Gestiona la información personal de los clientes. Expone un CRUD REST completo sobre /api/clientes, valida los datos con Bean Validation y garantiza que el documento de identidad sea único."
    Add-Body "Modelo Cliente: id, nombres, apellidos, documento, correo, teléfono y estado (ACTIVO o INACTIVO). El documento debe tener exactamente 8 dígitos, el teléfono 9 dígitos y el correo un formato válido. Los errores se devuelven con un formato JSON uniforme."
    Add-Bullet "POST /api/clientes responde 201 Created y devuelve el cliente con su id."
    Add-Bullet "GET /api/clientes y GET /api/clientes/{id} responden 200 OK."
    Add-Bullet "PUT /api/clientes/{id} actualiza; DELETE /api/clientes/{id} responde 204 No Content."
    Add-Bullet "Un DNI duplicado responde 409 Conflict; un cliente inexistente responde 404 Not Found."

    Add-Heading "3.2. ms-vehiculo (puerto 8082)" 2
    Add-Body "Administra la flota. Cada vehículo tiene placa única, marca, modelo, año, tarifa diaria y estado (DISPONIBLE, ALQUILADO o MANTENIMIENTO). Además del CRUD, expone PATCH /api/vehiculos/{id}/estado, que es el endpoint que utiliza ms-alquiler para sincronizar la disponibilidad."
    Add-Bullet "La placa es única y se valida contra duplicados."
    Add-Bullet "La tarifa se almacena como DECIMAL(10,2) y se usa para calcular el importe del alquiler."
    Add-Bullet "No se permite alquilar un vehículo que no esté en estado DISPONIBLE."
    Add-Bullet "El cambio de estado se realiza con un cuerpo JSON simple: { ""estado"": ""ALQUILADO"" }."

    Add-Heading "3.3. ms-alquiler (puerto 8083)" 2
    Add-Body "Es el servicio central del negocio. Registra los contratos, valida las fechas, comprueba por HTTP que el cliente y el vehículo existan, verifica la disponibilidad, calcula el importe y sincroniza el estado del vehículo. También sirve el frontend web desde la raíz del servicio."
    Add-Body "Reglas principales:"
    Add-Bullet "La fecha de inicio no puede estar en el pasado y la fecha de fin debe ser posterior a la de inicio."
    Add-Bullet "El importe nunca se recibe desde el cliente: se calcula como días calendario por tarifa diaria, con un mínimo de un día, BigDecimal y redondeo HALF_UP."
    Add-Bullet "Si el DTO no incluye tarifa, se toma la tarifa registrada en el vehículo."
    Add-Bullet "Solo un alquiler ACTIVO puede actualizarse, finalizarse o cancelarse."
    Add-Bullet "Al finalizar o cancelar, el vehículo vuelve a DISPONIBLE; al eliminar un alquiler activo también se libera."

    Add-Heading "3.4. Frontend web" 2
    Add-Body "El panel se construyó con HTML, CSS y JavaScript vanilla, sin frameworks ni herramientas de compilación. Se publica desde src/main/resources/static de ms-alquiler, por lo que se abre en http://localhost:8083/ y no requiere un cuarto servidor."
    Add-Body "Incluye un tablero con indicadores y estado de los tres servicios, tablas con búsqueda y filtros, formularios modales para clientes, vehículos y alquileres, acciones de edición, eliminación, finalización y cancelación, notificaciones tipo toast y una vista previa del importe antes de registrar el alquiler."

    # ================= 4. CARPETAS =================
    Add-Heading "4. Estructura de carpetas importantes" 1
    Add-Body "Los tres proyectos comparten la misma organización interna. La separación por capas facilita el mantenimiento y deja explícita la responsabilidad de cada paquete."
    Add-MonoBlock @(
        'lab11-alquiler-vehiculos/',
        '|-- ms-cliente/',
        '|   `-- src/main/java/com/tecsup/cliente/',
        '|       |-- controller/    ClienteController.java',
        '|       |-- services/      ClienteService.java',
        '|       |-- repository/    ClienteRepository.java',
        '|       |-- model/         Cliente.java, EstadoCliente.java',
        '|       |-- dto/           ClienteRequest.java, ClienteResponse.java',
        '|       |-- exception/     GlobalExceptionHandler.java y errores',
        '|       `-- config/        WebConfig.java (CORS)',
        '|-- ms-vehiculo/',
        '|   `-- src/main/java/com/tecsup/vehiculo/  (misma organización)',
        '|-- ms-alquiler/',
        '|   |-- src/main/java/com/tecsup/alquiler/',
        '|   |   |-- controller/    AlquilerController.java',
        '|   |   |-- services/      AlquilerService.java',
        '|   |   |                  ClienteClientService.java',
        '|   |   |                  VehiculoClientService.java',
        '|   |   |-- repository/    AlquilerRepository.java',
        '|   |   |-- model/         Alquiler.java, EstadoAlquiler.java',
        '|   |   |-- dto/           AlquilerRequest/Response, DTOs remotos',
        '|   |   |-- exception/     Errores y manejador global',
        '|   |   `-- config/        WebConfig.java (CORS)',
        '|   `-- src/main/resources/',
        '|       |-- static/        index.html, css/styles.css, js/app.js',
        '|       `-- application*.yml',
        '|-- sql/                   01_schema.sql, 02_data.sql',
        '|-- postman/               colección con 35 requests',
        '|-- docs/                  evidencias, diagramas, imágenes y este Word',
        '`-- README.md'
    )

    Add-Table "Rol de las carpetas principales." @('Carpeta', 'Contenido', 'Para qué sirve') @(
        @('controller/', 'Clases @RestController', 'Define las rutas HTTP y los códigos de respuesta.'),
        @('services/', 'Lógica de negocio', 'Valida reglas, calcula importes y coordina llamadas remotas.'),
        @('repository/', 'Interfaces JpaRepository', 'Acceso a datos sin escribir SQL manual.'),
        @('model/', 'Entidades y enums', 'Representan las tablas y los estados del dominio.'),
        @('dto/', 'Request y Response', 'Separan el contrato de la API del modelo persistente.'),
        @('exception/', 'Excepciones y handler', 'Traducen errores a un JSON uniforme.'),
        @('config/', 'WebConfig', 'Habilitan CORS para el frontend.'),
        @('resources/static/', 'HTML, CSS y JS', 'Publican el panel web desde ms-alquiler.')
    ) @(3.2, 4.6, 8.8)

    # ================= 5. CODIGO =================
    Add-PageBreak
    Add-Heading "5. Código importante" 1
    Add-Body "Las siguientes capturas corresponden al código fuente real del proyecto. Se seleccionaron los fragmentos que explican las decisiones centrales: reglas de negocio, integración entre servicios, manejo de errores, configuración y persistencia."

    Add-Heading "5.1. Reglas de negocio del alquiler" 2
    Add-Body "El método crear() aplica un orden estricto: valida las fechas, confirma que el cliente exista, obtiene el vehículo y comprueba su disponibilidad, resuelve la tarifa, calcula el importe, guarda el alquiler y finalmente marca el vehículo como ALQUILADO. El cálculo se hace con BigDecimal y ChronoUnit.DAYS, nunca con el importe enviado por el cliente."
    Add-Figure 'docs\img\code-alquiler-service.png' 'AlquilerService: creación del contrato y cálculo del importe estimado.' 15.5
    Add-Body "La anotación @Transactional garantiza que la operación de base de datos sea atómica. Si la llamada remota para cambiar el estado del vehículo falla, la transacción se revierte y el alquiler no queda registrado."

    Add-Heading "5.2. Integración con ms-cliente" 2
    Add-Body "ClienteClientService encapsula la llamada HTTP. La URL base se inyecta desde application.yml, de modo que puede cambiarse con la variable de entorno MS_CLIENTE_URL sin recompilar. Un 404 del servicio remoto se convierte en ResourceNotFoundException (404 local) y un fallo de conexión en ExternalServiceException (503)."
    Add-Figure 'docs\img\code-cliente-client.png' 'ClienteClientService: consulta del cliente y traducción de errores HTTP.' 15.5

    Add-Heading "5.3. Integración con ms-vehiculo" 2
    Add-Body "Este servicio realiza dos operaciones: obtener los datos del vehículo para validar disponibilidad y tarifa, y cambiar su estado mediante PATCH. El cuerpo se envía como un Map con la clave estado. El mismo tratamiento de errores se aplica a ambas llamadas."
    Add-Figure 'docs\img\code-vehiculo-client.png' 'VehiculoClientService: consulta y cambio de estado del vehículo.' 15.5

    Add-Heading "5.4. Manejo uniforme de errores" 2
    Add-Body "Cada microservicio tiene un GlobalExceptionHandler con @RestControllerAdvice. Todas las respuestas de error comparten los campos timestamp, status, error, message, path y errors. Así, el frontend puede mostrar un mensaje claro sin conocer los detalles internos de cada servicio."
    Add-Figure 'docs\img\code-exception-handler.png' 'GlobalExceptionHandler de ms-cliente: excepciones traducidas a respuestas JSON uniformes.' 15.5

    Add-Heading "5.5. API REST de alquileres" 2
    Add-Body "El controlador expone el ciclo de vida completo. POST responde 201 Created, DELETE responde 204 No Content y los PATCH de finalizar y cancelar devuelven el alquiler actualizado. La validación del cuerpo se activa con @Valid."
    Add-Figure 'docs\img\code-controller.png' 'AlquilerController: endpoints y códigos de respuesta del ciclo de vida.' 15.5

    Add-Heading "5.6. Configuración por perfiles" 2
    Add-Body "application.yml define el puerto, el perfil activo y las URLs de los otros microservicios. El perfil dev usa ddl-auto=update y muestra el SQL; el perfil prod usa ddl-auto=validate, oculta el SQL y toma las credenciales de variables de entorno."
    Add-Figure 'docs\img\code-config.png' 'application.yml: puerto, perfil activo y URLs configurables por entorno.' 15.5
    Add-Figure 'docs\img\code-config-prod.png' 'application-prod.yml: configuración segura para producción.' 15.5

    Add-Heading "5.7. Base de datos" 2
    Add-Body "Existen tres bases independientes. No hay llaves foráneas entre ellas: las referencias se guardan como identificadores. La tabla alquiler incluye índices por cliente, vehículo y estado para acelerar las consultas más frecuentes."
    Add-Figure 'docs\img\code-sql.png' 'Esquema SQL: tres bases independientes y tabla de alquileres sin FK cruzadas.' 15.5

    Add-Heading "5.8. CORS" 2
    Add-Body "El frontend se sirve desde el puerto 8083 y consume APIs en 8081, 8082 y 8083. Para permitirlo se agregó una configuración WebConfig en los tres servicios, con soporte para GET, POST, PUT, PATCH, DELETE y OPTIONS."
    Add-Figure 'docs\img\code-cors.png' 'WebConfig: configuración CORS compartida por los tres microservicios.' 15.5

    # ================= 6. FRONTEND =================
    Add-PageBreak
    Add-Heading "6. Frontend web terminado" 1
    Add-Body "El panel se abre en http://localhost:8083/ y consume las tres APIs en tiempo real. Las capturas siguientes se tomaron con el sistema en ejecución y datos reales."

    Add-Heading "6.1. Panel general" 2
    Add-Body "El tablero muestra cuatro indicadores (clientes, vehículos, disponibles y alquileres activos), el estado de los tres microservicios y los últimos alquileres registrados. Los indicadores se actualizan al refrescar y cada tarjeta enlaza visualmente con el servicio que origina el dato."
    Add-Figure 'docs\img\dashboard.png' 'Panel general con indicadores, estado de servicios y alquileres recientes.' 15.5

    Add-Heading "6.2. Gestión de clientes" 2
    Add-Body "La vista de clientes permite buscar por nombre, apellido o DNI, editar un registro y eliminarlo. El formulario valida los campos obligatorios y muestra los errores del backend en un toast."
    Add-Figure 'docs\img\clientes.png' 'Listado de clientes con búsqueda, estado y acciones.' 15.5

    Add-Heading "6.3. Gestión de vehículos" 2
    Add-Body "La vista de vehículos muestra placa, año, tarifa diaria y estado. Incluye búsqueda por placa, marca o modelo y un filtro por DISPONIBLE, ALQUILADO o MANTENIMIENTO."
    Add-Figure 'docs\img\vehiculos.png' 'Flota de vehículos con filtro por estado y tarifa diaria.' 15.5

    Add-Heading "6.4. Gestión de alquileres" 2
    Add-Body "La vista de alquileres muestra el cliente, el vehículo, el periodo, los días, el importe calculado y el estado. Los alquileres activos permiten finalizar o cancelar; todos permiten eliminar. El filtro superior separa activos, finalizados y cancelados."
    Add-Figure 'docs\img\alquileres.png' 'Contratos de alquiler con importe calculado y acciones de ciclo de vida.' 15.5

    Add-Heading "6.5. Formularios modales" 2
    Add-Body "Los formularios se abren en ventanas modales para no perder el contexto de la tabla. El formulario de alquiler solo lista vehículos disponibles y calcula el importe estimado mientras se eligen las fechas."
    Add-Figure 'docs\img\modal-cliente.png' 'Formulario modal para registrar o editar un cliente.' 13.5
    Add-Figure 'docs\img\modal-vehiculo.png' 'Formulario modal para registrar o editar un vehículo.' 13.5
    Add-Figure 'docs\img\modal-alquiler.png' 'Formulario de alquiler con vista previa del importe estimado.' 13.5

    Add-Heading "6.6. Código del frontend" 2
    Add-Body "La función api() centraliza las peticiones fetch, agrega el encabezado Content-Type, aplica un tiempo máximo de espera y convierte las respuestas de error del backend en excepciones con mensaje y lista de campos."
    Add-Figure 'docs\img\code-frontend-api.png' 'app.js: configuración de las APIs y cliente HTTP central.' 15.5
    Add-Body "La vista previa del importe replica la regla del backend para dar retroalimentación inmediata, pero el valor definitivo siempre lo calcula el servidor."
    Add-Figure 'docs\img\code-frontend-calculo.png' 'app.js: cálculo visual de días por tarifa antes de enviar el formulario.' 15.5
    Add-Body "El envío del alquiler valida las fechas en el navegador, arma el DTO con los identificadores y las fechas, y envía únicamente la tarifa si el usuario decidió escribir una."
    Add-Figure 'docs\img\code-frontend-alquiler.png' 'app.js: validaciones y envío del alta de alquiler.' 15.5

    # ================= 7. PRUEBAS =================
    Add-PageBreak
    Add-Heading "7. Servicios en ejecución y pruebas" 1
    Add-Heading "7.1. Evidencia de los servicios" 2
    Add-Body "La siguiente captura muestra salidas reales de los tres servicios: los códigos 200 de cada API, un alquiler consultado por id, la cabecera CORS que autoriza al frontend y el arranque de Tomcat en el puerto 8083."
    Add-Figure 'docs\img\terminal-servicios.png' 'Salidas reales de los tres microservicios y de la cabecera CORS.' 15.5

    Add-Heading "7.2. Tabla de pruebas" 2
    Add-Table "Pruebas funcionales y técnicas ejecutadas sobre el sistema." @('Prueba', 'Acción realizada', 'Resultado obtenido') @(
        @('Compilación', 'mvn clean package -DskipTests en los tres proyectos', 'BUILD SUCCESS en ms-cliente, ms-vehiculo y ms-alquiler.'),
        @('Bases de datos', 'Ejecutar sql/01_schema.sql', 'Tres bases con una tabla cada una y sin llaves foráneas cruzadas.'),
        @('Listado de clientes', 'GET /api/clientes', '200 OK con el arreglo JSON de clientes.'),
        @('Alta de cliente', 'POST /api/clientes con datos válidos', '201 Created y cliente devuelto con id.'),
        @('Validación de DNI', 'POST con documento de 7 dígitos', '400 Bad Request con el detalle del campo documento.'),
        @('Alta de vehículo', 'POST /api/vehiculos con placa única', '201 Created; tarifa almacenada como DECIMAL.'),
        @('Alta de alquiler', 'POST /api/alquileres sin tarifa ni importe', '201 Created; tarifa tomada del vehículo e importe calculado.'),
        @('Cálculo del importe', '3 días por S/ 185.50', 'S/ 556.50 con BigDecimal y redondeo HALF_UP.'),
        @('Sincronización', 'Crear un alquiler', 'El vehículo pasa a ALQUILADO mediante PATCH.'),
        @('Finalización', 'PATCH /api/alquileres/{id}/finalizar', '200 OK; alquiler FINALIZADO y vehículo DISPONIBLE.'),
        @('Fecha inválida', 'fechaInicio en el pasado', '400 Bad Request con mensaje uniforme.'),
        @('Cliente inexistente', 'idCliente = 9999', '404 Not Found con mensaje uniforme.'),
        @('Vehículo no disponible', 'idVehiculo en MANTENIMIENTO', '409 Conflict con mensaje uniforme.'),
        @('Servicio caído', 'Detener ms-cliente y crear un alquiler', '503 Service Unavailable mediante ExternalServiceException.'),
        @('Eliminación', 'DELETE /api/alquileres/{id}', '204 No Content y 404 al volver a consultar.'),
        @('Frontend', 'Abrir http://localhost:8083/', '200 OK, tres servicios en línea y datos visibles.'),
        @('CORS', 'GET con Origin: http://localhost:8083', 'Access-Control-Allow-Origin: http://localhost:8083.')
    ) @(3.4, 6.6, 6.6)

    Add-Heading "7.3. Resultados" 2
    Add-Body "Las pruebas confirman que el flujo completo funciona: cliente, vehículo, alquiler, sincronización, finalización y liberación del vehículo. También se verificó que los errores de validación, los recursos inexistentes, los conflictos de negocio y la caída de un servicio se comunican con códigos HTTP y mensajes consistentes. El frontend no presenta errores en la consola y muestra los tres servicios en línea."

    # ================= 8. EJECUCION =================
    Add-PageBreak
    Add-Heading "8. Cómo ejecutar el proyecto" 1
    Add-Heading "8.1. Requisitos" 2
    Add-Bullet "JDK 17 y Maven 3.9 o superior."
    Add-Bullet "MySQL 8 en el puerto 3306 con el usuario lab11_user (o variables de entorno equivalentes)."
    Add-Bullet "Un navegador moderno para abrir el panel web."

    Add-Heading "8.2. Preparar la base de datos" 2
    Add-MonoBlock @(
        'mysql -u root -p < sql/00_usuario.sql',
        'mysql -u root -p < sql/01_schema.sql',
        'mysql -u root -p < sql/02_data.sql'
    )

    Add-Heading "8.3. Compilar" 2
    Add-MonoBlock @(
        'mvn clean package -DskipTests -f ms-cliente/pom.xml',
        'mvn clean package -DskipTests -f ms-vehiculo/pom.xml',
        'mvn clean package -DskipTests -f ms-alquiler/pom.xml'
    )

    Add-Heading "8.4. Arrancar los servicios en orden" 2
    Add-Body "Primero se levantan ms-cliente y ms-vehiculo, y por último ms-alquiler, porque este consume a los otros dos. En Windows puede usarse el script run-all.bat; en Linux o Git Bash, run-all.sh."
    Add-MonoBlock @(
        'java -jar ms-cliente/target/ms-cliente-0.0.1-SNAPSHOT.jar',
        'java -jar ms-vehiculo/target/ms-vehiculo-0.0.1-SNAPSHOT.jar',
        'java -jar ms-alquiler/target/ms-alquiler-0.0.1-SNAPSHOT.jar'
    )

    Add-Heading "8.5. Abrir el frontend" 2
    Add-Body "Con los tres servicios activos, abrir http://localhost:8083/ en el navegador. El panel comprueba el estado de las APIs y carga los datos automáticamente. El perfil por defecto es dev; para producción se define SPRING_PROFILES_ACTIVE=prod y las variables DB_URL, DB_USER y DB_PASSWORD."

    # ================= 9. CONCLUSIONES =================
    Add-Heading "9. Conclusiones" 1
    Add-Bullet "La separación en tres microservicios permitió aislar clientes, vehículos y alquileres, cada uno con su propia base de datos y su propio ciclo de despliegue."
    Add-Bullet "La comunicación HTTP con RestClient mantiene bajo el acoplamiento: ms-alquiler solo depende de los contratos JSON de los otros servicios."
    Add-Bullet "El cálculo del importe en el backend, con BigDecimal y validación de fechas, evita manipulaciones desde el cliente y garantiza consistencia."
    Add-Bullet "El manejo uniforme de errores facilita el consumo de las APIs y mejora la experiencia del frontend."
    Add-Bullet "El panel web, sin frameworks ni build tools, demuestra que es posible operar todo el sistema con una interfaz sencilla y clara."
    Add-Bullet "La verificación de punta a punta, las pruebas de error y la evidencia de ejecución respaldan el funcionamiento del laboratorio."

    # ================= 10. ANEXO =================
    Add-PageBreak
    Add-Heading "10. Anexo: endpoints de la API" 1
    Add-Body "Todas las rutas devuelven JSON. Los errores conservan el formato uniforme descrito en la sección 5.4."
    Add-Table "Endpoints disponibles en los tres microservicios." @('Servicio', 'Método', 'Ruta', 'Éxito') @(
        @('ms-cliente', 'GET', '/api/clientes', '200'),
        @('ms-cliente', 'GET', '/api/clientes/{id}', '200'),
        @('ms-cliente', 'POST', '/api/clientes', '201'),
        @('ms-cliente', 'PUT', '/api/clientes/{id}', '200'),
        @('ms-cliente', 'DELETE', '/api/clientes/{id}', '204'),
        @('ms-vehiculo', 'GET', '/api/vehiculos', '200'),
        @('ms-vehiculo', 'GET', '/api/vehiculos/{id}', '200'),
        @('ms-vehiculo', 'POST', '/api/vehiculos', '201'),
        @('ms-vehiculo', 'PUT', '/api/vehiculos/{id}', '200'),
        @('ms-vehiculo', 'PATCH', '/api/vehiculos/{id}/estado', '200'),
        @('ms-vehiculo', 'DELETE', '/api/vehiculos/{id}', '204'),
        @('ms-alquiler', 'GET', '/api/alquileres', '200'),
        @('ms-alquiler', 'GET', '/api/alquileres/{id}', '200'),
        @('ms-alquiler', 'GET', '/api/alquileres/cliente/{idCliente}', '200'),
        @('ms-alquiler', 'POST', '/api/alquileres', '201'),
        @('ms-alquiler', 'PUT', '/api/alquileres/{id}', '200'),
        @('ms-alquiler', 'PATCH', '/api/alquileres/{id}/finalizar', '200'),
        @('ms-alquiler', 'PATCH', '/api/alquileres/{id}/cancelar', '200'),
        @('ms-alquiler', 'DELETE', '/api/alquileres/{id}', '204')
    ) @(3.3, 2.0, 8.3, 2.6)

    Add-Body "Documento generado a partir del código fuente real, las capturas del frontend en ejecución y las evidencias de prueba del proyecto lab11-alquiler-vehiculos."

    # ---------- Actualizar indice y campos ----------
    $doc.TablesOfContents.Item(1).Update()
    $doc.Fields.Update() | Out-Null

    try {
        $doc.BuiltInDocumentProperties.Item("Title").Value = "Laboratorio 11 - Sistema de alquiler de vehículos"
        $doc.BuiltInDocumentProperties.Item("Subject").Value = "Microservicios Spring Boot y frontend web"
        $doc.BuiltInDocumentProperties.Item("Author").Value = "Laboratorio 11"
    } catch { }

    if (Test-Path $outPath) { Remove-Item $outPath -Force }
    [Microsoft.VisualBasic.Interaction]::CallByName($doc, 'SaveAs2', [Microsoft.VisualBasic.CallType]::Method, $outPath, 16)

    $pages = $doc.ComputeStatistics(2)
    $words = $doc.ComputeStatistics(0)
    $shapes = $doc.InlineShapes.Count
    $tables = $doc.Tables.Count
    $paragraphs = $doc.Paragraphs.Count

    $summary = @(
        "Documento: $outPath",
        "Tamaño: $((Get-Item $outPath).Length) bytes",
        "Páginas: $pages",
        "Palabras: $words",
        "Imágenes: $shapes",
        "Tablas: $tables",
        "Párrafos: $paragraphs",
        "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    )
    $summary | Set-Content -Path $logPath -Encoding UTF8
    $summary | ForEach-Object { Write-Output $_ }
}
finally {
    try { $doc.Close(0) } catch { }
    try { $word.Quit() } catch { }
    try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($sel) | Out-Null } catch { }
    try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null } catch { }
    try { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null } catch { }
}
