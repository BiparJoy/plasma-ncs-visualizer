#!/bin/sh
# Installs (or upgrades) the widget for the current user.
set -e

ID="tausif.aurora.ncs.visualizer"
DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.local/share/plasma/plasmoids/$ID"

if kpackagetool6 --type Plasma/Applet --list 2>/dev/null | grep -qx "$ID"; then
    echo "Upgrading $ID ..."
    kpackagetool6 --type Plasma/Applet --upgrade "$DIR/package"
else
    echo "Installing $ID ..."
    kpackagetool6 --type Plasma/Applet --install "$DIR/package"
fi

# Plasma caches compiled QML and can keep serving the previous version.
rm -f "$HOME/.cache/qmlcache/"*ncs* "$HOME/.cache/qmlcache/"*aurora* 2>/dev/null || true

# kpackagetool does not preserve the executable bit
[ -f "$TARGET/contents/ui/tools/commandMonitor" ] && chmod +x "$TARGET/contents/ui/tools/commandMonitor"

# The QML side is useless without the GPU renderer.
if [ ! -f /usr/lib64/qt6/qml/com/tausif/aurorancs/libaurorancs.so ] \
   && [ ! -f /usr/lib/qt6/qml/com/tausif/aurorancs/libaurorancs.so ]; then
    echo
    echo "NOTE: the GPU renderer plugin is not installed yet."
    echo "      Run ./install-plugin.sh first, or the widget will only show an error."
fi

echo
echo "Installed to $TARGET"
echo "Add it with: right click the desktop or panel > Add or Manage Widgets > Aurora NCS Visualizer"
echo "If it was already on screen, reload the shell:  systemctl --user restart plasma-plasmashell"
