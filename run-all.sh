#!/usr/bin/env bash
# =====================================================================
# Laboratorio 11 - Arranca MySQL y los 3 microservicios en orden.
# Requisitos: Docker (recomendado) o MySQL local + Maven + Java 17.
# =====================================================================
set -e
cd "$(dirname "$0")"
mkdir -p logs

echo "============================================"
echo " Lab 11 - Alquiler de vehiculos"
echo "============================================"

if command -v docker >/dev/null 2>&1; then
    echo "[1/4] Levantando MySQL con Docker..."
    docker compose up -d
    echo "Esperando a que MySQL este healthy..."
    for i in $(seq 1 40); do
        if docker compose exec -T mysql mysqladmin ping -h 127.0.0.1 -u root \
            -p"${MYSQL_ROOT_PASSWORD:-lab11_root}" --silent >/dev/null 2>&1; then
            break
        fi
        sleep 3
    done
else
    echo "[1/4] Docker no disponible. Usando MySQL local en localhost:3306."
    if [ -n "${MYSQL_ROOT_PASSWORD:-}" ]; then
        mysql -u root -p"$MYSQL_ROOT_PASSWORD" < sql/00_usuario.sql
        mysql -u root -p"$MYSQL_ROOT_PASSWORD" < sql/01_schema.sql
        mysql -u root -p"$MYSQL_ROOT_PASSWORD" < sql/02_data.sql
    else
        mysql -u root < sql/00_usuario.sql
        mysql -u root < sql/01_schema.sql
        mysql -u root < sql/02_data.sql
    fi
fi

arrancar() {
    local nombre="$1"
    echo "Arrancando $nombre..."
    (cd "$nombre" && mvn spring-boot:run > "../logs/$nombre.log" 2>&1) &
    echo $! > "logs/$nombre.pid"
}

echo "[2/4] Arrancando ms-cliente (8081)..."
arrancar ms-cliente
sleep 20

echo "[3/4] Arrancando ms-vehiculo (8082)..."
arrancar ms-vehiculo
sleep 20

echo "[4/4] Arrancando ms-alquiler (8083)..."
arrancar ms-alquiler

echo ""
echo "Servicios lanzados. Logs en ./logs/"
echo "Pruebe: curl http://localhost:8081/api/clientes"
echo "        curl http://localhost:8082/api/vehiculos"
echo "        curl http://localhost:8083/api/alquileres"
echo "Para detenerlos: kill \$(cat logs/*.pid)"
