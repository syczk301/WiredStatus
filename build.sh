#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
python3 tools/sparkle/bootstrap.py
APP="build/Wired Status.app"
CACHE="${TMPDIR:-/tmp}/wired-status-module-cache"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" build/bin "$CACHE"
xcrun swift -module-cache-path "$CACHE" make-icon.swift build/AppIcon.iconset
/usr/bin/python3 pack-icon.py build/AppIcon.iconset "$APP/Contents/Resources/AppIcon.icns"
for ARCH in arm64 x86_64; do
  xcrun swiftc -swift-version 5 -O -target "$ARCH-apple-macosx13.0" -module-cache-path "$CACHE" \
    -F tools/sparkle/vendor -framework Sparkle -Xlinker -rpath -Xlinker @executable_path/../Frameworks -framework AppKit -framework SystemConfiguration -framework ServiceManagement Sources/*.swift \
    -o "build/bin/WiredStatus-$ARCH"
done
xcrun lipo -create build/bin/WiredStatus-arm64 build/bin/WiredStatus-x86_64 -output "$APP/Contents/MacOS/WiredStatus"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>WiredStatus</string>
<key>CFBundleIdentifier</key><string>local.czk.wiredstatus</string>
<key>CFBundleName</key><string>Wired Status</string>
<key>CFBundleDisplayName</key><string>有线状态</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.2.0</string>
<key>CFBundleVersion</key><string>6</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
python3 tools/sparkle/bootstrap.py "$APP"
codesign --force --sign - "$APP"
codesign --verify --strict "$APP"
echo "Built: $PWD/$APP"
