import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../code/ncs.js" as Ncs

// Drives the NCS visualizer.
//
// The rendering is the original spicetify-visualizer pipeline, running in the
// C++ plugin. This item owns the motion model that stands in for Spotify's
// audio analysis, and feeds it in as `amplitude` and `noiseOffset` each frame.

Item {
    id: root

    // audio, 0..1
    property real level: 0
    property real bass: 0

    // geometry / quality
    property int dotCount: 322
    property real orbScale: 1.0
    property real dotScale: 1.0
    property real glowScale: 1.0
    property int targetFps: 60
    property bool running: true
    property int seed: 1234

    // colour
    property color coreColor: "#ff2e88"
    property color glowColor: "#ff2e88"

    // motion model
    property int motionModel: 0
    property real averageWindow: 0.15
    property real flowSpeed: 1.0
    property real bodyStiffness: 20.0
    property real bodyDamping: 0.85
    property real levelSmooth: 6.5
    property real punch: 0.5
    property real beatDecay: 7.0
    property real onset: 1.18

    property bool debugMode: false

    readonly property int orbSize: Math.max(8, Math.floor(Math.min(width, height) * orbScale))
    readonly property real fps: fpsMeter.fps
    property real amplitude: 0.15

    readonly property bool pluginMissing: loader.status === Loader.Error
    readonly property string rendererError: {
        if (pluginMissing) {
            return i18n("GPU renderer plugin not installed");
        }
        return loader.item ? loader.item.error : "";
    }

    property var motion: Ncs.createMotion()

    function applyMotion() {
        motion.model = root.motionModel;
        motion.averageWindow = root.averageWindow;
        motion.flowSpeed = root.flowSpeed;
        motion.bodyStiffness = root.bodyStiffness;
        motion.bodyDamping = root.bodyDamping;
        motion.levelSmooth = root.levelSmooth;
        motion.punch = root.punch;
        motion.beatDecay = root.beatDecay;
        motion.onset = root.onset;
    }

    onMotionModelChanged: applyMotion()
    onAverageWindowChanged: applyMotion()
    onFlowSpeedChanged: applyMotion()
    onBodyStiffnessChanged: applyMotion()
    onBodyDampingChanged: applyMotion()
    onLevelSmoothChanged: applyMotion()
    onPunchChanged: applyMotion()
    onBeatDecayChanged: applyMotion()
    onOnsetChanged: applyMotion()

    Component.onCompleted: applyMotion()

    QtObject {
        id: fpsMeter
        property real fps: 0
        property int frames: 0
        property real accum: 0

        function tick(dt) {
            frames += 1;
            accum += dt;
            if (accum >= 0.5) {
                fps = frames / accum;
                frames = 0;
                accum = 0;
            }
        }
    }

    // Vsync-driven, then decimated down to targetFps so a 144 Hz screen does
    // not cost more than a 60 Hz one.
    FrameAnimation {
        id: ticker
        running: root.running && root.visible && root.width > 0 && loader.item !== null
        property real carry: 0
        readonly property real minStep: 1.0 / Math.max(1, root.targetFps) - 0.002

        onTriggered: {
            carry += Math.min(frameTime, 0.25);
            if (carry < minStep) {
                return;
            }
            const dt = carry;
            carry = 0;

            root.motion.setAudio(root.level, root.bass);
            root.motion.update(dt);
            fpsMeter.tick(dt);

            root.amplitude = root.motion.amplitude;

            const item = loader.item;
            if (item) {
                item.amplitude = root.motion.amplitude;
                item.noiseOffset = root.motion.noiseOffset;
            }
        }
    }

    Loader {
        id: loader
        anchors.centerIn: parent
        width: root.orbSize
        height: root.orbSize
        source: Qt.resolvedUrl("NcsSurface.qml")

        onLoaded: {
            item.color = Qt.binding(() => root.coreColor);
            item.glowColor = Qt.binding(() => root.glowColor);
            item.dotCount = Qt.binding(() => root.dotCount);
            item.dotScale = Qt.binding(() => root.dotScale);
            item.glowScale = Qt.binding(() => root.glowScale);
            item.seed = Qt.binding(() => root.seed);
        }
    }

    // --- renderer missing / failed ---------------------------------------
    // Shown unconditionally, not just in debug mode: without the compiled
    // plugin there is nothing else on screen, and a blank widget gives the user
    // no idea why.
    Rectangle {
        anchors.fill: parent
        visible: root.rendererError !== ""
        color: Qt.rgba(0, 0, 0, 0.35)
        radius: Kirigami.Units.cornerRadius
        border.width: 1
        border.color: Kirigami.Theme.negativeTextColor

        ColumnLayout {
            anchors.centerIn: parent
            anchors.margins: Kirigami.Units.smallSpacing
            width: parent.width - Kirigami.Units.largeSpacing * 2
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Layout.preferredWidth
                source: "dialog-error-symbolic"
                color: Kirigami.Theme.negativeTextColor
                isMask: true
                visible: root.height > Kirigami.Units.iconSizes.medium * 4
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: Kirigami.Theme.negativeTextColor
                font: Kirigami.Theme.smallFont
                text: root.rendererError
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: Kirigami.Theme.textColor
                font: Kirigami.Theme.smallFont
                opacity: 0.8
                visible: root.pluginMissing && root.height > Kirigami.Units.gridUnit * 8
                text: i18n("Build it with install-plugin.sh from the project sources.")
            }
        }
    }

    // --- debug readout ---------------------------------------------------
    Rectangle {
        visible: root.debugMode
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 2
        width: dbg.implicitWidth + 8
        height: dbg.implicitHeight + 6
        color: "#b0000000"
        radius: 3
        Text {
            id: dbg
            anchors.centerIn: parent
            color: "#ffffff"
            font.pixelSize: 10
            font.family: "monospace"
            text: `${root.dotCount}^2 = ${root.dotCount * root.dotCount} dots  ${root.fps.toFixed(0)} fps\n` +
                  `orb ${root.orbSize}px  dot ${root.dotScale.toFixed(2)}x  glow ${root.glowScale.toFixed(2)}x\n` +
                  `lvl ${root.level.toFixed(2)}  bass ${root.bass.toFixed(2)}  amp ${root.amplitude.toFixed(2)}` +
                  (root.rendererError !== "" ? "\n" + root.rendererError : "")
        }
    }
}
