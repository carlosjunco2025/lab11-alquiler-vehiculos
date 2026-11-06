# Genera paginas HTML con fragmentos reales de codigo y las captura con Chrome headless.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$pagesDir = Join-Path $PSScriptRoot 'pages'
$imgDir = Join-Path $root 'docs\img'
New-Item -ItemType Directory -Force -Path $pagesDir, $imgDir | Out-Null

function Read-Range {
    param([string]$Path, [int]$Start, [int]$End)
    $all = [System.IO.File]::ReadAllLines($Path, [System.Text.Encoding]::UTF8)
    return @($all[($Start - 1)..($End - 1)])
}

$snippets = @(
    @{
        Name = 'code-alquiler-service'; Title = 'AlquilerService.java'
        Sub = 'Reglas de negocio: crear un alquiler y calcular el importe'
        Badge = 'ms-alquiler - Java 17'
        Ranges = @(
            @{ File = 'ms-alquiler\src\main\java\com\tecsup\alquiler\services\AlquilerService.java'; Start = 67; End = 95 },
            @{ File = 'ms-alquiler\src\main\java\com\tecsup\alquiler\services\AlquilerService.java'; Start = 198; End = 207 }
        )
    },
    @{
        Name = 'code-cliente-client'; Title = 'ClienteClientService.java'
        Sub = 'Integracion HTTP con ms-cliente y traduccion de errores'
        Badge = 'ms-alquiler - RestClient'
        Ranges = @(
            @{ File = 'ms-alquiler\src\main\java\com\tecsup\alquiler\services\ClienteClientService.java'; Start = 12; End = 48 }
        )
    },
    @{
        Name = 'code-vehiculo-client'; Title = 'VehiculoClientService.java'
        Sub = 'Consulta del vehiculo y cambio de estado mediante PATCH'
        Badge = 'ms-alquiler - RestClient'
        Ranges = @(
            @{ File = 'ms-alquiler\src\main\java\com\tecsup\alquiler\services\VehiculoClientService.java'; Start = 15; End = 28 },
            @{ File = 'ms-alquiler\src\main\java\com\tecsup\alquiler\services\VehiculoClientService.java'; Start = 51; End = 71 }
        )
    },
    @{
        Name = 'code-exception-handler'; Title = 'GlobalExceptionHandler.java'
        Sub = 'Respuestas JSON uniformes para todos los errores'
        Badge = 'ms-cliente - @RestControllerAdvice'
        Ranges = @(
            @{ File = 'ms-cliente\src\main\java\com\tecsup\cliente\exception\GlobalExceptionHandler.java'; Start = 17; End = 47 }
        )
    },
    @{
        Name = 'code-controller'; Title = 'AlquilerController.java'
        Sub = 'Endpoints REST del ciclo de vida del alquiler'
        Badge = 'ms-alquiler - Spring MVC'
        Ranges = @(
            @{ File = 'ms-alquiler\src\main\java\com\tecsup\alquiler\controller\AlquilerController.java'; Start = 21; End = 30 },
            @{ File = 'ms-alquiler\src\main\java\com\tecsup\alquiler\controller\AlquilerController.java'; Start = 32; End = 61 }
        )
    },
    @{
        Name = 'code-config'; Title = 'application.yml'
        Sub = 'Puerto, perfil activo y URLs de los otros microservicios'
        Badge = 'ms-alquiler - Configuracion'
        Ranges = @(
            @{ File = 'ms-alquiler\src\main\resources\application.yml'; Start = 1; End = 8 },
            @{ File = 'ms-alquiler\src\main\resources\application.yml'; Start = 18; End = 23 }
        )
    },
    @{
        Name = 'code-config-prod'; Title = 'application-prod.yml'
        Sub = 'Perfil de produccion: variables de entorno y ddl-auto validate'
        Badge = 'ms-alquiler - Configuracion'
        Ranges = @(
            @{ File = 'ms-alquiler\src\main\resources\application-prod.yml'; Start = 1; End = 16 }
        )
    },
    @{
        Name = 'code-sql'; Title = '01_schema.sql'
        Sub = 'Tres bases independientes y tabla de alquileres sin FK entre bases'
        Badge = 'MySQL 8 - Esquema'
        Ranges = @(
            @{ File = 'sql\01_schema.sql'; Start = 1; End = 14 },
            @{ File = 'sql\01_schema.sql'; Start = 52; End = 70 }
        )
    },
    @{
        Name = 'code-cors'; Title = 'WebConfig.java'
        Sub = 'CORS para que el panel web pueda consumir las tres APIs'
        Badge = 'ms-cliente / ms-vehiculo / ms-alquiler'
        Ranges = @(
            @{ File = 'ms-cliente\src\main\java\com\tecsup\cliente\config\WebConfig.java'; Start = 1; End = 24 }
        )
    },
    @{
        Name = 'code-frontend-api'; Title = 'app.js - cliente HTTP'
        Sub = 'Configuracion de las APIs y funcion central que interpreta las respuestas'
        Badge = 'Frontend - JavaScript vanilla'
        Ranges = @(
            @{ File = 'ms-alquiler\src\main\resources\static\js\app.js'; Start = 8; End = 13 },
            @{ File = 'ms-alquiler\src\main\resources\static\js\app.js'; Start = 143; End = 173 }
        )
    },
    @{
        Name = 'code-frontend-calculo'; Title = 'app.js - calculo visual'
        Sub = 'Vista previa del importe antes de enviar el formulario'
        Badge = 'Frontend - JavaScript vanilla'
        Ranges = @(
            @{ File = 'ms-alquiler\src\main\resources\static\js\app.js'; Start = 546; End = 565 }
        )
    },
    @{
        Name = 'code-frontend-alquiler'; Title = 'app.js - alta de alquiler'
        Sub = 'Validaciones del formulario y envio del POST al microservicio'
        Badge = 'Frontend - JavaScript vanilla'
        Ranges = @(
            @{ File = 'ms-alquiler\src\main\resources\static\js\app.js'; Start = 673; End = 715 }
        )
    }
)

$template = @'
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<style>
  * { box-sizing: border-box; }
  html, body { margin: 0; padding: 0; background: #e8eef8; }
  body { padding: 10px; width: 900px; font-family: "Segoe UI", Arial, sans-serif; }
  .card { width: 880px; border: 1px solid #1e293b; border-radius: 12px; overflow: hidden; background: #0b1220; box-shadow: 0 10px 24px rgba(15,23,42,.18); }
  .hd { display: flex; align-items: center; justify-content: space-between; gap: 18px; padding: 14px 22px; background: linear-gradient(135deg, #111c31, #0b1220); border-bottom: 1px solid #1e293b; }
  .lbl { color: #7dd3fc; font-size: 10px; font-weight: 700; letter-spacing: 1.6px; text-transform: uppercase; }
  h1 { margin: 3px 0 0; font: 600 15px/1.25 Consolas, "Courier New", monospace; color: #f8fafc; }
  .sub { margin: 3px 0 0; color: #94a3b8; font-size: 11px; }
  .badge { flex: none; padding: 6px 10px; border: 1px solid #1e40af; border-radius: 999px; background: #172554; color: #bfdbfe; font-size: 10px; font-weight: 700; white-space: nowrap; }
  .code { padding: 14px 0 16px; }
  .line { display: flex; height: 20px; line-height: 20px; font-family: Consolas, "Courier New", monospace; font-size: 12.5px; white-space: pre; }
  .ln { width: 48px; flex: none; padding-right: 14px; text-align: right; color: #475569; }
  .tx { padding-right: 20px; color: #dbeafe; }
  .sep .ln { color: #334155; }
  .sep .tx { color: #64748b; font-style: italic; }
  .c { color: #7c8ea8; font-style: italic; }
  .s { color: #86efac; }
  .a { color: #7dd3fc; }
  .k { color: #c084fc; }
  .n { color: #fbbf24; }
</style>
</head>
<body>
  <div class="card" id="card">
    <div class="hd">
      <div>
        <div class="lbl">Codigo fuente</div>
        <h1>__TITLE__</h1>
        <p class="sub">__SUB__</p>
      </div>
      <div class="badge">__BADGE__</div>
    </div>
    <div class="code" id="code"></div>
  </div>
<script>
const ENTRIES = __DATA__;
const KEYWORDS = /^(public|private|protected|class|interface|extends|implements|new|return|if|else|for|while|try|catch|finally|throw|throws|final|void|static|this|super|import|package|null|true|false|long|int|String|BigDecimal|List|Map|LocalDate|var|const|let|function|async|await|export|default|from|of|in|typeof|instanceof|switch|case|break|continue|do|enum|boolean|double|float|char|byte|abstract|synchronized|volatile|transient|assert|yield|delete|record)$/;
function esc(s) { return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }
function paintSegment(seg) {
  return seg.replace(/(@[A-Za-z_]\w*)|\b([A-Za-z_]\w*)\b|\b(\d+(?:\.\d+)?)\b/g, function (m, ann, word, num) {
    if (ann) return '<span class="a">' + ann + '</span>';
    if (word) return KEYWORDS.test(word) ? '<span class="k">' + word + '</span>' : word;
    if (num) return '<span class="n">' + num + '</span>';
    return m;
  });
}
function highlight(line) {
  const t = line.replace(/^\s+/, '');
  if (/^(\/\/|\/\*|\*|--|#)/.test(t)) return '<span class="c">' + esc(line) + '</span>';
  let out = '', i = 0;
  while (i < line.length) {
    const ch = line[i];
    if (ch === '"' || ch === "'" || ch === '`') {
      let j = i + 1;
      while (j < line.length) { if (line[j] === '\\') { j += 2; continue; } if (line[j] === ch) { j++; break; } j++; }
      out += '<span class="s">' + esc(line.slice(i, j)) + '</span>';
      i = j;
      continue;
    }
    if (ch === '/' && line[i + 1] === '/') { out += '<span class="c">' + esc(line.slice(i)) + '</span>'; break; }
    let j = i;
    while (j < line.length && !(line[j] === '"' || line[j] === "'" || line[j] === '`' || (line[j] === '/' && line[j + 1] === '/'))) j++;
    out += paintSegment(esc(line.slice(i, j)));
    i = j;
  }
  return out;
}
const code = document.getElementById('code');
let maxLen = 0;
for (const e of ENTRIES) {
  const row = document.createElement('div');
  if (e.sep) {
    row.className = 'line sep';
    row.innerHTML = '<span class="ln">...</span><span class="tx">' + esc(e.text) + '</span>';
  } else {
    row.className = 'line';
    row.innerHTML = '<span class="ln">' + e.n + '</span><span class="tx">' + highlight(e.t) + '</span>';
    if (e.t.length > maxLen) maxLen = e.t.length;
  }
  code.appendChild(row);
}
if (maxLen > 108) {
  const size = Math.max(10.2, 780 / (0.55 * maxLen));
  document.querySelectorAll('.line').forEach(function (l) { l.style.fontSize = size.toFixed(1) + 'px'; });
}
</script>
</body>
</html>
'@

$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$ErrorActionPreference = 'Continue'
$profile = Join-Path $env:TEMP 'lab11-chrome-code'
New-Item -ItemType Directory -Force -Path $profile | Out-Null

$summary = @()
foreach ($s in $snippets) {
    $entries = New-Object System.Collections.Generic.List[object]
    $first = $true
    foreach ($r in $s.Ranges) {
        $full = Join-Path $root $r.File
        if (-not (Test-Path $full)) { throw "No existe $full" }
        $lines = Read-Range -Path $full -Start $r.Start -End $r.End
        if (-not $first) {
            $entries.Add([ordered]@{ sep = $true; text = '... fragmento continuo ...' })
        }
        $first = $false
        $n = $r.Start
        foreach ($line in $lines) {
            $entries.Add([ordered]@{ n = $n; t = $line })
            $n++
        }
    }

    $json = ConvertTo-Json -InputObject ([object[]]$entries.ToArray()) -Depth 5 -Compress
    $html = $template.Replace('__TITLE__', $s.Title).Replace('__SUB__', $s.Sub).Replace('__BADGE__', $s.Badge).Replace('__DATA__', $json)
    $htmlPath = Join-Path $pagesDir ($s.Name + '.html')
    [System.IO.File]::WriteAllText($htmlPath, $html, (New-Object System.Text.UTF8Encoding($false)))

    $count = $entries.Count
    $height = 138 + (20 * $count)
    $imgPath = Join-Path $imgDir ($s.Name + '.png')
    $url = 'file:///' + ($htmlPath -replace '\\', '/')
    if (Test-Path $imgPath) { Remove-Item $imgPath -Force }
    & $chrome --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --window-size=900,$height --virtual-time-budget=3000 --user-data-dir="$profile" --screenshot="$imgPath" $url 2>$null | Out-Null

    Add-Type -AssemblyName System.Drawing
    $img = [System.Drawing.Image]::FromFile($imgPath)
    $summary += [pscustomobject]@{ Imagen = $s.Name + '.png'; Lineas = $count; Ancho = $img.Width; Alto = $img.Height; Bytes = (Get-Item $imgPath).Length }
    $img.Dispose()
}

# Imagen tipo terminal con evidencia real de los servicios.
$terminalLines = [System.IO.File]::ReadAllLines((Join-Path $root 'docs\tools-terminal.txt'), [System.Text.Encoding]::UTF8)
$termEntries = foreach ($l in $terminalLines) { [ordered]@{ t = $l } }
$termJson = ConvertTo-Json -InputObject ([object[]]$termEntries) -Depth 4 -Compress
$termTemplate = @'
<!DOCTYPE html>
<html lang="es"><head><meta charset="utf-8"><style>
* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; background: #e8eef8; }
body { padding: 10px; width: 940px; font-family: "Segoe UI", Arial, sans-serif; }
.card { width: 920px; border: 1px solid #1e293b; border-radius: 12px; overflow: hidden; background: #0b1220; box-shadow: 0 10px 24px rgba(15,23,42,.18); }
.bar { display: flex; align-items: center; gap: 7px; padding: 11px 16px; background: #111c31; border-bottom: 1px solid #1e293b; }
.dot { width: 11px; height: 11px; border-radius: 50%; }
.r { background: #ef4444; } .y { background: #f59e0b; } .g { background: #22c55e; }
.bar span { margin-left: 10px; color: #94a3b8; font-size: 11.5px; }
.hd { padding: 13px 20px 10px; border-bottom: 1px solid #16213a; }
.lbl { color: #7dd3fc; font-size: 10px; font-weight: 700; letter-spacing: 1.6px; text-transform: uppercase; }
h1 { margin: 4px 0 0; font: 600 15px/1.25 Consolas, "Courier New", monospace; color: #f8fafc; }
.term { padding: 14px 20px 18px; font-family: Consolas, "Courier New", monospace; font-size: 11.4px; line-height: 21px; color: #cbd5e1; white-space: pre; }
.p { color: #7dd3fc; }
.ok { color: #86efac; }
.js { color: #fbbf24; }
.dim { color: #8194ab; }
</style></head><body>
<div class="card">
  <div class="bar"><i class="dot r"></i><i class="dot y"></i><i class="dot g"></i><span>PowerShell - servicios en ejecucion</span></div>
  <div class="hd"><div class="lbl">Evidencia real</div><h1>Los tres microservicios responden y comparten CORS</h1></div>
  <div class="term" id="term"></div>
</div>
<script>
const LINES = __DATA__;
const out = document.getElementById('term');
for (const item of LINES) {
  const s = document.createElement('div');
  let txt = item.t;
  if (/^PS>/.test(txt)) s.className = 'p';
  else if (/^(200|HTTP\/1\.1 200|Access-Control-Allow-Origin|Content-Type)/.test(txt)) s.className = 'ok';
  else if (/^\{/.test(txt)) s.className = 'js';
  else if (/^\d{4}-/.test(txt)) s.className = 'dim';
  s.textContent = txt === '' ? ' ' : txt;
  out.appendChild(s);
}
</script></body></html>
'@
$termHtmlPath = Join-Path $pagesDir 'terminal-servicios.html'
[System.IO.File]::WriteAllText($termHtmlPath, $termTemplate.Replace('__DATA__', $termJson), (New-Object System.Text.UTF8Encoding($false)))
$termHeight = 150 + (21 * $terminalLines.Count)
$termImg = Join-Path $imgDir 'terminal-servicios.png'
if (Test-Path $termImg) { Remove-Item $termImg -Force }
& $chrome --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --window-size=940,$termHeight --virtual-time-budget=3000 --user-data-dir="$profile" --screenshot="$termImg" ('file:///' + ($termHtmlPath -replace '\\', '/')) 2>$null | Out-Null
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile($termImg)
$summary += [pscustomobject]@{ Imagen = 'terminal-servicios.png'; Lineas = $terminalLines.Count; Ancho = $img.Width; Alto = $img.Height; Bytes = (Get-Item $termImg).Length }
$img.Dispose()

$summary | Format-Table -AutoSize
