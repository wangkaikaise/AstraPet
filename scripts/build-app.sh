#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
CONFIGURATION="${1:-release}"
BUILD_DIR="$ROOT_DIR/.build/$CONFIGURATION"
APP_DIR="$ROOT_DIR/dist/Eva Desktop Pet.app"
CONTENTS_DIR="$APP_DIR/Contents"

cd "$ROOT_DIR"
swift build -c "$CONFIGURATION"
BUILD_DIR="${BUILD_DIR:A}"

rm -rf "$APP_DIR"
mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources"
cp "$BUILD_DIR/EvaDesktopPet" "$CONTENTS_DIR/MacOS/EvaDesktopPet"
cp "$ROOT_DIR/support/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/support/EvaDesktopPet.icns" "$CONTENTS_DIR/Resources/EvaDesktopPet.icns"
for resource in eva-glass-v11.png eva-glass-v11-blink.png eva-glass-v11-happy.png eva-glass-v11-gloomy.png eva-glass-v11-sleep.png; do
  cp "$ROOT_DIR/Sources/EvaDesktopPet/Resources/$resource" "$CONTENTS_DIR/Resources/$resource"
done

codesign --force --deep --sign - "$APP_DIR"
print "Built $APP_DIR"
