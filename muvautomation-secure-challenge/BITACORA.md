# Bitácora Laboratorio 3 — CrowdStrike Incident Hub

**Equipo:** Andrés Camilo Vivas Baquero (Red Team) · Johan Sebastián Beltrán Gutiérrez (Blue Team / Builder)
**Grupo:** G07 · **Temática:** Opción 1 — Automatización de incidentes de CrowdStrike Falcon
**Fecha de ejecución:** 2026-09-16 (UTC)
**Objetivo:** Publicar el prototipo "CrowdStrike Incident Hub" por HTTP sin autenticación, ejecutar el ciclo completo Diseñar → Construir → Atacar → Detectar → Corregir → Verificar, y dejar evidencia reproducible.

> Las capturas de este documento están en [`evidence/screenshots/`](muvautomation-secure-challenge/evidence/screenshots/), seleccionadas de todas las tomadas durante la sesión (se descartaron las que solo mostraban pasos de instalación/configuración de las VMs sin valor como evidencia técnica del laboratorio).

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

![Kali listo tras cambiar de instalador ISO a imagen VMware oficial](muvautomation-secure-challenge/evidence/screenshots/03-kali-ova-listo.png)

*El instalador ISO de Kali falló repetidamente por corrupción de paquetes leídos desde el medio virtual (`Hashes of expected file` no coincidían). Se resolvió usando la imagen VMware pre-armada oficial de Kali, evitando reinstalar desde cero.*

---

## 2. Fase A — Construcción y publicación

```bash
bash scripts/00-verify-host.sh
bash scripts/01-deploy-nginx.sh
```

![Primer intento de despliegue mostrando la página por defecto de Nginx en vez del sitio, y estado del firewall ufw](muvautomation-secure-challenge/evidence/screenshots/01-baseline-y-firewall.png)

*Al primer `curl` local apareció la página por defecto "Welcome to nginx!" en vez del sitio — el virtual host no había tomado efecto con `reload`. La misma captura confirma el firewall (`ufw`) activo y limitado a `192.168.92.0/24` + OpenSSH, tal como pide el Paso 5 de la guía.*

![Sitio CrowdStrike Incident Hub respondiendo correctamente tras systemctl restart](muvautomation-secure-challenge/evidence/screenshots/02-sitio-desplegado-fix.png)

*Diagnóstico: la configuración (`/etc/nginx/sites-available/muvautomation`) y los archivos publicados en `/var/www/muvautomation/` eran correctos; el problema era que `systemctl reload nginx` no aplicaba el cambio de virtual host. Se solucionó con `systemctl restart nginx`, y el sitio quedó sirviendo el HTML real (`200 OK`, `Content-Length: 7257`).*

---

## 3. Fase C — Reconocimiento y exploración pasiva (Red Team)

```bash
bash scripts/02-red-recon.sh
```
Resultado: `evidence/red/nmap_port80.nmap` (puerto 80 abierto, `nginx 1.28.3 (Ubuntu)` visible en el banner), `curl_home.txt`, `curl_headers.txt`.

![Sitio CrowdStrike Incident Hub cargado dentro del navegador proxy de OWASP ZAP (Manual Explore)](muvautomation-secure-challenge/evidence/screenshots/04-zap-manual-explore-sitio.png)

*Exploración manual (`Manual Explore`, sin Active Scan) del sitio y de `/public-inventory.txt`, navegando a través del proxy de ZAP para que quede registrado en `History`/`Alerts` de forma pasiva.*

![Reporte HTML de ZAP: resumen de alertas por nivel de riesgo e insights](muvautomation-secure-challenge/evidence/screenshots/05-zap-reporte-resumen-alertas.png)

*Resultado del reporte pasivo: 0 alertas Altas, 2 Medias, 2 Bajas — coherente con la ausencia de headers de seguridad antes del hardening. Insights: 100% de respuestas `2xx`, 2 endpoints (`text/html` y `text/plain`), 100% método `GET`. Reporte completo en [`reports/zap-passive/2026-09-16-ZAP-Report-.html`](muvautomation-secure-challenge/reports/zap-passive/2026-09-16-ZAP-Report-.html).*

---

## 4. Captura de tráfico y evidencia de Information Disclosure (H1 — STRIDE)

```bash
# Blue Team, en Ubuntu:
bash scripts/03a-blue-capture.sh
# Red Team, en Kali, durante los 60s:
bash scripts/03b-red-fetch.sh
```

![Terminal de Ubuntu mostrando dos intentos fallidos de captura (0 paquetes, luego permiso denegado) y el tercer intento exitoso con 22 paquetes capturados](muvautomation-secure-challenge/evidence/screenshots/06-captura-trafico-tcpdump.png)

*Primer intento: 0 paquetes (Red Team no llegó a tiempo a los 60s de ventana). Segundo intento: `Permission denied` por un proceso `tcpdump` colgado del intento anterior sobre `/tmp/lab3-http.pcap`. Se resolvió con `sudo pkill tcpdump && sudo rm -f /tmp/lab3-http.pcap` y se repitió la captura: **22 paquetes capturados** correctamente.*

El PCAP se trajo a Kali con `scp` y se abrió en Wireshark:

![Wireshark con filtro http mostrando las 4 peticiones/respuestas relevantes del PCAP](muvautomation-secure-challenge/evidence/screenshots/07-wireshark-filtro-http.png)

*Filtro `http` sobre `evidence/blue/lab3-http.pcap` (22 paquetes totales, 4 mostrados): `GET /`, `200 OK (text/html)`, `GET /public-inventory.txt`, `200 OK (text/plain)`.*

![Wireshark Follow HTTP Stream mostrando el contenido completo en texto plano, incluidas las alertas ficticias](muvautomation-secure-challenge/evidence/screenshots/08-wireshark-http-stream-texto-plano.png)

*Al aplicar **Follow → HTTP Stream** sobre la petición a `/public-inventory.txt`, se observa el contenido completo en texto plano: el `User-Agent: curl/8.20.0`, el `Server: nginx/1.28.3 (Ubuntu)`, y el cuerpo completo del inventario con las alertas ficticias (`ALT-LAB-1001 Critical Command & Control`, etc.). Esto demuestra de forma directa que, sin TLS, cualquiera en la ruta de red puede leer el contenido completo sin explotar ninguna vulnerabilidad de la aplicación — la evidencia central de H1.*

---

## 5. Fase D — Detección y correlación (Blue Team)

```bash
bash scripts/04-blue-detect.sh
```

![access.log completo mostrando las peticiones de línea base, Nmap, curl y ZAP correlacionadas por timestamp](muvautomation-secure-challenge/evidence/screenshots/09-deteccion-access-log.png)

*Las sondas de detección de servicio de Nmap (`-sV`) sí generan peticiones HTTP reales y quedan registradas: `/HNAP1`, `/sdk`, `/evox/about`, `/nmaplowercheck...`, todas con `User-Agent: Mozilla/5.0 (compatible; Nmap Scripting Engine...)` y todas `404`. También se ve la navegación real de Firefox durante la sesión de ZAP.*

![Regla de detección: IPs con 5+ respuestas 404, y requests que coinciden con herramientas de reconocimiento](muvautomation-secure-challenge/evidence/screenshots/10-deteccion-regla-404.png)

*`journalctl -u nginx` no mostró ninguna entrada ("No entries") — esta instalación de Nginx no reenvía logs al journal de systemd, solo escribe en `access.log`/`error.log`. La regla de "5+ respuestas 404 en 5 minutos" identificó correctamente las sondas de Nmap como actividad de reconocimiento.*

---

## 6. Fase E/F — Corrección y verificación (antes/después)

```bash
bash scripts/05-harden-nginx.sh   # Ubuntu
bash scripts/06-retest.sh         # Kali
```

![Primer intento de verificación post-hardening mostrando que los headers nuevos aún no aparecían](muvautomation-secure-challenge/evidence/screenshots/11-hardening-antes-bug-reload.png)

*Igual que en el despliegue inicial, `systemctl reload nginx` no aplicó la nueva configuración con hardening (headers ausentes, `Server: nginx/1.28.3 (Ubuntu)` sin ocultar). Mismo patrón de bug, misma causa probable.*

![Verificación tras systemctl restart: Server solo dice "nginx" y aparecen los 3 headers de seguridad](muvautomation-secure-challenge/evidence/screenshots/12-hardening-despues-headers-ok.png)

*Con `systemctl restart nginx`, la corrección sí se aplicó: `Server: nginx` (sin versión), `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`.*

![Retest desde Kali: /.git/config responde 403 Forbidden con los headers de seguridad presentes](muvautomation-secure-challenge/evidence/screenshots/13-retest-git-config-403.png)

*Confirmación final desde Red Team: la ruta oculta `/.git/config`, que antes del hardening no había sido probada, ahora responde `403 Forbidden` en vez de `200`.*

| Aspecto | Antes (`evidence/red/`) | Después (`evidence/retest/`) |
|---|---|---|
| Banner de servidor (Nmap) | `nginx 1.28.3 (Ubuntu)` | `nginx` (sin versión) |
| Header `Server` (curl) | `nginx/1.28.3 (Ubuntu)` | `nginx` |
| Headers de seguridad | Ausentes | `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy` |
| Ruta oculta `/.git/config` | No probada aún | `403 Forbidden` |
| Confidencialidad del tráfico HTTP | Sin cifrar (confirmado por PCAP) | **Sin cambio** — sigue abierto para Lab 4 |

Esto confirma exactamente la regla pedagógica de la guía: el hardening reduce la **exposición de metadatos** (Information Disclosure), pero no resuelve el riesgo de fondo de **confidencialidad/integridad** de HTTP sin cifrar.

---

## 7. Línea de tiempo completa (Purple Team)

| Hora UTC | Actor | Acción | Evidencia |
|---|---|---|---|
| 19:08:08 | Builder | Verificación de línea base del host | `evidence/blue/00-baseline.txt` |
| 19:09:24 | Builder | Nginx desplegado (tras corregir el bug de `reload`) | Sección 2 |
| 19:09:24 | Builder | Firewall (`ufw`) limitado a `192.168.92.0/24` + OpenSSH | Sección 2 |
| 21:33:26 | Red Team | Verificación manual de acceso remoto | consola Kali |
| **21:35:10** | Red Team | `nmap -sV -p 80` + `curl -i /` + `curl -I /public-inventory.txt` | Sección 3 |
| 21:35:10 | Blue Team | Sondas de Nmap quedan registradas como `404` en `access.log` | Sección 5 |
| 21:44–21:53 | Red Team | Exploración pasiva con OWASP ZAP | Sección 3 |
| **22:06:13** | Blue Team + Red Team | Captura coordinada de 60s (`tcpdump`) | Sección 4 |
| 22:15 | Blue Team | Revisión de logs y regla de detección | Sección 5 |
| 22:20 | Blue Team | Aplicación del hardening | Sección 6 |
| **22:24:46 – 22:24:52** | Red Team | Retest completo | Sección 6 |

---

## 8. Preguntas de análisis (Sección 12 de la guía)

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
Durante la corrección del hardening (y también durante el despliegue inicial), la hipótesis de que `systemctl reload nginx` no aplicaba los cambios de virtual host (a diferencia de `restart`) nunca se comprobó a fondo — se resolvió empíricamente usando `restart` en su lugar dos veces, pero la causa raíz exacta (por qué `reload` no bastaba en este entorno) quedó sin diagnosticar. Es un buen ejemplo de una "solución que funcionó" sin una explicación técnica completamente verificada.

---

## 9. Riesgos — estado final

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

## 10. Reproducción

Ver [`README.md`](muvautomation-secure-challenge/README.md) para variables de entorno y el orden exacto de scripts (`scripts/00-verify-host.sh` a `scripts/06-retest.sh`).

**Tag de entrega:** `lab-3`
