# Checklist — Publicar WAWidget en KDE Store

1. **Cuenta**: inicia sesión en https://store.kde.org (se usa la cuenta de Pling/KDE Identity).

2. **Crear producto**: *Add Product*.

3. **Categoría exacta** (necesaria para que aparezca en «Obtener nuevos widgets…»):
   `Linux/Unix Desktops → Desktop Extensions → KDE Plasma Extensions → Plasma 6 Extensions → Plasma 6 Applets`

4. **Archivo**: genera el paquete con `./package.sh` y sube `dist/wawidget-1.0.0.plasmoid`.
   Alternativa: enlazar la release de GitHub (`https://github.com/SantiAsCode/wawidget/releases`).

5. **Ficha**:
   - Nombre: `WAWidget`
   - Descripción: pegar `store/descripcion-es.md` (y/o `store/descripcion-en.md`).
   - Licencia: MIT
   - Homepage: https://github.com/SantiAsCode/wawidget
   - Versión: 1.0.0

6. **Capturas** (con Spectacle, ya instalado):
   - `spectacle -b -n -o captura-escritorio.png` (widget flotante en el escritorio)
   - `spectacle -b -n -o captura-panel.png` (popup abierto desde el panel)
   - `spectacle -b -n -o captura-config.png` (diálogo de configuración: icono + User-Agent)

7. **Publicar** y esperar la sincronización con KNewStuff. Notas:
   - Puede tardar en aparecer en «Obtener nuevos widgets…».
   - El buscador del diálogo requiere al menos 3 letras.
   - Si no aparece tras un tiempo, reportarlo en https://forum.opendesktop.org (categoría Pling.com).

8. **Actualizaciones**: sube una nueva versión del `.plasmoid`, actualiza `Version` en `metadata.json`, regenera el paquete y edita el producto en la tienda.
