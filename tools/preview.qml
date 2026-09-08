// Standalone preview of the renderer, with no Plasma or CAVA involved.
//
//   qml tools/preview.qml
//
// Useful when changing the shaders or the plugin: it isolates the GPU pipeline
// from the widget, and prints any shader compile error straight to the console.

import QtQuick
import QtQuick.Window
import com.tausif.aurorancs

Window {
    id: win
    visible: true
    width: 900
    height: 900
    color: "#111111"
    title: "NCS renderer preview"

    NcsVisualizer {
        id: viz
        anchors.fill: parent
        dotCount: 322
        seed: 1234
        color: "#1a9fc4"
        glowColor: "#1a9fc4"
        // sweep the amplitude so the sphere inflates and deflates
        amplitude: 0.5 + 0.45 * Math.sin(clock.t * 0.6)
        onErrorChanged: if (error !== "") console.log("NCS ERROR:", error)
    }

    FrameAnimation {
        id: clock
        running: true
        property real t: 0
        onTriggered: {
            t += frameTime;
            // the original's noise rate: 0.75 * (0.5 + amplitude)
            viz.noiseOffset += frameTime * 0.75 * (0.5 + viz.amplitude);
        }
    }

    Text {
        x: 10
        y: 10
        color: "#ffffff"
        font.family: "monospace"
        text: `${viz.dotCount}^2 = ${viz.dotCount * viz.dotCount} dots   ` +
              `amplitude ${viz.amplitude.toFixed(2)}   noise ${viz.noiseOffset.toFixed(1)}` +
              (viz.error !== "" ? "\n" + viz.error : "")
    }
}
