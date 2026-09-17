# Reflexión individual — Johan Sebastián Beltrán Gutiérrez (Blue Team)

Revisando el `access.log` pude confirmar casi todas las acciones que hizo Camilo: el nmap, los curl y hasta la navegación de ZAP quedaron con su hora exacta, lo que ayudó bastante a armar la línea de tiempo. Lo que no esperaba es que las sondas de detección de Nmap generan peticiones HTTP reales y también quedan registradas ahí, no solo el tráfico "normal".

La regla de 5 o más respuestas 404 en 5 minutos funciona para detectar un escaneo como el nuestro, pero tiene sus límites: un atacante que vaya más lento, o que reparta las peticiones desde varias IPs, no la activaría. Es una señal simple, no una detección definitiva.

Sobre el hardening: aplicar `server_tokens off` y los headers de seguridad sí redujo la información que el servidor entrega de más, pero no cambia el hecho de que todo sigue viajando por HTTP sin cifrar. Ese riesgo lo dejamos anotado como pendiente para el Laboratorio 4. Me hubiera gustado tener más tiempo para correlacionar el PCAP con el log al mismo nivel de detalle que hicimos con los timestamps.
