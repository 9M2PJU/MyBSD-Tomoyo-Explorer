#!/usr/bin/env bash
# MyBSD Tomoyo Explorer Universal 1-Liner Installer
# Supports: Linux (x86_64 AppImage), Arch Linux (AUR), FreeBSD, and macOS
set -euo pipefail

REPO="9M2PJU/MyBSD-Tomoyo-Explorer"
TAG="v1.00-ALPHA"
APPIMAGE_NAME="MyBSD_Tomoyo_Explorer-x86_64.AppImage"
RELEASE_URL="https://github.com/${REPO}/releases/download/${TAG}/${APPIMAGE_NAME}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}=== Installing MyBSD Tomoyo Explorer (${TAG}) ===${NC}"

# Detect OS and Architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

INSTALL_PREFIX="${HOME}/.local"
BIN_DIR="${INSTALL_PREFIX}/bin"
APP_DIR="${INSTALL_PREFIX}/share/applications"
ICON_DIR="${INSTALL_PREFIX}/share/icons/hicolor/48x48/apps"

mkdir -p "${BIN_DIR}" "${APP_DIR}" "${ICON_DIR}"

if [ "${OS}" = "Linux" ]; then
    if [ "${ARCH}" = "x86_64" ]; then
        echo -e "${GREEN}Detected Linux x86_64.${NC} Downloading standalone AppImage..."
        TARGET_BIN="${BIN_DIR}/tomoyo-explorer"
        
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL -o "${TARGET_BIN}" "${RELEASE_URL}"
        elif command -v wget >/dev/null 2>&1; then
            wget -qO "${TARGET_BIN}" "${RELEASE_URL}"
        else
            echo -e "${RED}Error: curl or wget required.${NC}" >&2
            exit 1
        fi
        
        chmod +x "${TARGET_BIN}"
        ln -sf "${TARGET_BIN}" "${BIN_DIR}/bsd-explorer"

        # Extract icon and desktop file
        echo -e "${GREEN}Configuring Desktop Entry and Icons...${NC}"
        TEMP_DIR="$(mktemp -d)"
        (
            cd "${TEMP_DIR}"
            "${TARGET_BIN}" --appimage-extract tomoyo-explorer.png >/dev/null 2>&1 || true
            if [ -f squashfs-root/tomoyo-explorer.png ]; then
                cp squashfs-root/tomoyo-explorer.png "${ICON_DIR}/tomoyo-explorer.png"
            fi
        )
        rm -rf "${TEMP_DIR}"

    else
        echo -e "${RED}Error: No native build is available for Linux ${ARCH}.${NC}" >&2
        echo -e "${BLUE}The standalone AppImage is only built for x86_64.${NC}" >&2
        echo -e "${BLUE}Alternatively, install from source on a system with Ruby 1.8 and GTK 1.2.${NC}" >&2
        exit 1
    fi

    # Create Desktop Entry
    cat << 'EOF' > "${APP_DIR}/tomoyo-explorer.desktop"
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

elif [ "${OS}" = "Darwin" ]; then
    echo -e "${GREEN}Detected macOS (${ARCH}).${NC} Installing MyBSD Tomoyo Explorer.app..."
    if ! command -v unzip >/dev/null 2>&1; then
        echo -e "${RED}Error: unzip is required but was not found.${NC}" >&2
        echo -e "${BLUE}Install the Command Line Tools with: xcode-select --install${NC}" >&2
        exit 1
    fi
    MAC_APP_DIR="${HOME}/Applications"
    mkdir -p "${MAC_APP_DIR}"
    
    ZIP_URL="https://github.com/${REPO}/releases/download/${TAG}/MyBSD_Tomoyo_Explorer-macOS.zip"
    TEMP_DIR="$(mktemp -d)"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "${TEMP_DIR}/macos.zip" "${ZIP_URL}"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "${TEMP_DIR}/macos.zip" "${ZIP_URL}"
    else
        echo -e "${RED}Error: curl or wget required.${NC}" >&2
        exit 1
    fi
    unzip -qo "${TEMP_DIR}/macos.zip" -d "${MAC_APP_DIR}"
    rm -rf "${TEMP_DIR}"
    
    ln -sf "${MAC_APP_DIR}/MyBSD Tomoyo Explorer.app/Contents/MacOS/tomoyo-explorer" "${BIN_DIR}/tomoyo-explorer"
    ln -sf "${BIN_DIR}/tomoyo-explorer" "${BIN_DIR}/bsd-explorer"
    
    echo -e "${GREEN}Installed to: ${MAC_APP_DIR}/MyBSD Tomoyo Explorer.app${NC}"
    if [ ! -d "/Applications/Utilities/XQuartz.app" ] && [ ! -d "/Applications/XQuartz.app" ]; then
        echo -e "${BLUE}Note: For X11 graphical output on macOS, XQuartz is recommended:${NC}"
        echo "  brew install --cask xquartz"
    fi

elif [ "${OS}" = "FreeBSD" ]; then
    echo -e "${GREEN}Detected FreeBSD.${NC} Installing Tomoyo Explorer..."
    INSTALL_DIR="${HOME}/.local/share/bsd-explorer"
    mkdir -p "${INSTALL_DIR}"

    echo "Downloading BSD Explorer source archive..."
    TARBALL_URL="https://github.com/${REPO}/releases/download/${TAG}/bsd-explorer-${TAG}.tar.gz"
    TEMP_DIR="$(mktemp -d)"
    fetch -o "${TEMP_DIR}/bsd-explorer.tar.gz" "${TARBALL_URL}" 2>/dev/null || curl -fsSL -o "${TEMP_DIR}/bsd-explorer.tar.gz" "${TARBALL_URL}"
    tar -xzf "${TEMP_DIR}/bsd-explorer.tar.gz" -C "${TEMP_DIR}"
    cp -r "${TEMP_DIR}/bsd-explorer-${TAG}/"* "${INSTALL_DIR}/"
    rm -rf "${TEMP_DIR}"

    # Build ruby-gtk-fix if ruby is available
    if command -v ruby >/dev/null 2>&1; then
        (cd "${INSTALL_DIR}/ruby-gtk-fix" && ruby extconf.rb && make 2>/dev/null || true)
    fi

    cat << EOF > "${BIN_DIR}/tomoyo-explorer"
#!/usr/bin/env bash
export EXPLORER_BASE="${INSTALL_DIR}"
exec ruby "${INSTALL_DIR}/explorer_alone" "\${1:-\$PWD}"
EOF
    chmod +x "${BIN_DIR}/tomoyo-explorer"
    ln -sf "${BIN_DIR}/tomoyo-explorer" "${BIN_DIR}/bsd-explorer"

    if [ -f "${INSTALL_DIR}/icons/winxp/mybsd.png" ]; then
        cp "${INSTALL_DIR}/icons/winxp/mybsd.png" "${ICON_DIR}/tomoyo-explorer.png"
    fi

    # Create Desktop Entry
    cat << 'EOF' > "${APP_DIR}/tomoyo-explorer.desktop"
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
fi

# Ensure ~/.local/bin is in PATH notification
echo ""
echo -e "${GREEN}${BOLD}✓ MyBSD Tomoyo Explorer successfully installed!${NC}"
echo -e "Binary location: ${BOLD}${BIN_DIR}/tomoyo-explorer${NC}"
echo -e "Symlink:         ${BOLD}${BIN_DIR}/bsd-explorer${NC}"
echo ""
if [[ ":$PATH:" != *":${BIN_DIR}:"* ]]; then
    echo -e "${BLUE}Tip: Add ~/.local/bin to your PATH by adding this to ~/.bashrc or ~/.zshrc:${NC}"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
fi
if [ "${OS}" = "Darwin" ]; then
    echo -e "Run with: ${BOLD}tomoyo-explorer ~/${NC} or open ${BOLD}MyBSD Tomoyo Explorer.app${NC} from ~/Applications."
else
    echo -e "Run with: ${BOLD}tomoyo-explorer ~/${NC} or launch from your Application Menu."
fi
