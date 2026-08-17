# MyBSD Tomoyo Explorer

[![Release](https://img.shields.io/github/v/release/9M2PJU/MyBSD-Tomoyo-Explorer?style=flat-square&color=blue)](https://github.com/9M2PJU/MyBSD-Tomoyo-Explorer/releases)
[![AUR version](https://img.shields.io/aur/version/tomoyo-explorer-bin?style=flat-square&color=orange)](https://aur.archlinux.org/packages/tomoyo-explorer-bin)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20FreeBSD-lightgrey?style=flat-square)](#)
[![License](https://img.shields.io/badge/license-BSD--2--Clause-green?style=flat-square)](LICENSE)

**MyBSD Tomoyo Explorer** (originally known as **BSD Explorer**) is a classic BSD/Unix graphical desktop file manager written in Ruby with GTK+ 1.2 and GdkPixbuf. Originally developed in 2002 by **Ariff Abdullah** (*skywizard*) for the **MyBSD** project.

![MyBSD Tomoyo Explorer](screenshots/mybsd-tomoyo-explorer.png)

---

## ⚡ 1-Liner Quick Install

Install on **Linux** (x86_64, arm64) or **FreeBSD** with one command:

```bash
curl -fsSL https://raw.githubusercontent.com/9M2PJU/MyBSD-Tomoyo-Explorer/master/install.sh | bash
```

This will install `tomoyo-explorer` into `~/.local/bin/` and configure your desktop application menu entry with icons.

---

## 📦 Installation Options

### 1. Arch Linux (AUR)

Install via your preferred AUR helper:

```bash
# Using yay
yay -S tomoyo-explorer-bin

# Using paru
paru -S tomoyo-explorer-bin
```

Or clone and build manually:
```bash
git clone https://aur.archlinux.org/tomoyo-explorer-bin.git
cd tomoyo-explorer-bin
makepkg -si
```

---

### 2. Standalone Linux AppImage (x86_64 / amd64)

Download the portable AppImage from [GitHub Releases](../../releases):

```bash
# Download and make executable
curl -LO https://github.com/9M2PJU/MyBSD-Tomoyo-Explorer/releases/download/v1.00-ALPHA/MyBSD_Tomoyo_Explorer-x86_64.AppImage
chmod +x MyBSD_Tomoyo_Explorer-x86_64.AppImage

# Run
./MyBSD_Tomoyo_Explorer-x86_64.AppImage ~/
```

> **Note:** The AppImage bundles the complete Ruby 1.8 interpreter, GTK+ 1.2, GdkPixbuf loaders, and compiled `ruby-gtk-fix` C extension. It runs out-of-the-box on modern Linux distributions without any legacy dependencies required on the host system.

---

### 3. FreeBSD Installation

On FreeBSD, install dependencies and set up Tomoyo Explorer:

```bash
# Install Ruby and GTK 1.2 libraries
pkg install ruby18 ruby-gtk graphics/ruby-gdk_pixbuf

# Download and run via 1-liner installer
curl -fsSL https://raw.githubusercontent.com/9M2PJU/MyBSD-Tomoyo-Explorer/master/install.sh | bash
```

Or using the included FreeBSD port skeleton:
```bash
cd freebsd/
make install clean
```

---

### 4. Docker / Container Environment (amd64 / arm64)

A containerized environment is provided for easy local execution and development:

```bash
# Build the container image
docker build -t mybsd-tomoyo-explorer:latest .

# Run with X11 display forwarding
./run-tomoyo-explorer.sh ~/
```

---

## 🛠️ Building & Packaging

### Building the Linux AppImage
```bash
chmod +x build-appimage.sh
./build-appimage.sh
```
The resulting executable AppImage will be placed in `dist/MyBSD_Tomoyo_Explorer-x86_64.AppImage`.

---

## 📂 Repository Contents

| Directory / File | Description |
| :--- | :--- |
| [`ruby-BSD-Explorer/`](ruby-BSD-Explorer/) | Tomoyo Explorer `v1.00-ALPHA` ("Yamato Nadeshiko") Ruby source code, C fixes, and icon sets. |
| [`aur/tomoyo-explorer-bin/`](aur/tomoyo-explorer-bin/) | Official Arch User Repository (AUR) package files (`PKGBUILD`, `.SRCINFO`). |
| [`freebsd/`](freebsd/) | FreeBSD port `Makefile`, `pkg-descr`, and `pkg-plist`. |
| [`gelojoh-current/`](gelojoh-current/) | Historical Gelojoh HTTP/SSL server in Ruby. |
| [`IPv6/`](IPv6/) | IPv6 test chat server/clients and RFC drafts. |
| [`Dockerfile`](Dockerfile) | Multi-stage Docker environment for Ruby 1.8 + GTK 1.2. |
| [`build-appimage.sh`](build-appimage.sh) | Automated standalone AppImage packager. |
| [`install.sh`](install.sh) | Universal 1-liner install script. |

---

## 📜 Credits & Attribution

- **Original Author:** Ariff Abdullah a.k.a. *skywizard* (`skywizard@MyBSD.org.my`) and the MyBSD Project Team.
- **Original Release:** `1.00-ALPHA` ("Yamato Nadeshiko", 2002-02-26).
- **Maintenance & Modern Packaging:** [9M2PJU](https://github.com/9M2PJU).

---

## 📄 License

This project is licensed under the **BSD 2-Clause License**. See the [`LICENSE`](LICENSE) file for details.
