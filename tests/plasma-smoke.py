#!/usr/bin/env python3
"""Run an isolated Plasma window: no real accounts, configuration or downloads.

Requires a graphical session and plasmawindowed. The temporary QML instrumentation
is never installed. Exercises profiles, view lifetime, suspension and blob downloads.
"""
import json
import os
import re
from pathlib import Path
import shutil
import subprocess
import tempfile
import ctypes

ROOT = Path(__file__).resolve().parents[1]
TOOLBAR_HARNESS = r'''
        property int toolbarTestStep: 0
        property real originalHostY: 0
        property real originalHostHeight: 0
        Timer {
            interval: 1100
            running: true
            repeat: true
            onTriggered: {
                switch (popup.toolbarTestStep++) {
                case 0:
                    root.checkTest(Plasmoid.configuration.autoHideToolbar, "toolbar auto-hide enabled by default");
                    // Deterministic state tests: do not move the user's real cursor.
                    toolbarHover.enabled = false;
                    popup.updateToolbar();
                    break;
                case 1:
                    root.checkTest(!toolbar.visible, "toolbar hides after the grace period");
                    root.checkTest(host.y === 0, "hidden toolbar leaves no empty space above web content");
                    popup.originalHostY = host.y;
                    popup.originalHostHeight = host.height;
                    Plasmoid.configuration.autoHideToolbar = false;
                    break;
                case 2:
                    root.checkTest(toolbar.visible && toolbar.enabled && host.y >= toolbar.height, "always-visible toolbar reserves its own space");
                    Plasmoid.configuration.autoHideToolbar = true;
                    popup.nearToolbar = true;
                    break;
                case 3:
                    root.checkTest(toolbar.visible && toolbar.enabled && host.y >= toolbar.height, "nearby hover reserves space instead of covering web content");
                    root.checkTest(host.height < popup.originalHostHeight, "visible toolbar reduces web content height within the same popup");
                    console.log("WAWIDGET_CAPTURE_TOOLBAR");
                    accountMenu.open();
                    popup.nearToolbar = false;
                    break;
                case 4:
                    root.checkTest(toolbar.visible && accountMenu.visible, "open menu prevents auto-hide");
                    accountMenu.close();
                    accountDialog.open();
                    break;
                case 5:
                    root.checkTest(toolbar.visible && accountDialog.visible, "open dialog prevents auto-hide");
                    accountDialog.close();
                    toolbarShortcut.activated();
                    break;
                case 6:
                    root.checkTest(toolbar.visible && pinButton.activeFocus && popup.toolbarKeyboardFocus, "F6 reveals toolbar and protects keyboard navigation");
                    sessions.objectAt(0).view.forceActiveFocus(Qt.MouseFocusReason);
                    break;
                case 7:
                    root.checkTest(!toolbar.visible, "leaving toolbar restores auto-hide");
                    root.checkTest(host.y === popup.originalHostY && host.height === popup.originalHostHeight, "hiding restores full web content height");
                    Plasmoid.configuration.pinned = true;
                    popup.nearToolbar = true;
                    break;
                case 8:
                    root.checkTest(toolbar.visible, "pinned popup still reveals toolbar");
                    popup.nearToolbar = false;
                    break;
                case 9:
                    root.checkTest(!toolbar.visible && Plasmoid.configuration.pinned, "pinning does not disable toolbar auto-hide");
                    Plasmoid.configuration.pinned = false;
                    Plasmoid.configuration.autoHideToolbar = false;
                    smokeTimer.start();
                    stop();
                    break;
                }
            }
        }
'''
HARNESS = r'''
    property int testStep: 0
    property var firstTestView: null
    property string firstTestProfile: ""
    property Item savedTestHost: null
    function checkTest(condition, message) {
        if (!condition) {
            console.error("WAWIDGET_TEST_FAIL: " + message);
            Qt.quit();
            throw new Error(message);
        }
        console.log("WAWIDGET_TEST_OK: " + message);
    }
    Timer {
        id: smokeTimer
        interval: 1000
        running: false
        repeat: true
        onTriggered: {
            root.testStep++;
            if (root.testStep === 1) {
                root.checkTest(root.accounts.length === 1, "one initial account");
                root.firstTestProfile = root.accounts[0].storageName;
                root.checkTest(root.firstTestProfile === "wawidget-" + Plasmoid.id, "legacy profile retained");
                root.firstTestView = sessions.objectAt(0);
                root.checkTest(!root.firstTestView.view.profile.offTheRecord, "persistent profile");
                root.checkTest(Plasmoid.configuration.keepAccountsActive, "background active by default");
                // plasmawindowed overrides this property for its standalone window.
                // Restore the applet's panel binding to exercise pin/unpin policy.
                root.hideOnWindowDeactivate = Qt.binding(() => !Plasmoid.configuration.pinned && !root.attachmentDialogOpen);
                root.checkTest(!Plasmoid.configuration.pinned && root.hideOnWindowDeactivate, "popup closes on deactivation by default");
                Plasmoid.configuration.pinned = true;
                root.checkTest(!root.hideOnWindowDeactivate, "pin prevents closing on deactivation");
                root.addAccount("Trabajo");
            } else if (root.testStep === 2) {
                if (sessions.objectAt(1).view.loading || sessions.objectAt(1).view.loadProgress < 100) {
                    root.testStep--;
                    return;
                }
                root.checkTest(root.accounts.length === 2, "second account added");
                root.checkTest(root.firstTestView === sessions.objectAt(0), "adding preserves existing view");
                root.checkTest(sessions.objectAt(1).storageName !== root.firstTestProfile, "profiles isolated");
                root.renameAccount(0, "Personal");
                root.checkTest(root.firstTestView === sessions.objectAt(0), "renaming preserves existing view");
                var shown = sessions.objectAt(1);
                root.checkTest(shown.selected && shown.visible && shown.view.visible, "selected account is visible");
                shown.view.runJavaScript("document.body.innerText", function(text) { root.checkTest(text === "WAWidget isolated test", "test page rendered its document"); });
                console.log("WAWIDGET_CAPTURE");
                Plasmoid.configuration.pinned = false;
                root.checkTest(root.hideOnWindowDeactivate, "unpin restores closing on deactivation");
             } else if (root.testStep === 3) {
                 root.selectAccount(0);
                 root.savedTestHost = root.viewHost;
                 root.viewHost = null;
            } else if (root.testStep === 4) {
                root.checkTest(root.firstTestView === sessions.objectAt(0), "closing popup retains view");
                root.checkTest(root.firstTestView.view.lifecycleState === WebEngineView.LifecycleState.Active, "hidden account stays active");
                Plasmoid.configuration.keepAccountsActive = false;
            } else if (root.testStep === 5) {
                root.checkTest(root.firstTestView.view.lifecycleState === WebEngineView.LifecycleState.Frozen, "saving mode freezes hidden account");
                root.firstTestView.activeDownloads++;
            } else if (root.testStep === 6) {
                root.checkTest(root.firstTestView.view.lifecycleState === WebEngineView.LifecycleState.Active, "download prevents suspension");
                root.firstTestView.activeDownloads--;
                Plasmoid.configuration.keepAccountsActive = true;
                root.selectAccount(1);
                root.removeAccount(1);
            } else if (root.testStep === 7) {
                root.checkTest(root.accounts.length === 1 && root.accounts[0].storageName === root.firstTestProfile, "remove correct account");
                root.checkTest(root.firstTestView === sessions.objectAt(0), "removal preserves other view");
                root.firstTestView.view.runJavaScript("var a=document.createElement('a'); a.href=URL.createObjectURL(new Blob(['WAWidget smoke test'],{type:'text/plain'}));a.download='wawidget-test.txt';document.body.appendChild(a);a.click();");
            } else if (root.testStep >= 8 && root.downloads.length && root.downloads[0].done) {
                root.checkTest(root.downloads[0].success, "blob download completes");
                root.checkTest(root.downloads[0].request === null, "finished request released");
                var remainingView = root.firstTestView;
                smokeTimer.stop();
                remainingView.view.runJavaScript("document.body.innerHTML=" + JSON.stringify(LAYOUT_FIXTURE_JSON), function() {
                    Plasmoid.configuration.narrowChats = true;
                    remainingView.view.runJavaScript("JSON.stringify({width:document.getElementById('column').getBoundingClientRect().width,edge:document.getElementById('column').getBoundingClientRect().right,conversation:document.getElementById('conversation').getBoundingClientRect().left,staleColor:getComputedStyle(document.getElementById('paint-conversation')).borderLeftColor,actualBorder:getComputedStyle(document.getElementById('column')).borderRightWidth})", function(value) {
                        var layout = JSON.parse(value);
                        root.checkTest(layout.width === 270 && layout.edge === layout.conversation, "narrow outer column and separator stay aligned");
                        root.checkTest(layout.staleColor === "rgba(0, 0, 0, 0)" && layout.actualBorder === "1px", "independent background border is hidden and real column has a separator");
                        Plasmoid.configuration.narrowChats = false;
                        remainingView.view.runJavaScript("JSON.stringify({width:document.getElementById('column').getBoundingClientRect().width,color:getComputedStyle(document.getElementById('paint-conversation')).borderLeftColor})", function(value) {
                            var restored = JSON.parse(value);
                            root.checkTest(restored.width === 400, "disabling narrow mode restores original column width");
                            root.checkTest(restored.color === "rgb(100, 100, 100)", "disabling narrow mode restores original background border");
                            root.addAccount("Otra cuenta");
                            var otherView = sessions.objectAt(1);
                            var otherProfile = root.accounts[1].storageName;
                            root.removeAccount(0);
                            root.checkTest(root.accounts[0].storageName === otherProfile && sessions.objectAt(0) === otherView, "removing first account preserves remaining profile and view");
                             root.uploadTestView = otherView;
                             root.viewHost = root.savedTestHost;
                             uploadTimer.start();
                        });
                    });
                });
            } else if (root.testStep > 20) {
                root.checkTest(false, "download timed out");
            }
        }
    }
'''

UPLOAD_HARNESS = r'''
    property var uploadTestView: null
    property int uploadStep: 0
    property bool uploadCaptured: false
    Timer {
        id: uploadTimer
        interval: 700
        repeat: true
        onTriggered: {
            var account = root.uploadTestView;
            if (account.view.loading || account.view.loadProgress < 100)
                return;
            switch (root.uploadStep++) {
            case 0:
                account.view.runJavaScript("document.body.innerHTML='<input id=upload type=file>';window.uploadResult=null;document.getElementById('upload').onchange=async function(){window.uploadResult=await this.files[0].text();};document.getElementById('upload').focus();", function() {
                    account.view.forceActiveFocus(Qt.OtherFocusReason);
                    console.log("WAWIDGET_UPLOAD_KEY");
                });
                break;
            case 1:
                if (!root.uploadCaptured) {
                    root.uploadCaptured = true;
                    root.uploadStep--;
                    console.log("WAWIDGET_CAPTURE_ATTACHMENT");
                    return;
                }
                root.checkTest(account.attachmentDialogOpen && account.testPicker.visible, "real file input opens the attachment picker");
                root.checkTest(root.attachmentDialogOpen && !root.hideOnWindowDeactivate && !Plasmoid.configuration.pinned, "file picker holds popup open without changing pin preference");
                Plasmoid.configuration.keepAccountsActive = false;
                root.viewHost = null;
                root.checkTest(account.view.lifecycleState === WebEngineView.LifecycleState.Active, "file picker prevents hidden view suspension");
                root.viewHost = root.savedTestHost;
                root.checkTest(account.testPicker.fileMode === 0, "single-file input uses single selection");
                account.testPicker.currentFiles = [UPLOAD_FILE_ONE];
                // Simulate the chooser's completion, not its platform-specific UI.
                account.testPicker.accepted();
                account.testPicker.close();
                break;
            case 2:
                root.checkTest(!account.attachmentDialogOpen && root.hideOnWindowDeactivate, "accept releases request and restores popup policy");
                Plasmoid.configuration.keepAccountsActive = true;
                root.viewHost = root.savedTestHost;
                account.view.runJavaScript("window.uploadResult", function(result) {
                    root.checkTest(result === "WAWidget upload fixture", "selected file contents reach the web page");
                });
                break;
            case 3:
                account.view.runJavaScript("var input=document.getElementById('upload');input.value='';input.multiple=true;input.onchange=function(){window.uploadResult=Array.from(this.files).map(f=>f.name).join('|');};input.focus();", function() {
                    account.view.forceActiveFocus(Qt.OtherFocusReason);
                    console.log("WAWIDGET_UPLOAD_KEY");
                });
                break;
            case 4:
                root.checkTest(account.attachmentDialogOpen && account.testPicker.visible && account.testPicker.fileMode === 1, "multiple-file input opens multiple selection");
                account.testPicker.currentFiles = [UPLOAD_FILE_ONE, UPLOAD_FILE_TWO];
                account.testPicker.accepted();
                account.testPicker.close();
                break;
            case 5:
                account.view.runJavaScript("window.uploadResult", function(result) {
                    root.checkTest(result === "adjunto ñ %.txt|segundo.txt", "multiple file URLs preserve unicode and percent characters");
                });
                break;
            case 6:
                account.view.runJavaScript("var input=document.getElementById('upload');input.value='';input.focus();", function() {
                    account.view.forceActiveFocus(Qt.OtherFocusReason);
                    console.log("WAWIDGET_UPLOAD_KEY");
                });
                break;
            case 7:
                root.checkTest(account.attachmentDialogOpen && account.testPicker.visible, "picker reopens after accepting");
                account.testPicker.reject();
                break;
            case 8:
                root.checkTest(!account.attachmentDialogOpen && !root.attachmentDialogOpen && root.hideOnWindowDeactivate, "cancel releases request and restores popup policy");
                account.view.runJavaScript("document.getElementById('upload').files.length", function(count) {
                    root.checkTest(count === 0, "cancelling attaches no files");
                    console.log("WAWIDGET_TEST_PASS");
                });
                stop();
                break;
            }
        }
    }
'''


def press_upload_button():
    """Send Space only to the isolated X11 test window; never move global focus."""
    tree = subprocess.check_output(["xwininfo", "-root", "-tree"], text=True)
    window = re.search(r'(0x[0-9a-f]+) "WAWidget[^"\n]*"', tree)
    assert window, "Isolated test window not found"
    x11 = ctypes.CDLL("libX11.so.6")
    x11.XOpenDisplay.restype = ctypes.c_void_p
    display = x11.XOpenDisplay(None)
    assert display, "Attachment integration test requires X11"
    x11.XKeysymToKeycode.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
    x11.XSendEvent.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_int, ctypes.c_long, ctypes.c_void_p]
    x11.XFlush.argtypes = [ctypes.c_void_p]
    x11.XCloseDisplay.argtypes = [ctypes.c_void_p]

    class KeyEvent(ctypes.Structure):
        _fields_ = [("type", ctypes.c_int), ("serial", ctypes.c_ulong),
                    ("send_event", ctypes.c_int), ("display", ctypes.c_void_p),
                    ("window", ctypes.c_ulong), ("root", ctypes.c_ulong),
                    ("subwindow", ctypes.c_ulong), ("time", ctypes.c_ulong),
                    ("x", ctypes.c_int), ("y", ctypes.c_int),
                    ("x_root", ctypes.c_int), ("y_root", ctypes.c_int),
                    ("state", ctypes.c_uint), ("keycode", ctypes.c_uint),
                    ("same_screen", ctypes.c_int)]

    buffer = (ctypes.c_long * 24)()
    event = KeyEvent.from_buffer(buffer)
    event.display = display
    event.window = int(window[1], 16)
    event.keycode = x11.XKeysymToKeycode(display, 0x20)
    event.same_screen = 1
    for event_type, mask in [(2, 1), (3, 2)]:
        event.type = event_type
        x11.XSendEvent(display, event.window, 0, mask, ctypes.byref(buffer))
    x11.XFlush(display)
    x11.XCloseDisplay(display)


def main():
    with tempfile.TemporaryDirectory(prefix="wawidget-test-", dir="/tmp/opencode") as tmp:
        base = Path(tmp)
        package = base / "package"
        shutil.copytree(ROOT / "contents", package / "contents")
        shutil.copy(ROOT / "metadata.json", package / "metadata.json")
        main_qml = package / "contents/ui/main.qml"
        source = main_qml.read_text()
        source = source.replace("id: popup", "id: popup\n" + TOOLBAR_HARNESS, 1)
        harness = HARNESS.replace("LAYOUT_FIXTURE_JSON", json.dumps((ROOT / "tests/layout-fixture.html").read_text()))
        upload_one = base / "adjunto ñ %.txt"
        upload_two = base / "segundo.txt"
        upload_one.write_text("WAWidget upload fixture")
        upload_two.write_text("Second upload fixture")
        upload_harness = UPLOAD_HARNESS.replace("UPLOAD_FILE_ONE", json.dumps(upload_one.as_uri())).replace("UPLOAD_FILE_TWO", json.dumps(upload_two.as_uri()))
        main_qml.write_text(source[:source.rfind("}")] + harness + upload_harness + "}\n")
        account_qml = package / "contents/ui/AccountView.qml"
        source = account_qml.read_text().replace('url: "https://web.whatsapp.com"', 'url: "data:text/html,<html><body>WAWidget isolated test</body></html>"')
        target = base / "downloads"
        target.mkdir()
        source = source.replace("id: waProfile", "id: waProfile\n        downloadPath: " + json.dumps(str(target)))
        source = source.replace("id: account", "id: account\n    property alias testPicker: attachmentDialog", 1)
        # Deterministic picker automation: no portal service or user's folders.
        picker_options = "" if os.environ.get("WAWIDGET_NATIVE_PICKER") else '\n        options: Dialogs.FileDialog.DontUseNativeDialog'
        source = source.replace('objectName: "attachmentFileDialog"', 'objectName: "attachmentFileDialog"\n        currentFolder: ' + json.dumps(base.as_uri()) + picker_options)
        account_qml.write_text(source)
        # Only the isolated fixture bypasses the production WhatsApp-origin guard.
        style_js = package / "contents/ui/ChatStyle.js"
        style_js.write_text(style_js.read_text().replace('location.origin!=="https://web.whatsapp.com"||', ''))
        env = dict(os.environ, XDG_CONFIG_HOME=str(base / "config"), XDG_DATA_HOME=str(base / "data"), XDG_CACHE_HOME=str(base / "cache"))
        (base / "config").mkdir()
        (base / "config/kdeglobals").write_text("[Icons]\nTheme=breeze\n[General]\nColorScheme=BreezeLight\n")
        import threading
        process = subprocess.Popen(["plasmawindowed", str(package)], env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        watchdog = threading.Timer(45, process.kill)
        watchdog.start()
        lines = []
        try:
            for line in process.stdout:
                lines.append(line)
                if "WAWIDGET_UPLOAD_KEY" in line:
                    press_upload_button()
                if "WAWIDGET_CAPTURE" in line and shutil.which("xwininfo") and shutil.which("import"):
                    tree = subprocess.check_output(["xwininfo", "-root", "-tree"], text=True)
                    window = re.search(r'(0x[0-9a-f]+) "WAWidget[^"\n]*"', tree)
                    if "WAWIDGET_CAPTURE_ATTACHMENT" in line:
                        window = re.search(r'(0x[0-9a-f]+) "Seleccionar archivos para adjuntar[^"\n]*"', tree) or window
                    if window:
                        capture = "wawidget-attachment.png" if "WAWIDGET_CAPTURE_ATTACHMENT" in line else "wawidget-toolbar-visible.png" if "WAWIDGET_CAPTURE_TOOLBAR" in line else "wawidget-window.png"
                        subprocess.run(["import", "-window", window[1], "/tmp/opencode/" + capture], check=True)
                if "WAWIDGET_TEST_PASS" in line or "WAWIDGET_TEST_FAIL" in line:
                    break
        finally:
            process.terminate()
            try:
                remaining, _ = process.communicate(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                remaining, _ = process.communicate()
            watchdog.cancel()
        output = "".join(lines) + remaining
        print(output)
        assert "WAWIDGET_TEST_PASS" in output and "WAWIDGET_TEST_FAIL" not in output, "Plasma smoke test failed"
        assert (target / "wawidget-test.txt").read_text() == "WAWidget smoke test", "Downloaded artifact mismatch"
        assert not any(text in output for text in ["Unable to assign", "Binding loop", "Cannot stack", "ReferenceError", "TypeError", "SyntaxError"]), "QML runtime errors"
        print("PASS: isolated Plasma integration and downloaded artifact verified")


if __name__ == "__main__":
    main()
