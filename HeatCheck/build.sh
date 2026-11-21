#!/bin/sh
# Builds HeatCheck.app from a single Swift file and signs it locally with the App Sandbox.
set -eu
cd "$(dirname "$0")"

APP=build/HeatCheck.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Info.plist "$APP/Contents/Info.plist"
cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"  # drawn by make-icon.sh

swiftc -O -swift-version 6 -parse-as-library HeatCheck.swift \
    -o "$APP/Contents/MacOS/HeatCheck"

# "-" means ad-hoc signing: local, no developer certificate needed.
codesign --force --sign - --entitlements HeatCheck.entitlements "$APP"

echo "Done: $APP"
