#!/usr/bin/env bash
# Camilo (Red Team) - Fase C, Paso 8. Ejecutar en Kali, desde la raíz del repo,
# con lab.env ya cargado: `source lab.env`. Solo contra TARGET_IP autorizada.
set -euo pipefail

: "${TARGET_IP:?Define TARGET_IP (source lab.env primero)}"
: "${TARGET_URL:?Define TARGET_URL (source lab.env primero)}"

mkdir -p evidence/red
date -u +%Y-%m-%dT%H:%M:%SZ | tee evidence/red/start.txt

echo "== nmap: puerto y servicio =="
nmap -Pn -sV -p 80 "$TARGET_IP" -oA evidence/red/nmap_port80

echo "== curl: home =="
curl -i "$TARGET_URL/" | tee evidence/red/curl_home.txt

echo "== curl: headers del inventario público =="
curl -I "$TARGET_URL/public-inventory.txt" | tee evidence/red/curl_headers.txt

echo
echo "Listo. Con esto completa a mano evidence/attack-surface.md (Paso 9)"
echo "y corre OWASP ZAP en modo Manual Explore (Paso 10) contra \$TARGET_URL."
echo "No amplíes el rango de puertos ni el alcance sin autorización adicional."
