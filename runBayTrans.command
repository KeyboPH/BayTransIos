#!/bin/bash
set -euo pipefail

PROJECT_DIR="/Users/student/Documents/BayTransIos/bayTrans/bayTrans"
PROJECT_FILE="$PROJECT_DIR/bayTrans.xcodeproj"
WORKSPACE_FILE="$PROJECT_FILE/project.xcworkspace/contents.xcworkspacedata"
SCHEME="bayTrans"
BUNDLE_ID="mseuf.edu.ph.bayTrans"

cd "$PROJECT_DIR"

if [ ! -d "$PROJECT_FILE" ]; then
  echo "Project not found: $PROJECT_FILE"
  exit 1
fi

if [ ! -f "$WORKSPACE_FILE" ]; then
  mkdir -p "$PROJECT_FILE/project.xcworkspace"
  cat > "$WORKSPACE_FILE" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
XML
  echo "Recreated missing Xcode workspace file."
fi

SIM_LINE=$(xcrun simctl list devices available | awk '/-- iOS 26\.5 --/{flag=1;next} flag && /iPhone/ && /(Booted|Shutdown)/ {print; exit}')

if [ -z "$SIM_LINE" ]; then
  echo "No iPhone simulator running iOS 26.5 is available. Open Xcode > Simulator and create or boot one."
  exit 1
fi

SIM_RAW="${SIM_LINE#"${SIM_LINE%%[![:space:]]*}"}"
SIM_UDID="${SIM_RAW#*(}"
SIM_UDID="${SIM_UDID%%)*}"
SIM_NAME="${SIM_RAW%\ ($SIM_UDID)*}"

if [ -z "$SIM_NAME" ] || [ -z "$SIM_UDID" ]; then
  echo "Could not resolve a valid simulator from Xcode."
  exit 1
fi

echo "Using simulator: $SIM_NAME"
open -a Simulator
xcrun simctl boot "$SIM_UDID" >/dev/null 2>&1 || true

mkdir -p "$PROJECT_DIR/build"

xcodebuild \
  -project "$PROJECT_FILE" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIM_UDID" \
  build \
  -derivedDataPath "$PROJECT_DIR/build/DerivedData"

APP_PATH=$(find "$PROJECT_DIR/build/DerivedData" -path "*Build/Products/Debug-iphonesimulator/$SCHEME.app" | head -n 1)

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
  echo "Build completed, but the app bundle was not found."
  exit 1
fi

xcrun simctl install "$SIM_UDID" "$APP_PATH" || true
xcrun simctl launch --console "$SIM_UDID" "$BUNDLE_ID" || true

echo "Build finished. The app is installed and launch was attempted in the simulator."
