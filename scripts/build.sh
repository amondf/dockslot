#!/bin/zsh
# Compila para Apple Silicon e monta dist/DockSlot.app com assinatura ad-hoc.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release --arch arm64

app=dist/DockSlot.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$(swift build -c release --arch arm64 --show-bin-path)/DockSlot" "$app/Contents/MacOS/DockSlot"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp Resources/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
codesign --force --sign - --options runtime --identifier io.github.amondf.dockslot "$app"
echo "$app"
