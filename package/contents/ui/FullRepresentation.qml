import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid

PlasmaExtras.Representation {
    id: root

    Layout.minimumWidth: Kirigami.Units.gridUnit * 22
    Layout.minimumHeight: Kirigami.Units.gridUnit * 16
    Layout.preferredWidth: Kirigami.Units.gridUnit * 26
    Layout.preferredHeight: Kirigami.Units.gridUnit * 20

    collapseMarginsHint: true

    header: PlasmaExtras.PlasmoidHeading {
        contentItem: RowLayout {
            Kirigami.Heading {
                Layout.fillWidth: true
                level: 2
                text: i18n("Aurora NCS Visualizer")
                elide: Text.ElideRight
            }
            PlasmaComponents.Button {
                text: cava.running ? i18n("Stop CAVA") : i18n("Start CAVA")
                icon.name: "waveform-symbolic"
                onClicked: {
                    Plasmoid.configuration._stopCava = !Plasmoid.configuration._stopCava;
                    Plasmoid.configuration.writeConfig();
                }
            }
        }
    }

    contentItem: PlasmaComponents.ScrollView {
        contentWidth: availableWidth - Kirigami.Units.smallSpacing * 2

        ColumnLayout {
            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            Kirigami.InlineMessage {
                Layout.fillWidth: true
                visible: cava.hasError
                type: Kirigami.MessageType.Error
                text: cava.error !== "" ? cava.error : i18n("CAVA could not be started.")
            }

            Kirigami.InlineMessage {
                Layout.fillWidth: true
                visible: cava.loadingFailed
                type: Kirigami.MessageType.Error
                text: i18n("No way to run CAVA was available.\n\nInstall python3-websockets and qt6-qtwebsockets, or build the C++ process plugin.\n\n%1", cava.loadingErrors.join("\n"))
            }

            Kirigami.InlineMessage {
                Layout.fillWidth: true
                visible: !cava.hasError && !cava.running
                type: Kirigami.MessageType.Information
                text: i18n("CAVA is not running. Play something, or press Start CAVA.")
            }

            Kirigami.FormLayout {
                Layout.fillWidth: true

                PlasmaComponents.Label {
                    Kirigami.FormData.label: i18n("CAVA:")
                    text: cava.running ? i18n("Running") : i18n("Stopped")
                }
                PlasmaComponents.Label {
                    Kirigami.FormData.label: i18n("Process backend:")
                    text: cava.usingFallback ? i18n("WebSocket fallback (python)") : i18n("C++ plugin")
                }
                PlasmaComponents.Label {
                    Kirigami.FormData.label: i18n("Bars:")
                    text: cava.values.length
                }
                PlasmaComponents.Label {
                    Kirigami.FormData.label: i18n("Level / bass:")
                    text: `${main.audioLevel.toFixed(3)}  /  ${main.audioBass.toFixed(3)}`
                }
                PlasmaComponents.Label {
                    Kirigami.FormData.label: i18n("Dots:")
                    text: `${Plasmoid.configuration.dotCount * Plasmoid.configuration.dotCount} (${Plasmoid.configuration.dotCount} per side)`
                }
                PlasmaComponents.Label {
                    Kirigami.FormData.label: i18n("Paused by window:")
                    text: main.pauseByWindow ? i18n("Yes") : i18n("No")
                }
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                font: Kirigami.Theme.smallFont
                opacity: 0.7
                text: i18n("Turn on Debug mode in the widget settings to see a live frame rate readout on the sphere.")
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                font: Kirigami.Theme.smallFont
                opacity: 0.6
                text: i18n("Visualizer from spicetify-visualizer by Konsl. CAVA plumbing derived from Plasma Audio Visualizer by Luis Bocanegra. Both GPL-3.0.")
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
