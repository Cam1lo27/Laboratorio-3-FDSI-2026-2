#!/usr/bin/env bash
# Johan (Blue Team) - Fase E, Paso 15. Ejecutar en el Ubuntu Server, por SSH,
# desde la raíz del repo, con lab.env cargado.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

sudo cp /etc/nginx/sites-available/muvautomation /etc/nginx/sites-available/muvautomation.before-hardening.bak
sudo cp "$REPO_ROOT/nginx/muvautomation-hardened.conf" /etc/nginx/sites-available/muvautomation
sudo nginx -t
sudo systemctl reload nginx

TARGET_URL="${TARGET_URL:-http://127.0.0.1}"
curl -I "$TARGET_URL/"
curl -i "$TARGET_URL/.git/config"

echo
echo "Límite pedagógico: HTTP sigue siendo inseguro para confidencialidad e"
echo "integridad; ese riesgo queda abierto para HTTPS/identidad en el Lab 4."
echo "Paso 16: revisa app/public-inventory.txt y quita cualquier dato no esencial,"
echo "conservando la versión anterior en Git para el comparativo antes/después."
