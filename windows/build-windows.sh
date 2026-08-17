#!/bin/bash
set -euo pipefail

# Script to build Windows executable and distribution package
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
WINDOWS_DIR="${ROOT_DIR}/windows"
DIST_DIR="${ROOT_DIR}/dist"
PKG_DIR="${DIST_DIR}/MyBSD_Tomoyo_Explorer-win64"
ZIP_NAME="MyBSD_Tomoyo_Explorer-win64.zip"

echo "=== Building Windows Icon ==="
mkdir -p "${WINDOWS_DIR}"
if [ ! -f "${WINDOWS_DIR}/tomoyo.ico" ]; then
    python3 -c "from PIL import Image; img = Image.open('${ROOT_DIR}/ruby-BSD-Explorer/icons/winxp/mybsd.png'); img.save('${WINDOWS_DIR}/tomoyo.ico', format='ICO', sizes=[(16,16),(32,32),(48,48),(64,64),(128,128),(256,256)])"
fi

echo "=== Compiling Windows Resources & Executable ==="
cd "${WINDOWS_DIR}"
x86_64-w64-mingw32-windres tomoyo.rc -O coff -o tomoyo.res
x86_64-w64-mingw32-gcc -mwindows -O2 -s launcher.c tomoyo.res -o MyBSD_Tomoyo_Explorer.exe

echo "=== Assembling Windows Distribution Package ==="
rm -rf "${PKG_DIR}"
mkdir -p "${PKG_DIR}/share/bsd-explorer"
cp "${WINDOWS_DIR}/MyBSD_Tomoyo_Explorer.exe" "${PKG_DIR}/"
cp -r "${ROOT_DIR}/ruby-BSD-Explorer/"* "${PKG_DIR}/share/bsd-explorer/"
cp "${ROOT_DIR}/LICENSE" "${PKG_DIR}/LICENSE.txt"

cat << 'EOF' > "${PKG_DIR}/README.txt"
MyBSD Tomoyo Explorer (BSD Explorer)
=====================================
Original Author: Ariff Abdullah (skywizard@MyBSD.org.my)
MyBSD Project (http://www.MyBSD.org.my)
Maintainer: 9M2PJU <9m2pju@gmail.com>

Running on Windows
------------------
1. Double-click MyBSD_Tomoyo_Explorer.exe to start.
2. For complete graphical integration on modern Windows with X11 / Wayland,
   you can also run seamlessly in Windows Subsystem for Linux (WSL2):

   wsl curl -fsSL https://raw.githubusercontent.com/9M2PJU/MyBSD-Tomoyo-Explorer/master/install.sh | bash

Project Page: https://github.com/9M2PJU/MyBSD-Tomoyo-Explorer
EOF

echo "=== Creating Windows ZIP Archive ==="
cd "${DIST_DIR}"
rm -f "${ZIP_NAME}"
zip -r "${ZIP_NAME}" "MyBSD_Tomoyo_Explorer-win64"
cp "MyBSD_Tomoyo_Explorer-win64/MyBSD_Tomoyo_Explorer.exe" "${DIST_DIR}/MyBSD_Tomoyo_Explorer.exe"
rm -rf "${PKG_DIR}"

echo "=== Windows Package Built Successfully: ==="
ls -lh "${DIST_DIR}/${ZIP_NAME}" "${DIST_DIR}/MyBSD_Tomoyo_Explorer.exe"
