#!/usr/bin/env bash
# Johan (Blue Team) - Fase C, Paso 11 (lado servidor). Ejecutar en el Ubuntu Server.
# Coordínense por chat/voz: en cuanto arranques esto, avisa a Camilo para que
# corra scripts/03b-red-fetch.sh (tienen 60 segundos de ventana).
set -euo pipefail

mkdir -p evidence/blue
echo "Iniciando captura de 60s en tcp/80. Avisa YA a Red Team."
sudo timeout 60 tcpdump -i any -nn -s0 -w /tmp/lab3-http.pcap 'tcp port 80'

IP="$(hostname -I | awk '{print $1}')"
echo
echo "Captura terminada. Desde tu máquina local, tráela con:"
echo "  scp usuario@${IP}:/tmp/lab3-http.pcap evidence/blue/lab3-http.pcap"
echo "Luego ábrela en Wireshark con el filtro 'http' y documenta qué se observa."
