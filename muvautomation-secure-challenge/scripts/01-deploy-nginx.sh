#!/usr/bin/env bash
# Johan (Blue/Builder) - Fase A, Pasos 2-5. Ejecutar en el Ubuntu Server, por SSH,
# desde la raíz del repo, con lab.env ya cargado: `source lab.env`.
set -euo pipefail

: "${LAB_CIDR:?Define LAB_CIDR (source lab.env primero)}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "== Paso 2: instalar y habilitar Nginx =="
sudo apt update
sudo apt install -y nginx
sudo systemctl enable --now nginx
sudo systemctl status nginx --no-pager
sudo ss -lntp | grep ':80'

echo "== Paso 3: publicar el sitio mínimo =="
sudo mkdir -p /var/www/muvautomation
sudo cp "$REPO_ROOT/app/index.html" /var/www/muvautomation/index.html
sudo cp "$REPO_ROOT/app/public-inventory.txt" /var/www/muvautomation/public-inventory.txt

echo "== Paso 4: configurar el virtual host =="
sudo cp "$REPO_ROOT/nginx/muvautomation.conf" /etc/nginx/sites-available/muvautomation
sudo ln -sf /etc/nginx/sites-available/muvautomation /etc/nginx/sites-enabled/muvautomation
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
curl -i http://127.0.0.1/

echo "== Paso 5: limitar el firewall al segmento del laboratorio (LAB_CIDR=$LAB_CIDR) =="
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from "$LAB_CIDR" to any port 80 proto tcp
sudo ufw allow OpenSSH
sudo ufw --force enable
sudo ufw status numbered

echo
echo "Punto de control: avisa al docente para que verifique URL, firewall y contenido"
echo "antes de autorizar las pruebas de Red Team."
