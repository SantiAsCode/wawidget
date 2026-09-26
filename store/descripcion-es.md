# WAWidget — Descripción para KDE Store (ES)

**Nombre del producto:** WAWidget
**Categoría:** Linux/Unix Desktops → Desktop Extensions → KDE Plasma Extensions → Plasma 6 Extensions → Plasma 6 Applets
**Licencia:** MIT
**Sitio web:** https://github.com/SantiAsCode/wawidget

## Descripción corta

Widget no oficial de WhatsApp Web para KDE Plasma 6: escritorio flotante o panel, con sesión persistente y una cuenta por instancia.

## Descripción larga

WAWidget muestra WhatsApp Web dentro de KDE Plasma usando Qt WebEngine. Puede colocarse como widget flotante en el escritorio o como applet de panel con popup.

Características:

- Escanea el QR una sola vez: la sesión se guarda y se conserva entre reinicios y actualizaciones del shell.
- Multi-cuenta: cada instancia del widget usa un perfil aislado (Cookies, IndexedDB, Local Storage), así que puedes vincular una cuenta distinta en cada una.
- User-Agent editable desde la configuración; por defecto envía un Chrome reciente para evitar el aviso de «navegador no compatible» de WhatsApp Web.
- Icono configurable por instancia con el selector de iconos de KDE.
- Enlaces externos se abren en el navegador predeterminado y las descargas van a la carpeta de descargas del sistema.
- Interfaz mínima: sin barra de direcciones ni pestañas, solo WhatsApp Web.

Aviso: este widget es un proyecto no oficial y no está afiliado ni respaldado por Meta/WhatsApp. «WhatsApp» es una marca registrada de Meta Platforms, Inc.

Requisitos: KDE Plasma 6 y Qt 6 WebEngine (`qt6-webengine`, `qml6-module-qtwebengine`).

Limitaciones: sin notificaciones en segundo plano (la página se descarga al cerrar el popup del panel) y las llamadas de voz/video pueden no funcionar según la versión de Qt WebEngine.
