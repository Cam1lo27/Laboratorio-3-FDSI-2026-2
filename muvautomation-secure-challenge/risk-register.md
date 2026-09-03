# Registro de riesgos — Lab 3

| ID | Descripción | STRIDE | Estado | Evidencia | Responsable |
|----|-------------|--------|--------|-----------|-------------|
| R1 | Tráfico HTTP sin cifrar expone contenido y rutas en tránsito | Information Disclosure | Pendiente para Lab 4 (requiere HTTPS) | `evidence/blue/lab3-http.pcap`, diagrams/stride-table.md (H1) | Johan |
| R2 | Banner de Nginx podía revelar versión del servidor | Information Disclosure | Corregido (`server_tokens off`) | `evidence/red/nmap_port80.*` vs `evidence/retest/nmap_port80.*` | Johan |
| R3 | Faltaban headers de seguridad básicos (X-Content-Type-Options, X-Frame-Options, Referrer-Policy) | Information Disclosure / Tampering | Corregido | `evidence/retest/headers_after.txt` | Johan |
| R4 | Rutas ocultas (`/.git/config`) podían quedar accesibles | Information Disclosure | Corregido (`location ~ /\. { deny all; }`) | `evidence/retest/hidden_path.txt` | Johan |
| R5 | Sin correlación temporal entre acción Red Team y logs, difícil atribuir solicitudes | Repudiation | Mitigado (línea de tiempo Purple Team) | `evidence/purple-timeline.md` | Johan y Camilo |
| R6 | Sin TLS, un intermediario podría alterar el tráfico (no probado con MITM real) | Tampering | Aceptado para Lab 3, pendiente para Lab 4 | diagrams/stride-table.md (H4) | Ambos |

Leyenda de estado: **corregido** (control aplicado y verificado con retest) · **mitigado** (reduce el riesgo sin eliminarlo) · **aceptado** (riesgo conocido, fuera de alcance de este laboratorio) · **pendiente para Lab 4**.
