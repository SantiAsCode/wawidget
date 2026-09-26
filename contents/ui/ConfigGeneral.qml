import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.iconthemes as KIconThemes
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.components as PlasmaComponents3

KCM.SimpleKCM {
    property alias cfg_userAgent: userAgentField.text
    property string cfg_icon: plasmoid.configuration.icon

    Kirigami.FormLayout {
        RowLayout {
            Kirigami.FormData.label: i18n("Icono:")

            QQC2.Button {
                icon.name: cfg_icon || "internet-telephony"
                text: i18n("Cambiar icono…")

                onClicked: iconDialog.open()

                KIconThemes.IconDialog {
                    id: iconDialog
                    onIconNameChanged: cfg_icon = iconName || ""
                }
            }

            QQC2.Button {
                icon.name: "edit-clear"
                text: i18n("Restaurar")
                enabled: cfg_icon.length > 0
                onClicked: cfg_icon = ""
            }
        }

        QQC2.Label {
            Kirigami.FormData.isSection: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 32
            wrapMode: Text.WordWrap
            text: i18n("WhatsApp Web exige un User-Agent de Chrome reciente; si aparece un aviso de navegador no compatible, actualiza este valor.")
        }

        PlasmaComponents3.TextField {
            id: userAgentField
            Kirigami.FormData.label: i18n("User-Agent:")
            Layout.fillWidth: true
            text: cfg_userAgent
        }
    }
}
