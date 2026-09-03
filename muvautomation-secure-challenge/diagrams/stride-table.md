# Tabla STRIDE — Lab 3

Ver [dfd-lab3.png](dfd-lab3.png) para el diagrama de flujo con los dos límites de confianza referenciados abajo.

| ID | STRIDE | Hipótesis técnica | Validación |
|----|--------|--------------------|------------|
| H1 | Information Disclosure | HTTP permite observar contenido y rutas en tránsito. | Captura PCAP filtrada (`evidence/blue/lab3-http.pcap`, filtro `http`). |
| H2 | Information Disclosure | Headers y respuestas revelan tecnología o recursos. | `curl -I` y reporte pasivo de ZAP. |
| H3 | Repudiation | Sin correlación temporal, el equipo no puede atribuir solicitudes. | Comparar comando (con timestamp) contra `access.log`. |
| H4 | Tampering | Sin TLS, un intermediario podría alterar el tráfico; no se ejecutará MITM real. | Demostrar ausencia de protección (ausencia de TLS), sin interceptar terceros. |

Notas de equipo (llenar después de la ronda Red/Blue):

- H1 — Observado:
- H2 — Observado:
- H3 — Observado:
- H4 — Observado:
