# Tabla STRIDE — Lab 3

Ver [dfd-lab3.svg](dfd-lab3.svg) para el diagrama de flujo con los dos límites de confianza referenciados abajo.

| ID | STRIDE | Hipótesis técnica | Validación |
|----|--------|--------------------|------------|
| H1 | Information Disclosure | HTTP permite observar contenido y rutas en tránsito. | Captura PCAP filtrada (`evidence/blue/lab3-http.pcap`, filtro `http`). |
| H2 | Information Disclosure | Headers y respuestas revelan tecnología o recursos. | `curl -I` y reporte pasivo de ZAP. |
| H3 | Repudiation | Sin correlación temporal, el equipo no puede atribuir solicitudes. | Comparar comando (con timestamp) contra `access.log`. |
| H4 | Tampering | Sin TLS, un intermediario podría alterar el tráfico; no se ejecutará MITM real. | Demostrar ausencia de protección (ausencia de TLS), sin interceptar terceros. |

## Notas de equipo (después de la ronda Red/Blue)

**H1:** se confirmó con el PCAP. Al abrirlo en Wireshark y hacer Follow HTTP Stream sobre la petición al inventario, se ve todo en texto plano — el HTML de la página y las alertas ficticias, sin ningún tipo de cifrado.

**H2:** Nmap y curl mostraban al principio `Server: nginx/1.28.3 (Ubuntu)`, o sea la versión completa del servidor. Se corrigió con `server_tokens off` (se ve la diferencia comparando `evidence/red/` contra `evidence/retest/`).

**H3:** el `access.log` sí permitió correlacionar los comandos de Camilo (Red Team) con los eventos del lado de Ubuntu, usando los timestamps. Eso sí, un escaneo puro de puertos de Nmap (sin sondas de servicio) probablemente no habría dejado ningún rastro ahí, porque el log solo registra peticiones HTTP completas.

**H4:** no se hizo ningún MITM real, pero con el PCAP alcanza para demostrar que no hay ninguna protección — cualquiera en la misma red podría alterar el tráfico sin que nadie lo note. Ese riesgo se deja abierto para el Lab 4.
