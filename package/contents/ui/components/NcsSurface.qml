import QtQuick
import com.tausif.aurorancs

// Isolated so that NcsOrb can load it through a Loader and report a friendly
// error if the compiled plugin is not installed, instead of failing to build.
NcsVisualizer {
    id: surface
}
