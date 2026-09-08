#!/bin/sh
# Builds the GPU renderer plugin and installs it into Qt's QML import path.
# Needs: gcc-c++, cmake, qt6-qtbase-devel, qt6-qtdeclarative-devel
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD="$DIR/build/plugin"

cmake -S "$DIR/plugin" -B "$BUILD" -DCMAKE_BUILD_TYPE=Release
cmake --build "$BUILD" --parallel

echo
echo "Installing the QML module system-wide (needs sudo)..."
sudo cmake --install "$BUILD"

echo
echo "Plugin installed. Reload the shell:  systemctl --user restart plasma-plasmashell"
