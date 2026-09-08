#!/bin/sh
# Builds the distributable archives.
#
#   <name>-v<version>.plasmoid  the QML widget, installable from Plasma's
#                               "Add Widgets > Install from local file" dialog
#   <name>-v<version>-src.zip   the whole project, including the plugin source
#
# NOTE: a .plasmoid can only contain QML. The GPU renderer is compiled code and
# has to be built separately with ./install-plugin.sh, so the .plasmoid on its
# own will only show "GPU renderer plugin not installed".
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
NAME="aurora-ncs-visualizer"
VERSION=$(grep -o '"Version": *"[^"]*"' "$DIR/package/metadata.json" | cut -d'"' -f4)

PLASMOID="$DIR/$NAME-v$VERSION.plasmoid"
rm -f "$PLASMOID"
(cd "$DIR/package" && zip -qr "$PLASMOID" .)
echo "$PLASMOID"

SRC="$DIR/$NAME-v$VERSION-src.zip"
rm -f "$SRC"
(cd "$DIR" && zip -qr "$SRC" . \
    -x '*.plasmoid' '*-src.zip' 'build/*' '.git/*')
echo "$SRC"
