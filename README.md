# WAWidget

Widget **no oficial** de WhatsApp Web para **KDE Plasma 6**. Muestra WhatsApp Web en un widget flotante de escritorio o en el panel (icono + popup), usando Qt WebEngine.

> Este proyecto no está afiliado, asociado ni respaldado por Meta/WhatsApp. «WhatsApp» es una marca registrada de Meta Platforms, Inc. Úsalo bajo tu responsabilidad y respetando los términos de servicio de WhatsApp.

## Características

- Widget de escritorio flotante y redimensionable, o applet de panel con popup.
- Sesión persistente: escaneas el QR una vez y se conserva entre reinicios.
- **Pestañas multi-cuenta**: cada cuenta tiene su perfil aislado (cookies, IndexedDB y almacenamiento local). Se pueden añadir, renombrar y quitar pestañas.
- Cuentas activas en segundo plano por defecto, con modo de ahorro configurable.
- Chincheta configurable para mantener abierto el popup al cambiar de aplicación o tomar capturas.
- Barra superior autoocultable: aparece al acercar el cursor al borde superior o pulsar **F6**, haciendo espacio sin tapar los controles de WhatsApp.
- Menú contextual para copiar texto, enlaces e imágenes.
- Descargas con progreso, cancelación, errores y botón para abrir su carpeta.
- Vista configurable: columna de chats angosta, listado compacto y botón para plegar/desplegar chats.
- User-Agent editable desde la configuración (WhatsApp Web exige una versión reciente de Chrome; por defecto se envía una actual).
- Icono configurable por instancia con el selector de iconos de KDE.
- Sin barra de navegación: exclusivo para WhatsApp Web.

## Requisitos

- **KDE Plasma 6** (API mínima declarada: 6.0). No es compatible con Plasma 5.
- **Qt WebEngine 6.8 o posterior**, incluido el módulo QML `QtWebEngine`, y los módulos QML de Qt/KDE que utiliza Plasma.
- Conexión a Internet y WhatsApp en el teléfono para vincular la cuenta.

WAWidget no es exclusivo de Debian: el mismo archivo `.plasmoid` puede instalarse en otras distribuciones con Plasma 6 y las dependencias anteriores, sin compilar. La compatibilidad depende de las versiones instaladas, no solo del nombre de la distribución.

**Probado en Debian 13 con Plasma 6.3.6 y Qt 6.8.2.** Otras distribuciones todavía necesitan validación.

> **Importante:** tener Plasma 6 no garantiza disponer de una versión suficiente de Qt WebEngine. El código actual utiliza la señal [`permissionRequested`](https://doc.qt.io/qt-6/qml-qtwebengine-webengineview.html#permissionRequested-signal), introducida en Qt 6.8. Con una versión anterior, el widget puede fallar al cargar.

## Instalación

### 1. Instalar las dependencias

Sobre una instalación de Plasma 6, los paquetes habituales para añadir Qt WebEngine son:

| Distribución | Comando |
| --- | --- |
| Debian / Kubuntu | `sudo apt install qml6-module-qtwebengine qml6-module-qtcore` |
| Fedora KDE | `sudo dnf install qt6-qtwebengine` |
| Arch Linux / EndeavourOS | `sudo pacman -S qt6-webengine` |

Estos comandos no actualizan una distribución antigua a Plasma 6 ni garantizan Qt WebEngine 6.8 o posterior: comprueba la versión del paquete en tu gestor de software. En otras distribuciones, busca el paquete que proporciona el módulo QML `QtWebEngine` de Qt 6.

También necesitas `kpackagetool6` para instalar desde terminal; normalmente está disponible con Plasma 6. No se necesitan paquetes de desarrollo ni un compilador.

### 2. Instalar WAWidget

Elige **una** de las siguientes alternativas. Instala el widget con tu usuario habitual, **sin `sudo`**.

#### Desde un archivo `.plasmoid`

Obtén un paquete de WAWidget o genera uno como se explica en [Empaquetado](#empaquetado). Por ejemplo, puedes compartir `dist/wawidget-1.1.5.plasmoid` con otro equipo; no incluye tus cuentas ni tus mensajes.

Desde la carpeta donde hayas guardado el archivo:

```bash
kpackagetool6 -t Plasma/Applet -i wawidget-1.1.5.plasmoid
```

También puedes instalarlo gráficamente:

1. Abre **Añadir widgets** desde el escritorio o el panel.
2. Busca **Instalar widget desde archivo local…** en el menú de gestión de widgets (la etiqueta puede variar según la versión de Plasma).
3. Selecciona el archivo `.plasmoid`.

#### Desde GitHub

Con Git y las dependencias anteriores instaladas:

```bash
git clone https://github.com/SantiAsCode/wawidget.git
cd wawidget
kpackagetool6 -t Plasma/Applet -i .
```

#### Desde KDE Store

Cuando el widget esté publicado y sincronizado, podrá instalarse desde **Añadir widgets → Obtener nuevos widgets**.

### 3. Añadir el widget y vincular WhatsApp

Busca **WAWidget** en **Añadir widgets**, añádelo al panel o al escritorio y escanea el QR desde **WhatsApp → Dispositivos vinculados** en tu teléfono. Cada usuario y equipo conserva su propia sesión.

### Actualizar

Si ya está instalado, usa `-u` en lugar de `-i`. Para actualizar desde un archivo:

```bash
kpackagetool6 -t Plasma/Applet -u wawidget-1.1.5.plasmoid
```

O desde la carpeta del repositorio clonado:

```bash
git pull --ff-only
kpackagetool6 -t Plasma/Applet -u .
```

Después, cierra sesión y vuelve a entrar, o reinicia Plasma, para recargar el widget. No hace falta reiniciar el sistema. **No quites y vuelvas a añadir el widget existente**, porque cambiaría su identificador y no reutilizaría automáticamente el perfil anterior.

### Desinstalar

```bash
kpackagetool6 -t Plasma/Applet -r io.github.santiascode.wawidget
```

## Uso

1. Clic derecho en el escritorio o en el panel → *Añadir widgets* → **WAWidget**.
2. Escanea el QR con tu teléfono (WhatsApp → Dispositivos vinculados). En el teléfono aparecerá como «Chrome».
3. Para otra cuenta, pulsa **Añadir cuenta** en la barra superior, dale un nombre y escanea su QR.
4. El menú de la barra permite renombrar/quitar la cuenta actual y activar o desactivar cada ajuste visual y el segundo plano.
5. La **chincheta** de la barra fija el popup para que no se cierre al perder el foco. La preferencia se conserva entre reinicios y también está disponible en la configuración. Desactivarla restaura el cierre automático. Fijar no significa mantener por encima de otras ventanas; el icono del panel sigue permitiendo cerrar el popup manualmente.
6. La barra se oculta automáticamente tras **800 ms** al alejar el cursor. Acercalo a la zona superior para mostrarla; también podés pulsar **F6** y navegar con Tab. Al aparecer desplaza WhatsApp hacia abajo, sin tapar sus controles; al ocultarse devuelve toda la altura al contenido. No se oculta mientras usás un menú, diálogo o sus controles con el teclado. Desactivá **Ocultar barra automáticamente** en el menú para dejarla siempre visible. Fijar el popup no cambia este comportamiento.

Al actualizar se conserva el perfil original `~/.local/share/plasmashell/QtWebEngine/wawidget-<id>/` para la primera cuenta. Las nuevas usan nombres únicos derivados de ese identificador. No se deben abrir esos perfiles simultáneamente desde otro proceso.

Quitar una cuenta elimina su pestaña, no borra los datos locales ni desvincula el dispositivo en WhatsApp. Para desvincularlo, utiliza **Dispositivos vinculados** en el teléfono. No se permite quitar cuentas mientras haya descargas en curso. Los datos conservados no se recuperan automáticamente al añadir otra pestaña: esta crea un perfil nuevo.

Una actualización en disco no sustituye el QML que Plasma ya tiene cargado. Para ver los cambios en el panel, reinicia Plasma o cierra y vuelve a iniciar sesión. **No quites y vuelvas a añadir el widget existente**: cambiaría su identificador y no reutilizaría automáticamente el perfil anterior.

## Configuración

Clic derecho en el widget → *Configurar*:

- **Icono**: elegir o restaurar el icono de esa instancia.
- **Ocultar automáticamente la barra superior**: activado por defecto. Desactivarlo reserva espacio para la barra y la deja siempre visible.
- **User-Agent**: valor enviado por el navegador embebido. Si WhatsApp Web muestra un aviso de «navegador no compatible», actualiza este campo con el User-Agent de un Chrome reciente.
- **Segundo plano**: activado por defecto. Desactivarlo suspende las páginas no visibles, conservando sus sesiones; puede detener la recepción hasta volver a abrirlas. Una descarga en curso mantiene activa su cuenta.
- **Vista de chats**: columna angosta, listado compacto y botón de plegado se habilitan por separado, sin volver a vincular la cuenta. Desactivarlos restaura la presentación original. La lista compacta reduce únicamente la escala del listado para respetar la virtualización de filas de WhatsApp.

## Limitaciones

- Mantener páginas activas no equivale a integrar notificaciones nativas ni contadores de mensajes en el panel; esa integración no está incluida.
- Las descargas de archivos se guardan en la carpeta de descargas del sistema.
- La lista de descargas corresponde a la sesión actual del widget; no es un historial persistente.
- Los ajustes CSS dependen de los selectores actuales de WhatsApp Web (`#side`, `#pane-side`, `#main`). La columna angosta detecta el contenedor flex completo, adapta el panel contiguo y oculta los bordes decorativos desalineados de capas de fondo independientes, conservando el separador en el límite real. Podrían necesitar ajustes si WhatsApp cambia su interfaz. El plegado solo se aplica cuando existe el panel de conversación.
- Llamadas de voz/video pueden no funcionar según la versión de Qt WebEngine.

## Empaquetado

Desde la carpeta del repositorio, con Bash, Python 3 y `zip` instalados:

```bash
./package.sh
```

Genera `dist/wawidget-<versión>.plasmoid`, que puedes compartir entre distribuciones compatibles o publicar en KDE Store o en una release de GitHub. El script reemplaza el contenido previo de `dist/`.

## Prueba de integración

En una sesión gráfica con `plasmawindowed` disponible:

```bash
node tests/chat-style.test.cjs
python3 tests/plasma-smoke.py
```

La prueba crea un paquete y directorios XDG temporales bajo `/tmp/opencode`, utiliza una página local sin cuentas reales y comprueba la barra autoocultable (estados simulados sin mover el cursor), perfiles aislados, conservación de vistas, suspensión y una descarga `blob:` cuyo contenido se verifica. No prueba los selectores contra WhatsApp real ni inicia sesión. Si están disponibles `xwininfo` e ImageMagick, guarda una captura de la ventana de prueba en `/tmp/opencode/wawidget-window.png`.

## Licencia

MIT — ver [LICENSE](LICENSE).

---

# WAWidget (English)

**Unofficial** WhatsApp Web widget for **KDE Plasma 6**, requiring **Qt WebEngine 6.8 or later** and its QML module. The same `.plasmoid` package can be installed across distributions meeting these requirements, without compilation; Plasma 5 is not supported. Tested on Debian 13 with Plasma 6.3.6 and Qt 6.8.2; other distributions still need validation. Install as your regular user with `kpackagetool6 -t Plasma/Applet -i wawidget-1.1.5.plasmoid`, then add WAWidget to your panel or desktop and scan the QR code. Account tabs have isolated persistent profiles. Includes configurable background activity, native context menus, download progress and reversible compact-chat options. Existing widget profiles are preserved on upgrade. CSS compatibility still needs validation against the logged-in WhatsApp interface. Not affiliated with Meta/WhatsApp. Licensed under MIT.
