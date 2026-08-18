#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
CONFIGURATION="${1:-release}"
BUILD_DIR="$ROOT_DIR/.build/$CONFIGURATION"
APP_DIR="$ROOT_DIR/dist/AstraPet.app"
CONTENTS_DIR="$APP_DIR/Contents"

cd "$ROOT_DIR"
swift build -c "$CONFIGURATION"
BUILD_DIR="${BUILD_DIR:A}"

rm -rf "$APP_DIR"
mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources"
cp "$BUILD_DIR/AstraPet" "$CONTENTS_DIR/MacOS/AstraPet"
cp "$ROOT_DIR/support/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/Sources/AstraPet/Resources/robot.png" "$CONTENTS_DIR/Resources/robot.png"

codesign --force --deep --sign - "$APP_DIR"
print "Built $APP_DIR"
