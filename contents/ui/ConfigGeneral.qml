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
    property alias cfg_keepAccountsActive: keepAccountsActive.checked
    property alias cfg_narrowChats: narrowChats.checked
    property alias cfg_compactChats: compactChats.checked
    property alias cfg_allowCollapse: allowCollapse.checked
    property alias cfg_pinned: pinned.checked
    property alias cfg_autoHideToolbar: autoHideToolbar.checked

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: autoHideToolbar
            text: i18n("Ocultar automáticamente la barra superior")
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 32
            wrapMode: Text.WordWrap
            text: i18n("Aparece al acercar el cursor al borde superior y hace espacio sin tapar WhatsApp. Al ocultarse, el contenido recupera toda la altura. Se mantiene visible mientras usás sus menús o diálogos. F6 permite mostrarla con el teclado.")
        }
        QQC2.CheckBox {
            id: pinned
            text: i18n("Fijar ventana: mantener abierta al cambiar de aplicación")
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 32
            wrapMode: Text.WordWrap
            text: i18n("Evita que el popup del panel se cierre al perder el foco, por ejemplo al sacar una captura. También se puede cambiar con la chincheta de la barra superior. No lo convierte en una ventana siempre por encima de las demás.")
        }
        QQC2.CheckBox {
            id: keepAccountsActive
            text: i18n("Mantener todas las cuentas activas en segundo plano")
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 32
            wrapMode: Text.WordWrap
            text: i18n("Activado por defecto. Consume más memoria. Al desactivarlo, las cuentas no visibles se suspenden; pueden dejar de recibir mensajes hasta volver a abrirlas. Las descargas en curso no se suspenden.")
        }
        QQC2.CheckBox {
            id: narrowChats
            text: i18n("Columna de chats más angosta")
        }
        QQC2.CheckBox {
            id: compactChats
            text: i18n("Filas de chats más compactas")
        }
        QQC2.CheckBox {
            id: allowCollapse
            text: i18n("Mostrar botón para plegar/desplegar los chats")
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 32
            wrapMode: Text.WordWrap
            text: i18n("Los ajustes visuales son independientes y reversibles. Su compatibilidad depende de la versión de WhatsApp Web. Plegar solo se aplica cuando hay una conversación abierta.")
        }
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
