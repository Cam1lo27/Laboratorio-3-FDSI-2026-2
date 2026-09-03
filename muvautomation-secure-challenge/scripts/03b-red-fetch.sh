#!/usr/bin/env bash
# Camilo (Red Team) - Fase C, Paso 11 (lado ataque). Ejecutar en Kali, con
# lab.env cargado, JUSTO DESPUÉS de que Johan avise que arrancó tcpdump.
set -euo pipefail

: "${TARGET_URL:?Define TARGET_URL (source lab.env primero)}"

curl "$TARGET_URL/"
curl "$TARGET_URL/public-inventory.txt"

echo
echo "Peticiones enviadas dentro de la ventana de captura de Blue Team."
