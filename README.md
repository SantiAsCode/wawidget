# WAWidget

Widget **no oficial** de WhatsApp Web para **KDE Plasma 6**. Muestra WhatsApp Web en un widget flotante de escritorio o en el panel (icono + popup), usando Qt WebEngine.

> Este proyecto no está afiliado, asociado ni respaldado por Meta/WhatsApp. «WhatsApp» es una marca registrada de Meta Platforms, Inc. Úsalo bajo tu responsabilidad y respetando los términos de servicio de WhatsApp.

## Características

- Widget de escritorio flotante y redimensionable, o applet de panel con popup.
- Sesión persistente: escaneas el QR una vez y se conserva entre reinicios.
- **Multi-cuenta**: cada instancia del widget usa su propio perfil aislado (Cookies, IndexedDB, Local Storage), por lo que puedes vincular una cuenta distinta en cada una.
- User-Agent editable desde la configuración (WhatsApp Web exige una versión reciente de Chrome; por defecto se envía una actual).
- Icono configurable por instancia con el selector de iconos de KDE.
- Sin barra de navegación, sin pestañas: exclusivo para WhatsApp Web.

## Requisitos

- KDE Plasma 6 (API mínima 6.0)
- Qt 6 WebEngine (`qt6-webengine`, `qml6-module-qtwebengine`)
- Probado en Debian 13 con Plasma 6.3.6 y Qt 6.8.2

## Instalación

Desde KDE Store: *Añadir widgets* → *Obtener nuevos widgets* (cuando el widget esté publicado y sincronizado).

Desde el archivo `.plasmoid`:

```bash
kpackagetool6 -t Plasma/Applet -i wawidget-1.0.0.plasmoid
```

Desde el código fuente:

```bash
kpackagetool6 -t Plasma/Applet -i .
```

Actualizar y desinstalar:

```bash
kpackagetool6 -t Plasma/Applet -u .
kpackagetool6 -t Plasma/Applet -r io.github.santiascode.wawidget
```

## Uso

1. Clic derecho en el escritorio o en el panel → *Añadir widgets* → **WAWidget**.
2. Escanea el QR con tu teléfono (WhatsApp → Dispositivos vinculados). En el teléfono aparecerá como «Chrome».
3. Para una segunda cuenta, añade otra instancia de WAWidget y vincula la otra cuenta con su QR.

Cada instancia guarda su sesión en `~/.local/share/plasmashell/QtWebEngine/wawidget-<id>/`.

## Configuración

Clic derecho en el widget → *Configurar*:

- **Icono**: elegir o restaurar el icono de esa instancia.
- **User-Agent**: valor enviado por el navegador embebido. Si WhatsApp Web muestra un aviso de «navegador no compatible», actualiza este campo con el User-Agent de un Chrome reciente.

## Limitaciones

- Sin notificaciones en segundo plano: la página solo está activa cuando el widget está visible (en el panel, al cerrar el popup se descarga la página).
- Las descargas de archivos se guardan en la carpeta de descargas del sistema.
- Llamadas de voz/video pueden no funcionar según la versión de Qt WebEngine.

## Empaquetado

```bash
./package.sh
```

Genera `dist/wawidget-<versión>.plasmoid`, el archivo que se sube a KDE Store o a una release de GitHub.

## Licencia

MIT — ver [LICENSE](LICENSE).

---

# WAWidget (English)

**Unofficial** WhatsApp Web widget for **KDE Plasma 6**. It shows WhatsApp Web in a floating desktop widget or in the panel (icon + popup) using Qt WebEngine. Each widget instance uses its own isolated profile, so you can link a different account per instance. The User-Agent and the icon are configurable per instance. Not affiliated with Meta/WhatsApp. Licensed under MIT.
