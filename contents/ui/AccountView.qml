import QtQuick
import QtQuick.Window
import QtQuick.Dialogs as Dialogs
import QtWebEngine
import "ChatStyle.js" as ChatStyle

Item {
    id: account
    required property string storageName
    required property string userAgent
    required property bool keepActive
    required property bool selected
    required property bool narrowChats
    required property bool compactChats
    required property bool collapsed
    property alias view: webView
    property int activeDownloads: 0
    property var pendingFileRequest: null
    readonly property bool attachmentDialogOpen: pendingFileRequest !== null
    signal downloadStarted(var download)
    signal downloadEnded(var download)

    function finishFileSelection(files) {
        var request = pendingFileRequest;
        if (!request)
            return;
        if (files.length)
            // Qt 6.8's string-list API does not percent-decode file URLs.
            // Pass local paths so spaces, accents and literal '%' survive.
            request.dialogAccept(files.map(file => decodeURIComponent(file.toString().replace(/^file:\/\//, ""))));
        else
            request.dialogReject();
        pendingFileRequest = null;
    }

    Dialogs.FileDialog {
        id: attachmentDialog
        objectName: "attachmentFileDialog"
        parentWindow: account.Window.window
        title: qsTr("Seleccionar archivos para adjuntar")
        onAccepted: account.finishFileSelection(selectedFiles)
        onRejected: account.finishFileSelection([])
    }

    function applyStyle() {
        webView.runJavaScript(ChatStyle.script(narrowChats, compactChats, collapsed), WebEngineScript.ApplicationWorld);
    }
    onNarrowChatsChanged: applyStyle()
    onCompactChatsChanged: applyStyle()
    onCollapsedChanged: applyStyle()
    onUserAgentChanged: webView.reload()

    WebEngineProfile {
        id: waProfile
        storageName: account.storageName
        offTheRecord: storageName.length === 0
        persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
        httpUserAgent: account.userAgent
        onDownloadRequested: download => {
            account.activeDownloads++;
            account.downloadStarted(download);
            download.accept();
        }
        onDownloadFinished: download => {
            account.downloadEnded(download);
            account.activeDownloads = Math.max(0, account.activeDownloads - 1);
        }
    }

    WebEngineView {
        id: webView
        anchors.fill: parent
        url: "https://web.whatsapp.com"
        profile: waProfile
        // Frozen views retain their session and chat, but stop most background work.
        lifecycleState: account.keepActive || account.selected || account.activeDownloads > 0 || account.attachmentDialogOpen
                        ? WebEngineView.LifecycleState.Active : WebEngineView.LifecycleState.Frozen
        onLoadingChanged: info => {
            if (info.status === WebEngineView.LoadSucceededStatus)
                account.applyStyle();
        }
        onPermissionRequested: request => request.grant()
        onFileDialogRequested: request => {
            // Own the dialog explicitly: the persistent view can move between
            // the applet and its popup, so resolve the current window on opening.
            if (request.mode !== FileDialogRequest.FileModeOpen && request.mode !== FileDialogRequest.FileModeOpenMultiple)
                return;
            request.accepted = true;
            if (account.pendingFileRequest) {
                request.dialogReject();
                return;
            }
            attachmentDialog.fileMode = request.mode === FileDialogRequest.FileModeOpenMultiple
                                        ? Dialogs.FileDialog.OpenFiles : Dialogs.FileDialog.OpenFile;
            // Leave all file types available; WhatsApp validates its input's types.
            attachmentDialog.currentFiles = [];
            account.pendingFileRequest = request;
            attachmentDialog.open();
        }
        // Leave the native context menu enabled: copy/paste, links and media actions.
        onNewWindowRequested: request => {
            var url = request.requestedUrl.toString();
            // blob: URLs belong to this profile; an external browser cannot read them.
            if (/^https?:\/\//i.test(url) || /^mailto:/i.test(url))
                Qt.openUrlExternally(request.requestedUrl);
            else if (url === "" || url === "about:blank" || url.indexOf("blob:https://web.whatsapp.com/") === 0)
                downloadWindow.acceptAsNewWindow(request);
        }
    }

    // Some attachment flows create a popup before triggering the download. Keep it
    // in the originating profile instead of handing an unreadable blob to a browser.
    WebEngineView {
        id: downloadWindow
        visible: false
        profile: waProfile
    }
}
