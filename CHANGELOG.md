# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

## [1.1.5] - 2026-10-26

### Corregido

- La barra autoocultable ahora reserva espacio mientras está visible, en lugar de superponerse a los controles superiores de WhatsApp. Al ocultarse, el contenido recupera toda la altura.
- El espacio se mantiene durante el desvanecimiento para evitar solapamientos durante la transición.
- Pruebas de regresión de la separación entre barra y contenido y la recuperación del espacio al ocultarla.

## [1.1.4] - 2026-10-21

### Añadido

- Barra superior autoocultable por defecto: aparece al acercar el cursor al borde superior y se oculta tras 800 ms al alejarlo, sin desplazar WhatsApp.
- Opción persistente en el menú y la configuración para dejar la barra siempre visible. Es independiente de la chincheta.
- La barra permanece visible al usar menús, diálogos o navegación de teclado; F6 permite mostrarla y enfocar la chincheta.
- Pruebas de ocultación, superposición sin cambios de geometría, menús, diálogos, teclado y compatibilidad con el pineo.

## [1.1.3] - 2026-10-21

### Corregido

- Separador gris que permanecía superpuesto en el centro al estrechar los chats: WhatsApp lo dibuja también en una capa de fondo independiente. Se vuelve transparente solo el borde decorativo desalineado y se mantiene un separador en el límite real de la columna.
- Prueba de regresión con esa capa de fondo independiente, incluida la restauración del borde al desactivar la vista angosta.

## [1.1.2] - 2026-10-21

### Corregido

- La columna angosta ahora identifica la columna flex completa y redistribuye el espacio al panel contiguo, en lugar de achicar solo el contenedor interno y dejar el separador atrás.
- Detección de columnas después de montajes dinámicos de WhatsApp, sin depender de clases ofuscadas; limpieza de los ajustes al desactivarlos.
- Prueba de regresión en Qt WebEngine con contenedores anidados y verificación de la alineación del separador y restauración del ancho.

## [1.1.1] - 2026-10-21

### Añadido

- Chincheta en la barra superior y ajuste persistente para mantener abierto el popup al cambiar de aplicación o tomar capturas, usando `hideOnWindowDeactivate` de Plasma.

## [1.1.0] - 2026-10-21

### Añadido

- Pestañas para añadir, renombrar y quitar cuentas con perfiles independientes.
- Migración conservando el nombre del perfil de la sesión existente.
- Cuentas activas en segundo plano por defecto; suspensión configurable sin interrumpir descargas.
- Ajustes independientes de columna angosta, listado compacto y plegado de chats.
- Lista de descargas con progreso, cancelación, errores y acceso a la carpeta de destino.
- Prueba de integración aislada en Plasma, incluida la verificación de un archivo descargado.

### Corregido

- Menú contextual de WebEngine restaurado para copiar texto, enlaces e imágenes.
- Ventanas de descarga `blob:` retenidas en el perfil de origen en lugar de enviarlas al navegador externo.

## [1.0.0] - 2026-09-26

### Añadido

- Widget de escritorio flotante y applet de panel (icono + popup) para WhatsApp Web.
- Sesión persistente con perfil WebEngine propio por instancia (multi-cuenta).
- User-Agent configurable (por defecto, un Chrome reciente).
- Icono configurable por instancia mediante el diálogo de iconos de KDE.
- Permisos (notificaciones, micrófono, cámara) aceptados automáticamente.
- Descargas redirigidas a la carpeta de descargas del sistema.
- Apertura de enlaces externos en el navegador predeterminado.
