import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.core as PlasmaCore

KCM.SimpleKCM {
    id: root

    property int cfg_desktopWidgetBg
    property alias cfg_hideWhenIdle: hideWhenIdle.checked
    property alias cfg_idleTimer: idleTimer.value
    property alias cfg_hideToolTip: hideToolTip.checked
    property alias cfg_disableLeftClick: disableLeftClick.checked
    property alias cfg_debugMode: debugMode.checked
    property alias cfg_pauseOnFullScreenWindow: pauseFullScreen.checked
    property alias cfg_pauseOnMaximizedWindow: pauseMaximized.checked
    property alias cfg_fillPanel: fillPanel.checked
    property alias cfg_expanding: expanding.checked
    property alias cfg_length: length.value
    property alias cfg_minimumLength: minimumLength.value

    Kirigami.FormLayout {
        id: form

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("On the desktop")
        }

        ButtonGroup {
            id: bgGroup
        }

        RadioButton {
            Kirigami.FormData.label: i18n("Background:")
            text: i18n("None")
            ButtonGroup.group: bgGroup
            checked: root.cfg_desktopWidgetBg === PlasmaCore.Types.NoBackground
            onToggled: if (checked)
                root.cfg_desktopWidgetBg = PlasmaCore.Types.NoBackground
        }

        RadioButton {
            text: i18n("Standard")
            ButtonGroup.group: bgGroup
            checked: root.cfg_desktopWidgetBg === PlasmaCore.Types.StandardBackground
            onToggled: if (checked)
                root.cfg_desktopWidgetBg = PlasmaCore.Types.StandardBackground
        }

        RadioButton {
            text: i18n("Shadow only")
            ButtonGroup.group: bgGroup
            checked: root.cfg_desktopWidgetBg === PlasmaCore.Types.ShadowBackground
            onToggled: if (checked)
                root.cfg_desktopWidgetBg = PlasmaCore.Types.ShadowBackground
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("In a panel")
        }

        CheckBox {
            id: fillPanel
            Kirigami.FormData.label: i18n("Size:")
            text: i18n("Fill available panel space")
        }

        CheckBox {
            id: expanding
            text: i18n("Expand to fill the widget area")
        }

        SpinBox {
            id: length
            Kirigami.FormData.label: i18n("Length (px):")
            enabled: !expanding.checked
            from: 8
            to: 1024
            stepSize: 4
        }

        SpinBox {
            id: minimumLength
            Kirigami.FormData.label: i18n("Minimum length (px):")
            enabled: expanding.checked
            from: 8
            to: 1024
            stepSize: 4
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Behaviour")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Auto-hide when idle:")
            CheckBox {
                id: hideWhenIdle
            }
            Label {
                text: i18n("after")
                enabled: hideWhenIdle.checked
            }
            SpinBox {
                id: idleTimer
                enabled: hideWhenIdle.checked
                from: 1
                to: 3600
            }
            Label {
                text: i18n("seconds")
                enabled: hideWhenIdle.checked
            }
        }

        CheckBox {
            id: pauseFullScreen
            Kirigami.FormData.label: i18n("Stop CAVA when:")
            text: i18n("A fullscreen window is open")
        }

        CheckBox {
            id: pauseMaximized
            text: i18n("A maximized window is open")
        }

        CheckBox {
            id: hideToolTip
            Kirigami.FormData.label: i18n("Tooltip:")
            text: i18n("Hide")
        }

        CheckBox {
            id: disableLeftClick
            Kirigami.FormData.label: i18n("Left click:")
            text: i18n("Do not open the status popup")
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Troubleshooting")
        }

        CheckBox {
            id: debugMode
            Kirigami.FormData.label: i18n("Debug mode:")
            text: i18n("Show a frame-time readout on the sphere")
        }

        Label {
            text: i18n("Also raises the log level. Watch it with:\n  journalctl -f -t plasmashell | grep tausif.aurora.ncs")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }
    }
}
