#!/bin/zsh
set -e
cd "$(dirname "$0")"
APP=ChartFloat.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
FRAMEWORKS=(-framework Cocoa -framework WebKit -framework ScreenCaptureKit -framework AVFoundation)
swiftc -O -target arm64-apple-macos14.0 -o ChartFloat-arm64 main.swift "${FRAMEWORKS[@]}"
swiftc -O -target x86_64-apple-macos14.0 -o ChartFloat-x86_64 main.swift "${FRAMEWORKS[@]}"
lipo -create ChartFloat-arm64 ChartFloat-x86_64 -output "$APP/Contents/MacOS/ChartFloat"
rm -f ChartFloat-arm64 ChartFloat-x86_64
cp Info.plist "$APP/Contents/"
[ -f AppIcon.icns ] && cp AppIcon.icns "$APP/Contents/Resources/"
codesign --force --sign - "$APP"
echo "Built $APP"
