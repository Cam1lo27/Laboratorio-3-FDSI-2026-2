# Tabla STRIDE — Lab 3

Ver [dfd-lab3.png](dfd-lab3.png) para el diagrama de flujo con los dos límites de confianza referenciados abajo.

| ID | STRIDE | Hipótesis técnica | Validación |
|----|--------|--------------------|------------|
| H1 | Information Disclosure | HTTP permite observar contenido y rutas en tránsito. | Captura PCAP filtrada (`evidence/blue/lab3-http.pcap`, filtro `http`). |
| H2 | Information Disclosure | Headers y respuestas revelan tecnología o recursos. | `curl -I` y reporte pasivo de ZAP. |
| H3 | Repudiation | Sin correlación temporal, el equipo no puede atribuir solicitudes. | Comparar comando (con timestamp) contra `access.log`. |
| H4 | Tampering | Sin TLS, un intermediario podría alterar el tráfico; no se ejecutará MITM real. | Demostrar ausencia de protección (ausencia de TLS), sin interceptar terceros. |

Notas de equipo (llenar después de la ronda Red/Blue):

Notas de equipo (llenado después de la ronda Red/Blue):

- H1 — Observado: PCAP (`evidence/blue/lab3-http.pcap`) confirma que el HTML completo y el inventario de alertas viajan en texto plano por HTTP; visible con Wireshark → Follow HTTP Stream.
- H2 — Observado: Nmap y curl mostraron inicialmente `Server: nginx/1.28.3 (Ubuntu)` (versión completa); corregido con `server_tokens off` (ver evidence/retest/).
- H3 — Observado: access.log correlacionó exitosamente los comandos Red Team (nmap, curl) con timestamps UTC exactos; el escaneo SYN puro de Nmap no habría quedado registrado, solo las sondas de aplicación.
- H4 — Observado: se confirmó ausencia de TLS (todo el tráfico visible en PCAP); no se ejecutó MITM real, queda como riesgo abierto para Lab 4.
