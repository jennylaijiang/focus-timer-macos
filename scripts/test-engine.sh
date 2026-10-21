#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export FOCUS_ENGINE_ONLY=1
export CLANG_MODULE_CACHE_PATH="$PWD/.build/ModuleCache"
export SWIFTPM_MODULECACHE_OVERRIDE="$CLANG_MODULE_CACHE_PATH"
args=(--disable-sandbox --disable-xctest --enable-swift-testing --scratch-path .build/engine-tests --cache-path .build/package-cache)
developer_dir="$(xcode-select -p)"
# Some Command Line Tools distributions include Testing without registering its
# framework and interoperability library search paths with SwiftPM.
if [[ -d "$developer_dir/Library/Developer/Frameworks/Testing.framework" ]]; then
    args+=(-Xswiftc -F -Xswiftc "$developer_dir/Library/Developer/Frameworks")
    args+=(-Xlinker -rpath -Xlinker "$developer_dir/Library/Developer/Frameworks")
    args+=(-Xlinker -rpath -Xlinker "$developer_dir/Library/Developer/usr/lib")
fi
swift test "${args[@]}" "$@"
