import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import "./components"

Item {
    id: root

    // The orb is square, so in a panel it takes the panel thickness unless the
    // user asked it to stretch.
    readonly property int thickness: main.horizontal ? height : width
    readonly property int wanted: Plasmoid.configuration.expanding ? -1 : Math.max(Plasmoid.configuration.minimumLength, Math.min(Plasmoid.configuration.length, thickness > 0 ? thickness : Plasmoid.configuration.length))

    Layout.preferredWidth: main.onDesktop ? -1 : (main.horizontal ? (Plasmoid.configuration.expanding ? -1 : root.wanted) : -1)
    Layout.preferredHeight: main.onDesktop ? -1 : (!main.horizontal ? (Plasmoid.configuration.expanding ? -1 : root.wanted) : -1)
    Layout.minimumWidth: main.horizontal && Plasmoid.configuration.expanding ? Plasmoid.configuration.minimumLength : -1
    Layout.minimumHeight: !main.horizontal && Plasmoid.configuration.expanding ? Plasmoid.configuration.minimumLength : -1
    Layout.fillWidth: main.onDesktop || !main.horizontal || Plasmoid.configuration.expanding
    Layout.fillHeight: main.onDesktop || main.horizontal || Plasmoid.configuration.expanding

    NcsOrb {
        id: orb
        anchors.fill: parent
        visible: !cava.hasError

        level: main.audioLevel
        bass: main.audioBass

        dotCount: Plasmoid.configuration.dotCount
        orbScale: Plasmoid.configuration.orbScale
        dotScale: Plasmoid.configuration.dotScale
        glowScale: Plasmoid.configuration.glowScale
        targetFps: Plasmoid.configuration.targetFps
        seed: Plasmoid.configuration.seed

        coreColor: main.resolvedCoreColor
        glowColor: main.resolvedGlowColor

        motionModel: Plasmoid.configuration.motionModel
        averageWindow: Plasmoid.configuration.averageWindow
        flowSpeed: Plasmoid.configuration.flowSpeed
        bodyStiffness: Plasmoid.configuration.bodyStiffness
        bodyDamping: Plasmoid.configuration.bodyDamping
        levelSmooth: Plasmoid.configuration.levelSmooth
        punch: Plasmoid.configuration.punch
        beatDecay: Plasmoid.configuration.beatDecay
        onset: Plasmoid.configuration.onset

        debugMode: Plasmoid.configuration.debugMode

        // Keep breathing gently when nothing is playing, and stop entirely when
        // a fullscreen window is up or CAVA has been stopped.
        running: !main.pauseByWindow && !main.stopCava
    }

    Kirigami.Icon {
        anchors.centerIn: parent
        width: Kirigami.Units.iconSizes.roundedIconSize(Math.min(root.width, root.height))
        height: width
        source: Qt.resolvedUrl("./images/error.svg").toString().replace("file://", "")
        active: mouseArea.containsMouse
        isMask: true
        color: Kirigami.Theme.negativeTextColor
        visible: cava.hasError
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: enabled
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: !main.disableLeftClick || cava.hasError || main.expanded
        onClicked: main.expanded = !main.expanded
    }
}
