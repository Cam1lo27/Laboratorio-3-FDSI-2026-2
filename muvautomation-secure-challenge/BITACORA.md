# Bitácora Laboratorio 3 — CrowdStrike Incident Hub

**Equipo:** Andrés Camilo Vivas Baquero (Red Team) · Johan Sebastián Beltrán Gutiérrez (Blue Team / Builder)
**Grupo:** G07 · **Temática:** Opción 1 — Automatización de incidentes de CrowdStrike Falcon
**Fecha de ejecución:** 2026-09-16 (UTC)
**Objetivo:** Publicar el prototipo "CrowdStrike Incident Hub" por HTTP sin autenticación, ejecutar el ciclo completo Diseñar → Construir → Atacar → Detectar → Corregir → Verificar, y dejar evidencia reproducible.

---

## 1. Entorno técnico

| Componente | Detalle |
|---|---|
| Hipervisor | VMware Workstation Pro, ambas VMs en la misma máquina física, red **NAT** compartida |
| Blue Team / Builder | Ubuntu Server LTS — host `lab3ubuntu`, IP `192.168.92.132` |
| Red Team | Kali Linux (imagen VMware oficial) — IP `192.168.92.134` |
| Servicio publicado | Nginx 1.28.3, sitio estático `CrowdStrike Incident Hub`, puerto 80/TCP, sin TLS, sin autenticación |

Línea base registrada en [`evidence/blue/00-baseline.txt`](muvautomation-secure-challenge/evidence/blue/00-baseline.txt):
```
Static hostname: lab3ubuntu
Operating System: Ubuntu 26.04.1 LTS
ens33  192.168.92.132/24
Timestamp UTC: 2026-09-16T19:08:08Z
```

---

## 2. Línea de tiempo real (Purple Team)

| Hora UTC | Actor | Acción | Evidencia |
|---|---|---|---|
| 19:08:08 | Builder | Verificación de línea base del host | `evidence/blue/00-baseline.txt` |
| 19:09:24 | Builder | Nginx desplegado, primera respuesta local `200 OK` | script `01-deploy-nginx.sh` |
| 19:09:24 | Builder | Firewall (`ufw`) limitado a `192.168.92.0/24` + OpenSSH | log de despliegue |
| 21:33:26 | Red Team | Verificación manual de acceso remoto (`curl -i $TARGET_URL/`) | consola Kali |
| **21:35:10** | Red Team | `nmap -sV -p 80` + `curl -i /` + `curl -I /public-inventory.txt` | [`evidence/red/nmap_port80.nmap`](muvautomation-secure-challenge/evidence/red/nmap_port80.nmap), `curl_home.txt`, `curl_headers.txt` |
| 21:35:10 | Blue Team | Sondas de Nmap (`/HNAP1`, `/sdk`, `/evox/about`, `/nmaplowercheck...`) quedan registradas como `404` en `access.log` | [`evidence/blue/detection-rule.txt`](muvautomation-secure-challenge/evidence/blue/detection-rule.txt) |
| 21:44–21:53 | Red Team | Exploración pasiva con OWASP ZAP (Manual Explore) sobre `/` y `/public-inventory.txt` | [`reports/zap-passive/2026-09-16-ZAP-Report-.html`](muvautomation-secure-challenge/reports/zap-passive/2026-09-16-ZAP-Report-.html) |
| **22:06:13** | Blue Team + Red Team | Captura coordinada de 60s (`tcpdump`) mientras Red Team repite `curl` a `/` y `/public-inventory.txt` | [`evidence/blue/lab3-http.pcap`](muvautomation-secure-challenge/evidence/blue/lab3-http.pcap) — 22 paquetes capturados |
| 22:15 | Blue Team | Revisión de `access.log`/`error.log`/`journalctl` y regla de detección (5+ 404 en 5 min) | [`evidence/blue/telemetry.txt`](muvautomation-secure-challenge/evidence/blue/telemetry.txt) |
| 22:20 | Blue Team | Aplicación del hardening (`server_tokens off`, headers de seguridad, bloqueo de rutas ocultas) | `nginx/muvautomation-hardened.conf` |
| **22:24:46 – 22:24:52** | Red Team | Retest: `nmap -sV`, `curl -I /`, `curl -i /.git/config` | [`evidence/retest/nmap_port80.nmap`](muvautomation-secure-challenge/evidence/retest/nmap_port80.nmap), [`headers_after.txt`](muvautomation-secure-challenge/evidence/retest/headers_after.txt), [`hidden_path.txt`](muvautomation-secure-challenge/evidence/retest/hidden_path.txt) |

---

## 3. Comparación antes / después del hardening

| Aspecto | Antes (`evidence/red/`) | Después (`evidence/retest/`) |
|---|---|---|
| Banner de servidor (Nmap) | `nginx 1.28.3 (Ubuntu)` | `nginx` (sin versión) |
| Header `Server` (curl) | `nginx/1.28.3 (Ubuntu)` | `nginx` |
| Headers de seguridad | Ausentes | `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer` |
| Ruta oculta `/.git/config` | No probada aún | `403 Forbidden` |
| Confidencialidad del tráfico HTTP | Sin cifrar (confirmado por PCAP) | **Sin cambio** — HTTP sigue sin TLS, queda abierto para Lab 4 |

Esto confirma exactamente la regla pedagógica de la guía: el hardening reduce la **exposición de metadatos** (Information Disclosure), pero no resuelve el riesgo de fondo de **confidencialidad/integridad** de HTTP sin cifrar.

---

## 4. Evidencia de Information Disclosure (H1 — STRIDE)

Con el PCAP (`evidence/blue/lab3-http.pcap`) abierto en Wireshark, filtro `http`, se identificaron 4 paquetes de interés: `GET /`, `200 OK (text/html)`, `GET /public-inventory.txt`, `200 OK (text/plain)`. Al aplicar **Follow → HTTP Stream** sobre la petición al inventario, se observó en texto plano:

```
GET /public-inventory.txt HTTP/1.1
Host: 192.168.92.132
User-Agent: curl/8.20.0
Accept: */*

HTTP/1.1 200 OK
Server: nginx/1.28.3 (Ubuntu)
Content-Type: text/plain; charset=utf-8
Content-Length: 881

CrowdStrike Incident Hub - Inventario público de demostración (datos ficticios, uso académico)
...
ALERT_ID       SEVERITY  TACTIC (simulada)      STATUS
ALT-LAB-1001   Critical  Command & Control      Nueva
ALT-LAB-1002   High      Credential Access      En triage
ALT-LAB-1003   Medium    Discovery              Cerrada
```

Esto demuestra de forma directa que, sin TLS, cualquiera en la ruta de red puede leer el contenido completo — incluidas las "alertas" ficticias del prototipo — sin necesidad de explotar ninguna vulnerabilidad de la aplicación.

---

## 5. Resultado del análisis pasivo con OWASP ZAP

Reporte completo: [`reports/zap-passive/2026-09-16-ZAP-Report-.html`](muvautomation-secure-challenge/reports/zap-passive/2026-09-16-ZAP-Report-.html)

- **2 alertas de riesgo Medio, 2 de riesgo Bajo, 0 Altas** (exploración pasiva, sin Active Scan).
- Coinciden con lo esperado antes del hardening: ausencia de headers de seguridad.
- Insights: 100% de respuestas `2xx`, 2 endpoints totales (`text/html` y `text/plain`), 100% método `GET`.

---

## 6. Preguntas de análisis (Sección 12 de la guía)

**¿Qué pudo observar el Red Team sin explotar ninguna vulnerabilidad?**
El banner completo de versión de Nginx (`1.28.3 (Ubuntu)`), el HTML completo del portal y del inventario de alertas ficticias en texto plano, todos los headers de respuesta, y la ausencia de controles básicos de seguridad — todo mediante reconocimiento pasivo (Nmap, curl, ZAP en modo pasivo, lectura del PCAP).

**¿Qué pruebas de red no aparecieron en `access.log` y por qué?**
El descubrimiento/handshake TCP de bajo nivel de Nmap no deja rastro en `access.log`, porque ese log solo registra peticiones HTTP completas a nivel de aplicación. Lo que sí quedó registrado fueron las *sondas de detección de servicio* (`-sV`), que sí generan peticiones HTTP reales (`/HNAP1`, `/sdk`, etc.). Adicionalmente, `journalctl -u nginx` no mostró ninguna entrada ("No entries") porque esta instalación de Nginx no reenvía sus logs al journal de systemd, solo escribe en `access.log`/`error.log` — una limitante real de visibilidad que hay que tener en cuenta como Blue Team.

**¿Qué control aplicado reduce exposición, pero no resuelve el riesgo de HTTP?**
`server_tokens off` + los 3 headers de seguridad + el bloqueo de rutas ocultas (`location ~ /\.`) reducen la fuga de metadatos (versión de software, clickjacking, MIME sniffing, rutas sensibles), pero **no cifran el tráfico**. El PCAP capturado después del hardening seguiría mostrando el mismo contenido en texto plano — ese riesgo de confidencialidad/integridad permanece abierto hasta implementar HTTPS en el Laboratorio 4.

**¿Qué datos necesitaría Blue Team para distinguir `curl` legítimo de actividad sospechosa?**
Un solo request de `curl` no es sospechoso por sí mismo. Blue Team necesitaría correlacionar: frecuencia de solicitudes por IP en una ventana de tiempo, patrones de rutas no estándar (como las sondas de Nmap observadas: `/HNAP1`, `/sdk`, `/evox/about`), ausencia de cabeceras típicas de navegador (`Referer`, `Accept-Language`), reputación/contexto de la IP de origen (¿está dentro del `LAB_CIDR` autorizado?), y si la actividad coincide con una ventana de prueba autorizada y documentada.

**¿Qué amenaza STRIDE debe priorizarse en el Laboratorio 4?**
**Information Disclosure / Tampering** derivados de la ausencia de TLS (H1 y H4 de la tabla STRIDE, R1 y R6 del `risk-register.md`). Es el único riesgo que quedó explícitamente "pendiente para Lab 4" en el registro de riesgos, y es exactamente lo que introduce el siguiente laboratorio (HTTPS + identidad + roles).

**¿Qué conclusión propuesta por la IA no pudo comprobarse directamente?**
Durante la corrección del hardening, la hipótesis inicial de que `systemctl reload nginx` no aplicaba los cambios (a diferencia de `restart`) nunca se comprobó a fondo — se resolvió empíricamente usando `restart` en su lugar, pero la causa raíz exacta (por qué `reload` no bastaba en este entorno) quedó sin diagnosticar. Es un buen ejemplo de una "solución que funcionó" sin una explicación técnica completamente verificada.

---

## 7. Riesgos — estado final

Ver detalle completo en [`risk-register.md`](muvautomation-secure-challenge/risk-register.md). Resumen:

| Riesgo | Estado |
|---|---|
| R1 — Tráfico HTTP sin cifrar | Pendiente para Lab 4 |
| R2 — Banner de versión de Nginx | ✅ Corregido |
| R3 — Headers de seguridad faltantes | ✅ Corregido |
| R4 — Rutas ocultas accesibles | ✅ Corregido |
| R5 — Falta de correlación temporal | ✅ Mitigado (línea de tiempo Purple Team) |
| R6 — Ausencia de TLS ante tampering | Aceptado para Lab 3, pendiente para Lab 4 |

---

## 8. Reproducción

Ver [`README.md`](muvautomation-secure-challenge/README.md) para variables de entorno y el orden exacto de scripts (`scripts/00-verify-host.sh` a `scripts/06-retest.sh`).

**Tag de entrega:** `lab-3`
