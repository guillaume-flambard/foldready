#!/usr/bin/env bash
# foldready capture.sh — build an iOS app for the widest available simulator,
# install, launch and screenshot it. Feeds `foldready <path> --with-screenshots <out>`.
#
#   ./Scripts/capture.sh <repo> [--name App] [--out <dir>] [--landscape]
#
# Notes:
#   - No code signing needed for the simulator.
#   - The iPhone Fold simulator device type ships with Xcode 27. Until then the
#     widest device is used; swap the DEVICE_HINT below when Xcode 27 lands.
set -euo pipefail

REPO="${1:?usage: capture.sh <repo> [--name App] [--out dir] [--landscape]}"
shift
NAME=""
OUT=""
LANDSCAPE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) NAME="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --landscape) LANDSCAPE=1; shift ;;
    *) echo "unknown arg: $1"; exit 1 ;;
  esac
done

DEVICE_HINT="${FOLDREAD_DEVICE:-iPhone 16 Pro Max}"
RUNTIME_HINT="${FOLDREAD_RUNTIME:-iOS-18-5}"

cd "$REPO"
PROJ=$(ls *.xcodeproj 2>/dev/null | head -1)
WORKSPACE=$(ls *.xcworkspace 2>/dev/null | head -1)
if [[ -z "$PROJ" && -z "$WORKSPACE" ]]; then
  echo "error: no .xcodeproj or .xcworkspace in $REPO" >&2
  exit 1
fi
[[ -z "$NAME" ]] && NAME=$(basename "$REPO")
[[ -z "$OUT" ]] && OUT="$REPO/foldready-screenshots"
mkdir -p "$OUT"

# Find or create the widest compatible simulator.
UDID=$(xcrun simctl list devices available -j 2>/dev/null \
  | python3 -c "import json,sys;d=json.load(sys.stdin)['devices'];\
print(next((x['udid'] for k in sorted(d) for x in d[k] if '$DEVICE_HINT' in x['name']),''))")
if [[ -z "$UDID" ]]; then
  UDID=$(xcrun simctl create "FoldReady-Target" "$DEVICE_HINT" "com.apple.CoreSimulator.SimRuntime.$RUNTIME_HINT")
fi
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null

DERIVED="$REPO/.foldready-derived"
rm -rf "$DERIVED"

if [[ -n "$WORKSPACE" ]]; then
  xcodebuild -workspace "$WORKSPACE" -scheme "$NAME" \
    -destination "id=$UDID" -derivedDataPath "$DERIVED" \
    -configuration Debug CODE_SIGNING_ALLOWED=NO build -quiet
else
  xcodebuild -project "$PROJ" -target "$NAME" \
    -sdk iphonesimulator -destination "id=$UDID" -derivedDataPath "$DERIVED" \
    -configuration Debug CODE_SIGNING_ALLOWED=NO build -quiet
fi

APP=$(find "$DERIVED/Build/Products" -maxdepth 3 -name "*.app" -type d | head -1)
[[ -z "$APP" ]] && { echo "error: no .app produced" >&2; exit 1; }
BUNDLE=$(defaults read "$APP/Info" CFBundleIdentifier)
echo "installing $BUNDLE"
xcrun simctl install "$UDID" "$APP"
xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null
sleep 4
xcrun simctl io "$UDID" screenshot "$OUT/portrait.png"

if [[ "$LANDSCAPE" == "1" ]]; then
  # Rotate via the app's supported orientations when the app allows it.
  osascript -e "tell application \"Simulator\" to activate" 2>/dev/null || true
  osascript -e 'tell application "System Events" to key code 124 using {command down}' 2>/dev/null || true
  sleep 2
  xcrun simctl io "$UDID" screenshot "$OUT/landscape.png" || true
fi

echo "screenshots -> $OUT"
echo "next: foldready $REPO --with-screenshots $OUT --name $NAME --open"
