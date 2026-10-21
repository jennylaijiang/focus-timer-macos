#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! xcrun --find xcodebuild >/dev/null 2>&1; then
    echo 'Full Xcode 16 or later must be installed and selected to compile SwiftData models.' >&2
    echo 'Select Xcode in Xcode Settings > Locations > Command Line Tools, then retry.' >&2
    exit 1
fi
unset FOCUS_ENGINE_ONLY
configuration="${1:-release}"
if [[ "$configuration" != "debug" && "$configuration" != "release" ]]; then
    echo 'Usage: scripts/build-app.sh [debug|release]' >&2
    exit 1
fi
swift build -c "$configuration" --product Focus
binary_dir="$(swift build -c "$configuration" --show-bin-path)"
app="build/Focus.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$binary_dir/Focus" "$app/Contents/MacOS/Focus"
cp Resources/Info.plist "$app/Contents/Info.plist"
printf 'APPL????' > "$app/Contents/PkgInfo"
codesign --force --sign - "$app"
echo "Built $PWD/$app"
