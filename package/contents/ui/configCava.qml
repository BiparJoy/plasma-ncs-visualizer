import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "./components"

KCM.SimpleKCM {
    id: root

    property alias cfg_framerate: framerate.value
    property alias cfg_barCount: barCount.value
    property alias cfg_noiseReduction: noiseReduction.value
    property alias cfg_monstercat: monstercat.checked
    property alias cfg_waves: waves.checked
    property alias cfg_lowerCutoffFreq: lowerCutoff.value
    property alias cfg_higherCutoffFreq: higherCutoff.value
    property alias cfg_sensitivityEnabled: sensitivityEnabled.checked
    property alias cfg_sensitivity: sensitivity.value
    property int cfg_autoSensitivity
    property string cfg_inputMethod
    property string cfg_inputSource
    property alias cfg_sampleRate: sampleRate.value
    property alias cfg_sampleBits: sampleBits.value
    property alias cfg_inputChannels: inputChannels.value
    property int cfg_autoconnect
    property alias cfg_active: active.checked
    property alias cfg_remix: remix.checked
    property alias cfg_virtual: virtualCheck.checked
    property string cfg_outputChannels
    property string cfg_monoOption
    property alias cfg_cavaSleepTimer: sleepTimer.value

    PactlList {
        id: pactl
    }

    Kirigami.FormLayout {
        id: form

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Capture")
        }

        ComboBox {
            id: inputMethod
            Kirigami.FormData.label: i18n("Input method:")
            model: ["", "pulse", "pipewire", "alsa", "portaudio", "sndio", "oss", "jack", "shmem", "fifo"]
            onActivated: root.cfg_inputMethod = currentText
            Component.onCompleted: currentIndex = Math.max(0, model.indexOf(root.cfg_inputMethod))
            displayText: currentText === "" ? i18n("Auto") : currentText
        }

        ComboBox {
            id: inputSource
            Kirigami.FormData.label: i18n("Input source:")
            editable: true
            model: pactl.names
            onAccepted: root.cfg_inputSource = editText
            onActivated: root.cfg_inputSource = currentText
            Component.onCompleted: editText = root.cfg_inputSource
        }

        Label {
            text: i18n("Leave empty (or pick \"auto\") to follow the default output monitor.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        ComboBox {
            id: outputChannels
            Kirigami.FormData.label: i18n("Channels:")
            model: [
                { text: i18n("Mono"), value: "mono" },
                { text: i18n("Stereo"), value: "stereo" }
            ]
            textRole: "text"
            valueRole: "value"
            onActivated: root.cfg_outputChannels = currentValue
            Component.onCompleted: currentIndex = indexOfValue(root.cfg_outputChannels)
        }

        ComboBox {
            id: monoOption
            Kirigami.FormData.label: i18n("Mono from:")
            visible: root.cfg_outputChannels === "mono"
            model: [
                { text: i18n("Average"), value: "average" },
                { text: i18n("Left"), value: "left" },
                { text: i18n("Right"), value: "right" }
            ]
            textRole: "text"
            valueRole: "value"
            onActivated: root.cfg_monoOption = currentValue
            Component.onCompleted: currentIndex = indexOfValue(root.cfg_monoOption)
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Analysis")
        }

        SpinBox {
            id: barCount
            Kirigami.FormData.label: i18n("Bars:")
            from: 8
            to: 128
        }

        Label {
            text: i18n("The sphere only needs a loudness and a bass reading, so a modest number\nof bars is plenty. 32 is a good default.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        SpinBox {
            id: framerate
            Kirigami.FormData.label: i18n("CAVA frame rate:")
            from: 10
            to: 144
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Noise reduction:")
            Slider {
                id: noiseReduction
                from: 0
                to: 100
                stepSize: 1
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            }
            Label {
                text: noiseReduction.value
                font.family: "Monospace"
            }
        }

        Label {
            text: i18n("CAVA already smooths its output. Aurora's spring does its own smoothing on\ntop, so a lower value here keeps beats crisp.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        CheckBox {
            id: monstercat
            Kirigami.FormData.label: i18n("Smoothing:")
            text: i18n("Monstercat")
        }

        CheckBox {
            id: waves
            text: i18n("Waves")
        }

        SpinBox {
            id: lowerCutoff
            Kirigami.FormData.label: i18n("Lower cutoff (Hz):")
            from: 1
            to: 20000
            stepSize: 10
        }

        SpinBox {
            id: higherCutoff
            Kirigami.FormData.label: i18n("Higher cutoff (Hz):")
            from: 1
            to: 22050
            stepSize: 100
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Sensitivity")
        }

        CheckBox {
            id: autoSensitivity
            Kirigami.FormData.label: i18n("Automatic:")
            checked: root.cfg_autoSensitivity === 1
            onToggled: root.cfg_autoSensitivity = checked ? 1 : 0
        }

        CheckBox {
            id: sensitivityEnabled
            Kirigami.FormData.label: i18n("Manual:")
            text: i18n("Override")
        }

        RowLayout {
            visible: sensitivityEnabled.checked
            Slider {
                id: sensitivity
                from: 1
                to: 500
                stepSize: 1
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            }
            Label {
                text: sensitivity.value
                font.family: "Monospace"
            }
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Advanced")
        }

        SpinBox {
            id: sampleRate
            Kirigami.FormData.label: i18n("Sample rate:")
            from: 8000
            to: 192000
            stepSize: 100
        }

        SpinBox {
            id: sampleBits
            Kirigami.FormData.label: i18n("Sample bits:")
            from: 8
            to: 32
            stepSize: 8
        }

        SpinBox {
            id: inputChannels
            Kirigami.FormData.label: i18n("Input channels:")
            from: 1
            to: 2
        }

        SpinBox {
            id: autoconnect
            Kirigami.FormData.label: i18n("Autoconnect:")
            from: 0
            to: 2
            value: root.cfg_autoconnect
            onValueModified: root.cfg_autoconnect = value
        }

        CheckBox {
            id: active
            Kirigami.FormData.label: i18n("PipeWire:")
            text: i18n("Only capture active streams")
        }

        CheckBox {
            id: remix
            text: i18n("Remix")
        }

        CheckBox {
            id: virtualCheck
            text: i18n("Virtual")
        }

        SpinBox {
            id: sleepTimer
            Kirigami.FormData.label: i18n("CAVA sleep timer (s):")
            from: 0
            to: 300
        }

        Label {
            text: i18n("How long CAVA waits with no audio before it stops reading the device.\n0 disables it.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }
    }
}
