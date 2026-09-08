import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property int cfg_motionModel
    property alias cfg_audioGain: audioGain.value
    property alias cfg_averageWindow: averageWindow.value
    property alias cfg_flowSpeed: flowSpeed.value
    property alias cfg_bodyStiffness: stiffness.value
    property alias cfg_bodyDamping: damping.value
    property alias cfg_levelSmooth: levelSmooth.value
    property alias cfg_punch: punch.value
    property alias cfg_beatDecay: beatDecay.value
    property alias cfg_onset: onset.value

    readonly property bool aurora: cfg_motionModel === 1

    function reset() {
        audioGain.value = 1.0;
        averageWindow.value = 0.15;
        flowSpeed.value = 1.0;
        stiffness.value = 20.0;
        damping.value = 0.85;
        levelSmooth.value = 6.5;
        punch.value = 0.5;
        beatDecay.value = 7.0;
        onset.value = 1.18;
    }

    Kirigami.FormLayout {
        id: form

        ComboBox {
            id: modelBox
            Kirigami.FormData.label: i18n("Model:")
            model: [
                {
                    text: i18n("Original (spicetify)"),
                    value: 0
                },
                {
                    text: i18n("Aurora (spring + beat punch)"),
                    value: 1
                }
            ]
            textRole: "text"
            valueRole: "value"
            onActivated: root.cfg_motionModel = currentValue
            Component.onCompleted: currentIndex = indexOfValue(root.cfg_motionModel)
        }

        Label {
            Layout.fillWidth: true
            text: root.aurora
                  ? i18n("A spring carries the body of the motion while a transient detector\nadds a punch on each beat. Reacts harder than the original.")
                  : i18n("What the original does: the amplitude is a plain moving average of\nloudness, and the noise flows at 0.75 x (0.5 + amplitude).\nNo spring, no beat detection.")
            font: Kirigami.Theme.smallFont
            opacity: 0.75
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Input")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Audio gain:")
            Slider {
                id: audioGain
                from: 0.2
                to: 4.0
                stepSize: 0.05
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            }
            Label {
                text: audioGain.value.toFixed(2)
                font.family: "Monospace"
            }
        }

        Label {
            text: i18n("Raise this if the sphere barely moves at your usual listening volume.\nStereo capture reads quieter than mono, so it may want more gain.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        // ── original ─────────────────────────────────────────────────
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Response")
            visible: !root.aurora
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Averaging window:")
            visible: !root.aurora
            Slider {
                id: averageWindow
                from: 0.02
                to: 1.0
                stepSize: 0.01
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            }
            Label {
                text: averageWindow.value.toFixed(2) + " s"
                font.family: "Monospace"
            }
        }

        Label {
            visible: !root.aurora
            text: i18n("The original uses 0.15 s. Shorter is twitchier, longer is calmer.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        // ── aurora ───────────────────────────────────────────────────
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Body")
            visible: root.aurora
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Stiffness:")
            visible: root.aurora
            Slider {
                id: stiffness
                from: 2.0
                to: 60.0
                stepSize: 0.5
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            }
            Label {
                text: stiffness.value.toFixed(1)
                font.family: "Monospace"
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Damping:")
            visible: root.aurora
            Slider {
                id: damping
                from: 0.3
                to: 1.5
                stepSize: 0.01
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            }
            Label {
                text: damping.value.toFixed(2)
                font.family: "Monospace"
            }
        }

        Label {
            visible: root.aurora
            text: i18n("Below 1 the sphere overshoots and springs back; 1 is critically damped.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Loudness follow:")
            visible: root.aurora
            Slider {
                id: levelSmooth
                from: 1.0
                to: 20.0
                stepSize: 0.1
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            }
            Label {
                text: levelSmooth.value.toFixed(1)
                font.family: "Monospace"
            }
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Beat")
            visible: root.aurora
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Punch:")
            visible: root.aurora
            Slider {
                id: punch
                from: 0.0
                to: 1.5
                stepSize: 0.02
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            }
            Label {
                text: punch.value.toFixed(2)
                font.family: "Monospace"
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Beat decay:")
            visible: root.aurora
            Slider {
                id: beatDecay
                from: 2.0
                to: 20.0
                stepSize: 0.1
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            }
            Label {
                text: beatDecay.value.toFixed(1)
                font.family: "Monospace"
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Onset threshold:")
            visible: root.aurora
            Slider {
                id: onset
                from: 1.0
                to: 2.0
                stepSize: 0.01
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            }
            Label {
                text: onset.value.toFixed(2)
                font.family: "Monospace"
            }
        }

        Label {
            visible: root.aurora
            text: i18n("How far the bass has to jump above its running average to count as a beat.\nLower fires more often.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        // ── shared ───────────────────────────────────────────────────
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Flow")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Flow speed:")
            Slider {
                id: flowSpeed
                from: 0.1
                to: 4.0
                stepSize: 0.05
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            }
            Label {
                text: flowSpeed.value.toFixed(2) + "x"
                font.family: "Monospace"
            }
        }

        Label {
            text: i18n("How fast the wave pattern travels across the sphere.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        Button {
            text: i18n("Restore defaults")
            icon.name: "edit-undo-symbolic"
            onClicked: root.reset()
        }
    }
}
