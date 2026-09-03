#!/usr/bin/env bash
# Johan (Blue/Builder) - Fase A, Paso 1. Ejecutar en el Ubuntu Server, por SSH.
set -euo pipefail

mkdir -p evidence/blue
{
  echo "== hostnamectl =="
  hostnamectl
  echo
  echo "== ip -br address =="
  ip -br address
  echo
  echo "== uname -a =="
  uname -a
  echo
  echo "== timestamp UTC =="
  date -u +%Y-%m-%dT%H:%M:%SZ
} | tee evidence/blue/00-baseline.txt

echo
echo "Revisa que la IP mostrada arriba coincida con la IP asignada por el docente"
echo "y que este NO es un servidor de producción antes de continuar."
