# WAWidget — KDE Store description (EN)

**Product name:** WAWidget
**Category:** Linux/Unix Desktops → Desktop Extensions → KDE Plasma Extensions → Plasma 6 Extensions → Plasma 6 Applets
**License:** MIT
**Homepage:** https://github.com/SantiAsCode/wawidget

## Short description

Unofficial WhatsApp Web widget for KDE Plasma 6: floating desktop widget or panel applet, persistent session and one account per instance.

## Long description

WAWidget shows WhatsApp Web inside KDE Plasma using Qt WebEngine. It can be placed as a floating desktop widget or as a panel applet with a popup.

Features:

- Scan the QR code once: the session is stored and survives shell restarts and updates.
- Multi-account: every widget instance uses an isolated profile (Cookies, IndexedDB, Local Storage), so you can link a different account in each one.
- Editable User-Agent from the settings; by default it sends a recent Chrome user agent to avoid WhatsApp Web's "unsupported browser" notice.
- Per-instance icon, configurable with KDE's icon chooser.
- External links open in your default browser and downloads go to the system downloads folder.
- Minimal UI: no address bar or tabs, just WhatsApp Web.

Disclaimer: this widget is an unofficial project and is not affiliated with or endorsed by Meta/WhatsApp. "WhatsApp" is a trademark of Meta Platforms, Inc.

Requirements: KDE Plasma 6 and Qt 6 WebEngine (`qt6-webengine`, `qml6-module-qtwebengine`).

Limitations: no background notifications (the page unloads when the panel popup closes) and voice/video calls may not work depending on the Qt WebEngine version.
