# Línea de tiempo Purple Team (Paso 14)

Llenar entre Johan (evidencia Blue) y Camilo (acción Red), usando timestamps UTC reales.

| Hora UTC | Acción Red Team | Evidencia Blue Team | Conclusión |
|----------|------------------|-----------------------|------------|
| | Nmap port 80 | access.log puede no registrar el SYN scan | Diferenciar red vs. aplicación |
| | GET / | 200 en access.log | Correlación confirmada |
| | GET archivo (`public-inventory.txt`) | 200 en access.log y visible en PCAP | Contenido visible por HTTP |
| | Ruta inexistente | 404 en access.log | Detección validada |
