#!/usr/bin/env bash
# Johan (Blue Team) - Fase D, Pasos 12-13. Ejecutar en el Ubuntu Server.
set -euo pipefail

mkdir -p evidence/blue

{
  echo "== access.log (últimas 50) =="
  sudo tail -n 50 /var/log/nginx/access.log
  echo
  echo "== error.log (últimas 30) =="
  sudo tail -n 30 /var/log/nginx/error.log
  echo
  echo "== journalctl nginx (últimos 20 min) =="
  sudo journalctl -u nginx --since '20 minutes ago' --no-pager
} | tee evidence/blue/telemetry.txt

{
  echo "== IPs con 5+ respuestas 404 =="
  sudo awk '$9 ~ /404/ {print $1, $4, $7, $9, $12}' /var/log/nginx/access.log \
    | sort | uniq -c | sort -nr | head
  echo
  echo "== Requests que coinciden con herramientas de reconocimiento =="
  sudo grep -E 'nmap|curl|ZAP' /var/log/nginx/access.log | tail -n 30
} | tee evidence/blue/detection-rule.txt

echo
echo "Regla de laboratorio: señal cuando una misma IP produce >=5 respuestas 404"
echo "en 5 minutos. Completa evidence/purple-timeline.md correlacionando esto"
echo "con los comandos que corrió Camilo (evidence/red/*)."
