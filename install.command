#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

echo "=== xkill-mac Installer ==="
echo ""

# Generate icon if needed
if [ ! -f AppIcon.icns ]; then
    echo "Generating icon..."
    swift create_icon.swift
fi

# Build
echo "Building..."
swift build -c release 2>&1

# Create .app bundle
APP="xkill-mac.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
cp .build/release/xkill-mac "$APP/Contents/MacOS/xkill-mac"
cp Sources/xkill-mac/Info.plist "$APP/Contents/Info.plist"
cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp Assets/skull_normal.png "$APP/Contents/Resources/skull_normal.png"
cp Assets/skull_active.png "$APP/Contents/Resources/skull_active.png"
echo "Signing..."
codesign --sign - --force --deep "$APP"

# Install to /Applications
echo ""
echo "Installing to /Applications..."
rm -rf "/Applications/$APP"
cp -r "$APP" "/Applications/$APP"

echo ""
echo "Done! xkill-mac installed in /Applications."
echo ""
echo "IMPORTANT: On first launch, grant Accessibility permission"
echo "in System Settings > Privacy & Security > Accessibility,"
echo "then relaunch the app."
echo ""

# Launch
open "/Applications/$APP"
