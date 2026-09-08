import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "./components"

KCM.SimpleKCM {
    id: root

    property int cfg_colorSource
    property string cfg_coreColor
    property string cfg_glowColor
    property alias cfg_linkGlowColor: linkGlow.checked
    property alias cfg_hueCycleSpeed: hueSpeed.value
    property alias cfg_dotCount: dotCount.value
    property alias cfg_targetFps: targetFps.value
    property alias cfg_orbScale: orbScale.value
    property alias cfg_dotScale: dotScale.value
    property alias cfg_glowScale: glowScale.value
    property alias cfg_seed: seed.value

    Kirigami.FormLayout {
        id: form

        // ── colour ───────────────────────────────────────────────────
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Colour")
        }

        ComboBox {
            id: colorSource
            Kirigami.FormData.label: i18n("Source:")
            model: [
                {
                    text: i18n("Custom colour"),
                    value: 0
                },
                {
                    text: i18n("Plasma accent colour"),
                    value: 1
                },
                {
                    text: i18n("Cycle through hues"),
                    value: 2
                }
            ]
            textRole: "text"
            valueRole: "value"
            onActivated: root.cfg_colorSource = currentValue
            Component.onCompleted: currentIndex = indexOfValue(root.cfg_colorSource)
        }

        ColorButton {
            Kirigami.FormData.label: i18n("Dot colour:")
            visible: root.cfg_colorSource === 0
            dialogTitle: i18n("Dot colour")
            color: root.cfg_coreColor
            onAccepted: color => root.cfg_coreColor = color
        }

        CheckBox {
            id: linkGlow
            Kirigami.FormData.label: i18n("Glow:")
            text: i18n("Same colour as the dots")
        }

        Label {
            text: i18n("The original tints the whole sphere with one colour. Unlink this to tint\nthe bloom separately.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        ColorButton {
            Kirigami.FormData.label: i18n("Glow colour:")
            visible: root.cfg_colorSource === 0 && !linkGlow.checked
            dialogTitle: i18n("Glow colour")
            color: root.cfg_glowColor
            onAccepted: color => root.cfg_glowColor = color
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Cycle speed:")
            visible: root.cfg_colorSource === 2
            Slider {
                id: hueSpeed
                from: 0.005
                to: 0.3
                stepSize: 0.005
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            }
            Label {
                text: hueSpeed.value.toFixed(3)
                font.family: "Monospace"
            }
        }

        // ── sphere ───────────────────────────────────────────────────
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Sphere")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Size:")
            Slider {
                id: orbScale
                from: 0.4
                to: 1.0
                stepSize: 0.02
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            }
            Label {
                text: Math.round(orbScale.value * 100) + "%"
                font.family: "Monospace"
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Dots per side:")
            Slider {
                id: dotCount
                from: 32
                to: 512
                stepSize: 2
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            }
            Label {
                text: i18n("%1 dots", dotCount.value * dotCount.value)
                font.family: "Monospace"
            }
        }

        Label {
            text: i18n("322 is what the original uses (103,684 dots). It all runs on the GPU, so\nthis costs far less than it sounds.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Dot size:")
            Slider {
                id: dotScale
                from: 0.3
                to: 4.0
                stepSize: 0.05
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            }
            Label {
                text: dotScale.value.toFixed(2) + "x"
                font.family: "Monospace"
            }
        }

        Label {
            text: i18n("A multiplier on the original's dot radius of 0.9 / dots-per-side.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Glow radius:")
            Slider {
                id: glowScale
                from: 0.0
                to: 4.0
                stepSize: 0.05
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            }
            Label {
                text: glowScale.value.toFixed(2) + "x"
                font.family: "Monospace"
            }
        }

        Label {
            text: i18n("A multiplier on the original's blur radius of 1% of the sphere size.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        // ── other ────────────────────────────────────────────────────
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Other")
        }

        SpinBox {
            id: targetFps
            Kirigami.FormData.label: i18n("Frame rate limit:")
            from: 10
            to: 144
            stepSize: 5
        }

        SpinBox {
            id: seed
            Kirigami.FormData.label: i18n("Noise seed:")
            from: 0
            to: 999999
        }

        Label {
            text: i18n("Changes the shape of the wave pattern. The original reseeds it per track.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }
    }
}
