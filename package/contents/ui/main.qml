import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import "code/ncs.js" as Ncs

PlasmoidItem {
    id: main

    Plasmoid.backgroundHints: editMode ? PlasmaCore.Types.StandardBackground : plasmoid.configuration.desktopWidgetBg
    Plasmoid.constraintHints: Plasmoid.configuration.fillPanel ? Plasmoid.CanFillArea : Plasmoid.NoHint
    Plasmoid.status: PlasmaCore.Types.ActiveStatus

    property bool editMode: Plasmoid.containment.corona?.editMode ?? false
    property bool onDesktop: Plasmoid.location === PlasmaCore.Types.Floating
    property bool horizontal: Plasmoid.formFactor !== PlasmaCore.Types.Vertical
    property bool stopCava: Plasmoid.configuration._stopCava
    property bool disableLeftClick: Plasmoid.configuration.disableLeftClick
    property bool hideWhenIdle: Plasmoid.configuration.hideWhenIdle

    property bool pauseFullScreen: Plasmoid.configuration.pauseOnFullScreenWindow
    property bool pauseMaximized: Plasmoid.configuration.pauseOnMaximizedWindow
    property bool pauseByWindow: (pauseMaximized && tasksModel.maximizedExists) || (pauseFullScreen && tasksModel.fullScreenExists)

    property var logger: Logger.create(Plasmoid.configuration.debugMode ? LoggingCategory.Debug : LoggingCategory.Info)

    // CAVA reports each bar as 0..asciiMaxRange; a fixed range keeps the
    // loudness estimate independent of how large the widget happens to be.
    readonly property int asciiMaxRange: 1000

    readonly property bool stereo: Plasmoid.configuration.outputChannels === "stereo"
    // CAVA silently rounds the bar count down to even in stereo (bars=31 yields
    // 30 values), so ask for an even number in the first place.
    readonly property int effectiveBarCount: stereo ? Math.max(2, Plasmoid.configuration.barCount & ~1) : Plasmoid.configuration.barCount

    // --- colour ----------------------------------------------------------
    property real hueCycle: 0

    readonly property color resolvedCoreColor: {
        switch (Plasmoid.configuration.colorSource) {
        case 1:
            return Kirigami.Theme.highlightColor;
        case 2:
            return Qt.hsla(main.hueCycle, 0.9, 0.62, 1.0);
        default:
            return Plasmoid.configuration.coreColor;
        }
    }

    readonly property color resolvedGlowColor: {
        if (Plasmoid.configuration.linkGlowColor) {
            return main.resolvedCoreColor;
        }
        switch (Plasmoid.configuration.colorSource) {
        case 1:
            return Kirigami.Theme.highlightColor;
        case 2:
            return Qt.hsla((main.hueCycle + 0.08) % 1.0, 0.9, 0.6, 1.0);
        default:
            return Plasmoid.configuration.glowColor;
        }
    }

    Timer {
        // Only ticks when the hue cycle colour mode is actually selected.
        running: Plasmoid.configuration.colorSource === 2 && !main.pauseByWindow
        repeat: true
        interval: 50
        onTriggered: main.hueCycle = (main.hueCycle + Plasmoid.configuration.hueCycleSpeed * 0.05) % 1.0
    }

    // --- audio -----------------------------------------------------------
    property real audioLevel: 0
    property real audioBass: 0

    function updateStatus() {
        Qt.callLater(() => {
            if (Plasmoid.status === PlasmaCore.Types.RequiresAttentionStatus) {
                return;
            }
            Plasmoid.status = (hideWhenIdle && cava.idle || !cava.running) && !Plasmoid.expanded && !editMode && !cava.hasError ? PlasmaCore.Types.HiddenStatus : PlasmaCore.Types.ActiveStatus;
        });
    }

    onExpandedChanged: updateStatus()
    onEditModeChanged: {
        logger.debug("editMode:", editMode);
        updateStatus();
    }

    Cava {
        id: cava
        framerate: Plasmoid.configuration.framerate
        barCount: main.effectiveBarCount
        asciiMaxRange: main.asciiMaxRange
        noiseReduction: Plasmoid.configuration.noiseReduction
        monstercat: Plasmoid.configuration.monstercat
        waves: Plasmoid.configuration.waves
        autoSensitivity: Plasmoid.configuration.autoSensitivity
        sensitivityEnabled: Plasmoid.configuration.sensitivityEnabled
        sensitivity: Plasmoid.configuration.sensitivity
        lowerCutoffFreq: Plasmoid.configuration.lowerCutoffFreq
        higherCutoffFreq: Plasmoid.configuration.higherCutoffFreq
        inputMethod: Plasmoid.configuration.inputMethod
        inputSource: Plasmoid.configuration.inputSource
        sampleRate: Plasmoid.configuration.sampleRate
        sampleBits: Plasmoid.configuration.sampleBits
        inputChannels: Plasmoid.configuration.inputChannels
        autoconnect: Plasmoid.configuration.autoconnect
        active: Plasmoid.configuration.active
        remix: Plasmoid.configuration.remix
        virtual: Plasmoid.configuration.virtual
        outputChannels: Plasmoid.configuration.outputChannels
        monoOption: Plasmoid.configuration.monoOption
        reverse: 0
        waveform: 0
        eqEnabled: Plasmoid.configuration.eqEnabled
        eq: Plasmoid.configuration.eq
        idleCheck: main.hideWhenIdle
        idleTimer: Plasmoid.configuration.idleTimer
        cavaSleepTimer: Plasmoid.configuration.cavaSleepTimer

        onValuesChanged: {
            const a = Ncs.analyseBars(cava.values, main.asciiMaxRange, Plasmoid.configuration.audioGain, main.stereo);
            main.audioLevel = a.level;
            main.audioBass = a.bass;
        }
        onIdleChanged: {
            main.logger.info("cava.idle:", idle);
            main.updateStatus();
        }
        onHasErrorChanged: {
            main.logger.error("cava.hasError:", hasError, error);
            main.updateStatus();
        }
        onRunningChanged: {
            main.logger.info("cava.running:", running);
            main.updateStatus();
        }
    }

    preferredRepresentation: compactRepresentation
    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}

    onStopCavaChanged: {
        logger.debug("stopCava:", stopCava);
        if (stopCava) {
            cava.stop();
        } else {
            cava.start();
        }
    }

    onPauseByWindowChanged: {
        if (Plasmoid.configuration._stopCava) {
            return;
        }
        if (pauseByWindow) {
            cava.stop();
        } else {
            cava.start();
        }
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: cava.running ? i18n("Stop CAVA") : i18n("Start CAVA")
            icon.name: "waveform-symbolic"
            onTriggered: {
                Plasmoid.configuration._stopCava = !Plasmoid.configuration._stopCava;
                Plasmoid.configuration.writeConfig();
            }
        },
        PlasmaCore.Action {
            text: i18n("Show status")
            icon.name: "info-symbolic"
            onTriggered: main.expanded = !main.expanded
        }
    ]

    toolTipMainText: i18n("Aurora NCS Visualizer")
    toolTipSubText: {
        if (cava.hasError) {
            return i18n("CAVA error - open the widget for details");
        }
        if (!cava.running) {
            return i18n("CAVA is stopped");
        }
        return i18n("Listening to system audio");
    }

    Connections {
        target: Qt.application
        function onAboutToQuit() {
            cava.stop();
        }
    }

    TasksModel {
        id: tasksModel
        screenGeometry: Plasmoid.containment.screenGeometry
    }
}
