#!/usr/bin/env bash
# Camilo (Red Team) - Fase F, Paso 17. Ejecutar en Kali, con lab.env cargado,
# después de que Johan confirme que aplicó el hardening (script 05).
set -euo pipefail

: "${TARGET_IP:?Define TARGET_IP (source lab.env primero)}"
: "${TARGET_URL:?Define TARGET_URL (source lab.env primero)}"

mkdir -p evidence/retest
nmap -Pn -sV -p 80 "$TARGET_IP" -oA evidence/retest/nmap_port80
curl -I "$TARGET_URL/" | tee evidence/retest/headers_after.txt
curl -i "$TARGET_URL/.git/config" | tee evidence/retest/hidden_path.txt

echo
echo "Compara evidence/red/* (antes) contra evidence/retest/* (después):"
echo "  - la versión de Nginx no debe aparecer en banners"
echo "  - deben verse los headers X-Content-Type-Options, X-Frame-Options, Referrer-Policy"
echo "  - /.git/config debe responder 403/404, no 200"
