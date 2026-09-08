#!/bin/sh
set -e
kpackagetool6 --type Plasma/Applet --remove tausif.aurora.ncs.visualizer
echo "Removed. Reload the shell with: systemctl --user restart plasma-plasmashell"
