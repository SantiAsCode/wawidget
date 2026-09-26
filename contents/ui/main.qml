import QtQuick
import QtQuick.Layouts
import QtWebEngine
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    Plasmoid.icon: Plasmoid.configuration.icon || "internet-telephony"

    switchWidth: Kirigami.Units.gridUnit * 16
    switchHeight: Kirigami.Units.gridUnit * 23

    WebEngineProfile {
        id: waProfile
        storageName: "wawidget-" + Plasmoid.id
        offTheRecord: storageName.length === 0
        persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
        httpUserAgent: Plasmoid.configuration.userAgent

        onDownloadRequested: download => download.accept()
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: Kirigami.Units.gridUnit * 12
        Layout.preferredWidth: Kirigami.Units.gridUnit * 45
        Layout.preferredHeight: Kirigami.Units.gridUnit * 28

        WebEngineView {
            id: webView
            anchors.fill: parent
            url: "https://web.whatsapp.com"
            profile: waProfile

            onPermissionRequested: request => request.accept()
            onNewWindowRequested: request => Qt.openUrlExternally(request.requestedUrl)
            onContextMenuRequested: request => request.accepted = true
        }

        Connections {
            target: Plasmoid.configuration

            function onUserAgentChanged() {
                webView.reload();
            }
        }
    }
}
