import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import QtQml.Models
import QtCore
import QtWebEngine
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root
    Plasmoid.icon: Plasmoid.configuration.icon || "internet-telephony"
    hideOnWindowDeactivate: !Plasmoid.configuration.pinned
    switchWidth: Kirigami.Units.gridUnit * 16
    switchHeight: Kirigami.Units.gridUnit * 23

    property var accounts: []
    property int currentAccount: Math.max(0, Math.min(Plasmoid.configuration.activeAccount, accounts.length - 1))
    property Item viewHost: null
    property var downloads: []
    property bool downloadsVisible: false
    ListModel { id: sessionModel }

    function saveAccounts() {
        Plasmoid.configuration.accounts = JSON.stringify(accounts);
    }
    function selectAccount(index) {
        Plasmoid.configuration.activeAccount = index;
    }
    function addAccount(name) {
        var list = accounts.slice();
        list.push({name: name, storageName: "wawidget-" + Plasmoid.id + "-" + Date.now() + "-" + Math.random().toString(36).slice(2)});
        accounts = list;
        sessionModel.append({profileName: list[list.length - 1].storageName});
        saveAccounts();
        selectAccount(list.length - 1);
    }
    function renameAccount(index, name) {
        var list = accounts.slice();
        list[index] = {name: name, storageName: list[index].storageName};
        accounts = list;
        saveAccounts();
    }
    function removeAccount(index) {
        if (accounts.length < 2 || downloads.some(d => !d.done))
            return;
        var list = accounts.slice();
        list.splice(index, 1);
        sessionModel.remove(index);
        selectAccount(0);
        accounts = list;
        saveAccounts();
    }
    function finishDownload(download) {
        var list = downloads.slice();
        for (var i = 0; i < list.length; ++i) {
            if (list[i].request === download) {
                list[i] = {
                    request: null,
                    name: download.downloadFileName,
                    directory: download.downloadDirectory,
                    done: true,
                    success: download.state === WebEngineDownloadRequest.DownloadCompleted,
                    error: download.state === WebEngineDownloadRequest.DownloadCancelled ? i18n("Cancelada") : download.interruptReasonString,
                    received: download.receivedBytes,
                    total: download.totalBytes
                };
            }
        }
        downloads = list;
    }
    function localUrl(path) {
        return "file://" + path.split("/").map(part => encodeURIComponent(part)).join("/");
    }

    Component.onCompleted: {
        try {
            var parsed = JSON.parse(Plasmoid.configuration.accounts);
            if (Array.isArray(parsed))
                accounts = parsed.filter(a => a && typeof a.name === "string" && /^wawidget-[\w-]+$/.test(a.storageName));
        } catch (error) {
            console.warn("WAWidget: configuración de cuentas inválida", error);
        }
        if (!accounts.length) {
            // Reuse exactly the original profile; never move or copy a live Chromium profile.
            accounts = [{name: i18n("Principal"), storageName: "wawidget-" + Plasmoid.id}];
            saveAccounts();
        }
        for (var i = 0; i < accounts.length; ++i)
            sessionModel.append({profileName: accounts[i].storageName});
    }

    // The root owns the views, not the popup. Closing it must not destroy sessions/downloads.
    Instantiator {
        id: sessions
        model: sessionModel
        delegate: AccountView {
            required property int index
            required property string profileName
            parent: root.viewHost || root
            anchors.fill: parent
            storageName: profileName
            userAgent: Plasmoid.configuration.userAgent
            keepActive: Plasmoid.configuration.keepAccountsActive
            selected: index === root.currentAccount && !!root.viewHost && root.viewHost.visible
            visible: selected
            narrowChats: Plasmoid.configuration.narrowChats
            compactChats: Plasmoid.configuration.compactChats
            collapsed: Plasmoid.configuration.allowCollapse && Plasmoid.configuration.chatsCollapsed
            onDownloadStarted: download => {
                root.downloads = [{request: download, name: download.downloadFileName,
                    directory: download.downloadDirectory, done: false, success: false,
                    error: "", received: 0, total: download.totalBytes}].concat(root.downloads);
                root.downloadsVisible = true;
            }
            onDownloadEnded: download => root.finishDownload(download)
        }
    }

    Timer {
        interval: 500
        running: root.downloads.some(d => !d.done)
        repeat: true
        onTriggered: {
            root.downloads = root.downloads.map(d => {
                if (d.request) {
                    d.received = d.request.receivedBytes;
                    d.total = d.request.totalBytes;
                }
                return d;
            });
        }
    }

    fullRepresentation: ColumnLayout {
        id: popup
        spacing: toolbar.visible ? Kirigami.Units.smallSpacing : 0
        clip: true
        property bool toolbarRevealed: true
        property bool nearToolbar: toolbarHover.hovered && toolbarHover.point.position.y <= toolbar.implicitHeight + Kirigami.Units.gridUnit
        property bool toolbarKeyboardFocus: {
            var focused = popup.Window.window ? popup.Window.window.activeFocusItem : null;
            if (!focused || (focused.focusReason !== Qt.TabFocusReason
                    && focused.focusReason !== Qt.BacktabFocusReason
                    && focused.focusReason !== Qt.ShortcutFocusReason))
                return false;
            for (var item = focused; item; item = item.parent) {
                if (item === toolbar)
                    return true;
            }
            return false;
        }
        property bool toolbarEngaged: nearToolbar || toolbarKeyboardFocus || accountMenu.visible || accountDialog.visible || removeDialog.visible
        function updateToolbar() {
            if (toolbarEngaged || !Plasmoid.configuration.autoHideToolbar) {
                toolbarRevealed = true;
                hideToolbarTimer.stop();
            } else if (visible) {
                hideToolbarTimer.restart();
            }
        }
        onToolbarEngagedChanged: updateToolbar()
        onVisibleChanged: {
            if (visible) {
                toolbarRevealed = true;
                updateToolbar();
            } else {
                hideToolbarTimer.stop();
            }
        }
        Component.onCompleted: updateToolbar()
        HoverHandler {
            id: toolbarHover
            target: null
            // Passive observation: do not intercept clicks, scrolling or text selection.
        }
        Timer {
            id: hideToolbarTimer
            interval: 800
            onTriggered: {
                if (Plasmoid.configuration.autoHideToolbar && !popup.toolbarEngaged)
                    popup.toolbarRevealed = false;
            }
        }
        Connections {
            target: Plasmoid.configuration
            function onAutoHideToolbarChanged() { popup.updateToolbar(); }
        }
        Shortcut {
            id: toolbarShortcut
            sequence: "F6"
            enabled: popup.visible
            onActivated: {
                popup.toolbarRevealed = true;
                pinButton.forceActiveFocus(Qt.ShortcutFocusReason);
            }
        }
        Layout.minimumWidth: Kirigami.Units.gridUnit * 24
        Layout.minimumHeight: Kirigami.Units.gridUnit * 16
        Layout.preferredWidth: Kirigami.Units.gridUnit * 50
        Layout.preferredHeight: Kirigami.Units.gridUnit * 32

        Item {
            Layout.fillWidth: true
            // Keep space until the fade finishes: the toolbar must never cover WebEngine.
            Layout.minimumHeight: toolbar.visible ? toolbar.implicitHeight : 0
            Layout.maximumHeight: Layout.minimumHeight
            Layout.preferredHeight: Layout.minimumHeight
            clip: true
            z: 10
            QQC2.ToolBar {
                id: toolbar
                objectName: "accountToolbar"
                width: parent.width
                visible: opacity > 0
                enabled: !Plasmoid.configuration.autoHideToolbar || popup.toolbarRevealed
                opacity: enabled ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: Kirigami.Units.shortDuration }
                }
                contentItem: RowLayout {
                    QQC2.ScrollView {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.preferredHeight: tabs.implicitHeight
                        clip: true
                        contentWidth: tabs.implicitWidth
                        QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AlwaysOff
                        RowLayout {
                            id: tabs
                            Repeater {
                                model: root.accounts
                                QQC2.Button {
                                    required property int index
                                    required property var modelData
                                    text: modelData.name
                                    checkable: true
                                    checked: index === root.currentAccount
                                    onClicked: root.selectAccount(index)
                                    Accessible.name: i18n("Cuenta: %1", modelData.name)
                                }
                            }
                        }
                    }
                    QQC2.ToolButton {
                        id: pinButton
                        objectName: "pinButton"
                        icon.name: "window-pin"
                        text: checked ? i18n("Desfijar ventana") : i18n("Fijar ventana")
                        Accessible.name: text
                        display: QQC2.AbstractButton.IconOnly
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: checked
                            ? i18n("Ventana fijada: permanece abierta al cambiar de aplicación")
                            : i18n("Fijar ventana para que no se cierre al cambiar de aplicación")
                        checkable: true
                        checked: Plasmoid.configuration.pinned
                        onClicked: Plasmoid.configuration.pinned = checked
                    }
                    QQC2.ToolButton {
                        icon.name: "list-add"
                        text: i18n("Añadir cuenta")
                        display: QQC2.AbstractButton.IconOnly
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: text
                        onClicked: { accountDialog.editing = false; accountName.text = ""; accountDialog.open(); }
                    }
                    QQC2.ToolButton {
                        icon.name: "application-menu"
                        text: i18n("Opciones de cuenta")
                        display: QQC2.AbstractButton.IconOnly
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: text
                        onClicked: accountMenu.popup()
                        QQC2.Menu {
                            id: accountMenu
                            QQC2.MenuItem {
                                text: i18n("Renombrar cuenta…")
                                onTriggered: {
                                    accountDialog.editing = true;
                                    accountName.text = root.accounts[root.currentAccount].name;
                                    accountDialog.open();
                                }
                            }
                            QQC2.MenuItem {
                                text: i18n("Quitar cuenta…")
                                enabled: root.accounts.length > 1 && !root.downloads.some(d => !d.done)
                                onTriggered: removeDialog.open()
                            }
                            QQC2.MenuSeparator {}
                            QQC2.MenuItem {
                                objectName: "autoHideToolbarAction"
                                text: i18n("Ocultar barra automáticamente")
                                checkable: true
                                checked: Plasmoid.configuration.autoHideToolbar
                                onTriggered: Plasmoid.configuration.autoHideToolbar = checked
                            }
                            QQC2.MenuItem {
                                text: i18n("Mantener cuentas activas")
                                checkable: true
                                checked: Plasmoid.configuration.keepAccountsActive
                                onTriggered: Plasmoid.configuration.keepAccountsActive = checked
                            }
                            QQC2.MenuItem {
                                text: i18n("Columna de chats angosta")
                                checkable: true
                                checked: Plasmoid.configuration.narrowChats
                                onTriggered: Plasmoid.configuration.narrowChats = checked
                            }
                            QQC2.MenuItem {
                                text: i18n("Filas de chats compactas")
                                checkable: true
                                checked: Plasmoid.configuration.compactChats
                                onTriggered: Plasmoid.configuration.compactChats = checked
                            }
                            QQC2.MenuItem {
                                text: i18n("Permitir plegar los chats")
                                checkable: true
                                checked: Plasmoid.configuration.allowCollapse
                                onTriggered: Plasmoid.configuration.allowCollapse = checked
                            }
                        }
                    }
                    QQC2.ToolButton {
                        visible: Plasmoid.configuration.allowCollapse
                        icon.name: "view-split-left-right"
                        text: Plasmoid.configuration.chatsCollapsed ? i18n("Mostrar chats") : i18n("Ocultar chats")
                        display: QQC2.AbstractButton.IconOnly
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: text
                        checkable: true
                        checked: Plasmoid.configuration.chatsCollapsed
                        onClicked: Plasmoid.configuration.chatsCollapsed = checked
                    }
                    QQC2.ToolButton {
                        icon.name: "download"
                        text: i18n("Descargas (%1)", root.downloads.length)
                        display: QQC2.AbstractButton.IconOnly
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: text
                        checkable: true
                        checked: root.downloadsVisible
                        onClicked: root.downloadsVisible = checked
                    }
                }
            }
        }

        Item {
            id: host
            Layout.fillWidth: true
            Layout.fillHeight: true
            Component.onCompleted: root.viewHost = host
            Component.onDestruction: root.viewHost = null
        }

        QQC2.ScrollView {
            visible: root.downloadsVisible
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(downloadList.implicitHeight, Kirigami.Units.gridUnit * 8)
            clip: true
            ColumnLayout {
                id: downloadList
                width: popup.width
                QQC2.Label {
                    visible: root.downloads.length === 0
                    text: i18n("Todavía no hay descargas en esta sesión.")
                }
                Repeater {
                    model: root.downloads
                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true
                            QQC2.Label {
                                Layout.fillWidth: true
                                elide: Text.ElideMiddle
                                text: modelData.name + " — " + (modelData.done
                                    ? (modelData.success ? i18n("Completada") : i18n("No se descargó: %1", modelData.error))
                                    : (modelData.total > 0 ? Math.floor(modelData.received * 100 / modelData.total) + "%" : i18n("Descargando…")))
                            }
                            QQC2.ProgressBar {
                                visible: !modelData.done
                                Layout.fillWidth: true
                                indeterminate: modelData.total <= 0
                                value: modelData.total > 0 ? modelData.received / modelData.total : 0
                            }
                            QQC2.Label {
                                Layout.fillWidth: true
                                text: modelData.directory
                                elide: Text.ElideMiddle
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                            }
                        }
                        QQC2.Button {
                            visible: !modelData.done
                            text: i18n("Cancelar")
                            onClicked: { if (modelData.request) modelData.request.cancel(); }
                        }
                        QQC2.Button {
                            visible: modelData.success
                            text: i18n("Abrir carpeta")
                            onClicked: Qt.openUrlExternally(root.localUrl(modelData.directory))
                        }
                    }
                }
            }
        }

        QQC2.Dialog {
            id: accountDialog
            property bool editing: false
            title: editing ? i18n("Renombrar cuenta") : i18n("Añadir cuenta")
            width: Math.min(popup.width - Kirigami.Units.largeSpacing * 2, Kirigami.Units.gridUnit * 22)
            anchors.centerIn: parent
            modal: true
            standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel
            onOpened: { accountName.forceActiveFocus(); accountName.selectAll(); standardButton(QQC2.Dialog.Ok).enabled = accountName.text.trim().length > 0; }
            onAccepted: {
                if (editing) {
                    root.renameAccount(root.currentAccount, accountName.text.trim());
                } else {
                    root.addAccount(accountName.text.trim());
                }
            }
            QQC2.TextField {
                id: accountName
                placeholderText: i18n("Nombre de la cuenta")
                maximumLength: 40
                Accessible.name: placeholderText
                onTextChanged: {
                    if (accountDialog.visible)
                        accountDialog.standardButton(QQC2.Dialog.Ok).enabled = text.trim().length > 0;
                }
                onAccepted: { if (text.trim().length) accountDialog.accept(); }
            }
        }
        QQC2.Dialog {
            id: removeDialog
            anchors.centerIn: parent
            title: i18n("Quitar cuenta")
            width: Math.min(popup.width - Kirigami.Units.largeSpacing * 2, Kirigami.Units.gridUnit * 24)
            modal: true
            standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel
            QQC2.Label {
                width: Kirigami.Units.gridUnit * 20
                wrapMode: Text.WordWrap
                text: i18n("Se quitará esta pestaña. No se cerrará la sesión de WhatsApp ni se borrarán sus datos locales. Para desvincularla, usá Dispositivos vinculados en tu teléfono.")
            }
            onAccepted: {
                root.removeAccount(root.currentAccount);
            }
        }
    }
}
