# Inventario de superficie de ataque (Paso 9)

Llenado por Camilo (Red Team) usando la salida de `scripts/02-red-recon.sh`.

| Elemento | Dato observado | Riesgo / pregunta |
|----------|-----------------|--------------------|
| Host/IP | 192.168.92.132 | Limitado al CIDR 192.168.92.0/24 vía ufw, confirmado |
| Puerto | 80/TCP | Tráfico sin cifrar, texto plano visible por PCAP |
| Servidor | nginx 1.28.3 (Ubuntu) | Sí, se revela versión completa (pendiente de corregir con server_tokens off en Fase E) |
| Ruta `/` | 200 OK, Content-Length 7257 | Expone HTML completo del portal, sin autenticación |
| Archivo público | public-inventory.txt, 881 bytes, Content-Type text/plain | Expone Last-Modified y listado de assets/alertas ficticias |
