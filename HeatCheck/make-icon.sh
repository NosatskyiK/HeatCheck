#!/bin/sh
# Draws AppIcon.icns from code (make-icon.swift). Only needed if you change the icon:
# a ready AppIcon.icns is already here, and build.sh just copies it into the app.
set -eu
cd "$(dirname "$0")"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

swiftc -swift-version 6 make-icon.swift -o "$TMP/make-icon"
"$TMP/make-icon" "$TMP/AppIcon.iconset"
iconutil -c icns "$TMP/AppIcon.iconset" -o AppIcon.icns

echo "Done: AppIcon.icns"
