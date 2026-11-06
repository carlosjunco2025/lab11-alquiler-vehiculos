@echo off
rem =====================================================================
rem Laboratorio 11 - Arranca MySQL y los 3 microservicios en orden.
rem Requisitos: Docker (recomendado) o MySQL local + Maven + Java 17.
rem =====================================================================
setlocal EnableDelayedExpansion
cd /d "%~dp0"

echo ============================================
echo  Lab 11 - Alquiler de vehiculos
echo ============================================

where docker >nul 2>nul
if %ERRORLEVEL% NEQ 0 goto mysql_local

echo [1/4] Levantando MySQL con Docker...
docker compose up -d || goto error
echo Esperando a que el contenedor este healthy...
set CONTADOR=0
set ESTADO=starting

:esperar_mysql
for /f "delims=" %%E in ('docker inspect -f "{{.State.Health.Status}}" lab11-mysql 2^>nul') do set ESTADO=%%E
if /I "!ESTADO!"=="healthy" goto mysql_listo
set /a CONTADOR+=1
if !CONTADOR! GEQ 40 (
    echo ERROR: MySQL no llego a healthy. Revise: docker logs lab11-mysql
    exit /b 1
)
timeout /t 3 /nobreak >nul
goto esperar_mysql

:mysql_local
echo [1/4] Docker no disponible. Usando MySQL local en localhost:3306.
if "%MYSQL_ROOT_PASSWORD%"=="" (
    mysql -u root < sql\00_usuario.sql || goto error
    mysql -u root < sql\01_schema.sql || goto error
    mysql -u root < sql\02_data.sql || goto error
) else (
    mysql -u root -p%MYSQL_ROOT_PASSWORD% < sql\00_usuario.sql || goto error
    mysql -u root -p%MYSQL_ROOT_PASSWORD% < sql\01_schema.sql || goto error
    mysql -u root -p%MYSQL_ROOT_PASSWORD% < sql\02_data.sql || goto error
)

:mysql_listo
echo [OK] Base de datos disponible.

echo [2/4] Arrancando ms-cliente en el puerto 8081...
start "ms-cliente" /D "%~dp0ms-cliente" cmd /k "mvn spring-boot:run"
timeout /t 20 /nobreak >nul

echo [3/4] Arrancando ms-vehiculo en el puerto 8082...
start "ms-vehiculo" /D "%~dp0ms-vehiculo" cmd /k "mvn spring-boot:run"
timeout /t 20 /nobreak >nul

echo [4/4] Arrancando ms-alquiler en el puerto 8083...
start "ms-alquiler" /D "%~dp0ms-alquiler" cmd /k "mvn spring-boot:run"

echo.
echo Servicios lanzados. Verifique cada ventana y pruebe:
echo   curl http://localhost:8081/api/clientes
echo   curl http://localhost:8082/api/vehiculos
echo   curl http://localhost:8083/api/alquileres
exit /b 0

:error
echo ERROR: no se pudo preparar la base de datos.
exit /b 1
