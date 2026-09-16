

| Hora UTC | Acción Red Team | Evidencia Blue Team | Conclusión |
|----------|------------------|-----------------------|------------|
| 2026-09-16T21:35:10Z | Nmap port 80 | access.log registró las sondas HTTP de Nmap (HNAP1, sdk, evox/about), no el SYN scan puro | Diferenciar red vs. aplicación |
| 2026-09-16T21:35:10Z | GET / | 200 en access.log | Correlación confirmada |
| 2026-09-16T22:06:13Z | GET archivo (`public-inventory.txt`) | 200 en access.log y visible en PCAP | Contenido visible por HTTP |
| 2026-09-16T21:35:10Z | Ruta inexistente (`/HNAP1`) | 404 en access.log | Detección validada |
