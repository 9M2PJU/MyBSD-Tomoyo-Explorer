#!/bin/bash
set -euo pipefail

# Script to build standalone AppImage for MyBSD Tomoyo Explorer
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}"
BUILD_DIR="${ROOT_DIR}/build/appimage"
APPDIR="${BUILD_DIR}/AppDir"
OUTPUT_DIR="${ROOT_DIR}/dist"
OUTPUT_APPIMAGE="${OUTPUT_DIR}/MyBSD_Tomoyo_Explorer-x86_64.AppImage"

echo "=== Building Docker base image if needed ==="
if ! docker image inspect mybsd-tomoyo-explorer:latest >/dev/null 2>&1; then
    docker build -t mybsd-tomoyo-explorer:latest "${ROOT_DIR}"
fi

echo "=== Preparing AppDir structure ==="
rm -rf "${BUILD_DIR}"
mkdir -p "${APPDIR}/usr/bin"
mkdir -p "${APPDIR}/usr/lib/gdk-pixbuf"
mkdir -p "${APPDIR}/usr/share/bsd-explorer"
mkdir -p "${OUTPUT_DIR}"

echo "=== Extracting runtime and libraries from Docker image ==="
# Extract Ruby binary
docker run --rm mybsd-tomoyo-explorer:latest bash -c "cat /usr/bin/ruby1.8" > "${APPDIR}/usr/bin/ruby"
chmod +x "${APPDIR}/usr/bin/ruby"

# Extract shared libraries from /usr/lib (dereferencing symlinks)
docker run --rm mybsd-tomoyo-explorer:latest bash -c "tar -chC /usr/lib \
    libgtk-1.2.so.0 libgdk-1.2.so.0 libglib-1.2.so.0 libgmodule-1.2.so.0 \
    libgdk_pixbuf.so.2 libruby1.8.so.1.8 libXi.so.6 libXext.so.6 libXmu.so.6 \
    libXt.so.6 libSM.so.6 libICE.so.6 libX11.so.6 libXau.so.6 libXdmcp.so.6 \
    libpng12.so.0 libjpeg.so.62 libtiff.so.4 ruby" | tar -xC "${APPDIR}/usr/lib"

# Extract gdk-pixbuf loaders
docker run --rm mybsd-tomoyo-explorer:latest bash -c "tar -chC /usr/lib gdk-pixbuf" | tar -xC "${APPDIR}/usr/lib"

# Extract site_ruby
docker run --rm mybsd-tomoyo-explorer:latest bash -c "tar -chC /usr/local/lib site_ruby" | tar -xC "${APPDIR}/usr/lib"

# Extract /lib compatibility libraries
docker run --rm mybsd-tomoyo-explorer:latest bash -c "tar -chC /lib libcrypt.so.1 libncurses.so.5" | tar -xC "${APPDIR}/usr/lib"

echo "=== Copying Tomoyo Explorer files ==="
cp -r "${ROOT_DIR}/ruby-BSD-Explorer/"* "${APPDIR}/usr/share/bsd-explorer/"

# Extract compiled C extension gtk_fix.so
docker run --rm mybsd-tomoyo-explorer:latest bash -c "cat /usr/local/share/bsd-explorer/ruby-gtk-fix/gtk_fix.so" > "${APPDIR}/usr/share/bsd-explorer/ruby-gtk-fix/gtk_fix.so"
chmod +x "${APPDIR}/usr/share/bsd-explorer/ruby-gtk-fix/gtk_fix.so"

echo "=== Creating AppRun and Desktop Entry ==="
# AppRun
cat <<'EOF' > "${APPDIR}/AppRun"
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"

export APPDIR="${HERE}"
export EXPLORER_BASE="${HERE}/usr/share/bsd-explorer"
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${HERE}/usr/lib/gdk-pixbuf/loaders:${HERE}/usr/lib/site_ruby/1.8/x86_64-linux:${HERE}/usr/share/bsd-explorer/ruby-gtk-fix:${LD_LIBRARY_PATH:-}"
export RUBYLIB="${HERE}/usr/lib/ruby/1.8:${HERE}/usr/lib/ruby/1.8/x86_64-linux:${HERE}/usr/lib/site_ruby/1.8:${HERE}/usr/lib/site_ruby/1.8/x86_64-linux:${HERE}/usr/share/bsd-explorer:${RUBYLIB:-}"

# Minimal GTK 1.2 rc to prevent theme parser warnings from GTK 2/3 configs
export GTK_RC_FILES="${HERE}/usr/share/bsd-explorer/gtkrc"

TARGET_DIR="${1:-$PWD}"
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd || echo "$HOME")"

exec "${HERE}/usr/bin/ruby" "${HERE}/usr/share/bsd-explorer/explorer_alone" "${TARGET_DIR}"
EOF
chmod +x "${APPDIR}/AppRun"

# Clean GTK 1.2 gtkrc
cat <<'EOF' > "${APPDIR}/usr/share/bsd-explorer/gtkrc"
# Tomoyo Explorer GTK 1.2 Config
style "default"
{
  fontset = "-*-fixed-medium-r-normal-*-14-*-*-*-*-*-iso8859-1,-*-fixed-*-*-*-*-14-*-*-*-*-*-*-*,fixed"
}
class "GtkWidget" style "default"
EOF

# Desktop file
cat <<'EOF' > "${APPDIR}/tomoyo-explorer.desktop"
[Desktop Entry]
Name=MyBSD Tomoyo Explorer
GenericName=File Manager
Comment=Classic BSD/Unix Ruby GTK 1.2 File Manager
Exec=tomoyo-explorer %U
Icon=tomoyo-explorer
Terminal=false
Type=Application
Categories=System;FileManager;Utility;
StartupNotify=true
EOF

# Icons
cp "${ROOT_DIR}/ruby-BSD-Explorer/icons/winxp/mybsd.png" "${APPDIR}/tomoyo-explorer.png"
cp "${ROOT_DIR}/ruby-BSD-Explorer/icons/winxp/mybsd.png" "${APPDIR}/.DirIcon"

echo "=== Packaging AppImage ==="
if command -v appimagetool >/dev/null 2>&1; then
    ARCH=x86_64 appimagetool --no-appstream "${APPDIR}" "${OUTPUT_APPIMAGE}"
else
    if [ ! -d "${ROOT_DIR}/squashfs-root" ]; then
        echo "Downloading appimagetool..."
        curl -sSL -o "${ROOT_DIR}/appimagetool-x86_64.AppImage" https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
        chmod +x "${ROOT_DIR}/appimagetool-x86_64.AppImage"
        (cd "${ROOT_DIR}" && ./appimagetool-x86_64.AppImage --appimage-extract)
    fi
    ARCH=x86_64 "${ROOT_DIR}/squashfs-root/AppRun" --no-appstream "${APPDIR}" "${OUTPUT_APPIMAGE}"
fi

chmod +x "${OUTPUT_APPIMAGE}"

echo "=== Done! AppImage created at: ${OUTPUT_APPIMAGE} ==="
ls -lh "${OUTPUT_APPIMAGE}"
