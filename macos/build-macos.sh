#!/bin/bash
set -euo pipefail

# Script to build macOS App Bundle and Distribution Package
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
MACOS_DIR="${ROOT_DIR}/macos"
DIST_DIR="${ROOT_DIR}/dist"
APP_NAME="MyBSD Tomoyo Explorer.app"
APP_BUNDLE="${DIST_DIR}/${APP_NAME}"
ZIP_NAME="MyBSD_Tomoyo_Explorer-macOS.zip"

echo "=== Generating macOS Icon ==="
mkdir -p "${MACOS_DIR}"
if [ ! -f "${MACOS_DIR}/tomoyo.icns" ]; then
    python3 -c "from PIL import Image; img = Image.open('${ROOT_DIR}/ruby-BSD-Explorer/icons/winxp/mybsd.png'); img.save('${MACOS_DIR}/tomoyo.icns', format='ICNS')"
fi

echo "=== Creating macOS App Bundle Structure ==="
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources/share/bsd-explorer"

# Info.plist
cat << 'EOF' > "${APP_BUNDLE}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>MyBSD Tomoyo Explorer</string>
    <key>CFBundleExecutable</key>
    <string>tomoyo-explorer</string>
    <key>CFBundleIconFile</key>
    <string>tomoyo.icns</string>
    <key>CFBundleIdentifier</key>
    <string>my.mybsd.tomoyo-explorer</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MyBSD Tomoyo Explorer</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.00-ALPHA</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.10</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# PkgInfo
echo -n "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

# Copy Icon
cp "${MACOS_DIR}/tomoyo.icns" "${APP_BUNDLE}/Contents/Resources/tomoyo.icns"

# Copy Tomoyo Explorer data files
cp -r "${ROOT_DIR}/ruby-BSD-Explorer/"* "${APP_BUNDLE}/Contents/Resources/share/bsd-explorer/"

# Launcher script
cat << 'EOF' > "${APP_BUNDLE}/Contents/MacOS/tomoyo-explorer"
#!/bin/bash
APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESOURCES="${APP_ROOT}/Resources"
SHARE_DIR="${RESOURCES}/share/bsd-explorer"

export EXPLORER_BASE="${SHARE_DIR}"

if [ -z "${DISPLAY:-}" ]; then
    export DISPLAY=":0"
fi

TARGET_DIR="${1:-$HOME}"

# If native Ruby GTK is available
if command -v ruby >/dev/null 2>&1 && ruby -e "require 'gtk'" 2>/dev/null; then
    exec ruby "${SHARE_DIR}/explorer_alone" "${TARGET_DIR}"
else
    RESP=$(osascript -e 'button returned of (display dialog "MyBSD Tomoyo Explorer\n\nTo run GTK+ 1.2 on macOS, please install XQuartz and a native Ruby with GTK 1.2 support:\n\nbrew install --cask xquartz\n\nVisit the project page for details." with title "MyBSD Tomoyo Explorer" buttons {"Cancel", "Open GitHub"} default button "Open GitHub" with icon note)' 2>/dev/null || echo "Cancel")
    if [ "$RESP" = "Open GitHub" ]; then
        open "https://github.com/9M2PJU/MyBSD-Tomoyo-Explorer"
    fi
fi
EOF
chmod +x "${APP_BUNDLE}/Contents/MacOS/tomoyo-explorer"

echo "=== Creating macOS ZIP Package ==="
cd "${DIST_DIR}"
rm -f "${ZIP_NAME}"
zip -r "${ZIP_NAME}" "${APP_NAME}"

echo "=== macOS Package Built Successfully: ==="
ls -lh "${DIST_DIR}/${ZIP_NAME}"
