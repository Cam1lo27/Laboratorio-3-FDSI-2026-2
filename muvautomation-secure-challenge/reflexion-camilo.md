# Reflexión individual — Andrés Camilo Vivas Baquero (Red Team)

Lo que más me llamó la atención de este laboratorio es lo fácil que fue conseguir información del servidor sin explotar nada. Con un simple `nmap -sV` ya sabía qué versión exacta de Nginx corría, y con `curl` podía leer el HTML completo de la página y del inventario de alertas, incluidos datos que en un caso real no deberían verse tan fácil.

El reporte pasivo de ZAP también me sorprendió por lo directo que fue: sin correr ningún ataque activo, ya marcaba la falta de headers de seguridad básicos. Eso conecta directo con las hipótesis H1 y H2 de STRIDE que habíamos planteado antes de empezar — no eran solo teoría, se vieron reflejadas en la práctica casi de inmediato.

Una limitación que noté en mis propias pruebas es que el escaneo de puertos de Nmap en sí no deja rastro en el `access.log`; solo quedan registradas las sondas que sí generan peticiones HTTP reales. Eso significa que, si alguien solo mira ese log, se puede perder parte del reconocimiento que en verdad ocurrió.
