#!/bin/bash
# Launcher for MyBSD Tomoyo Explorer

xhost +local:root >/dev/null 2>&1 || true

TARGET_DIR="${1:-$HOME}"

# Ensure absolute path
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd || echo "$HOME")"

exec docker run --rm -it \
  --name "tomoyo-explorer-$$" \
  -e "DISPLAY=${DISPLAY:-:0}" \
  -e "XAUTHORITY=/root/.Xauthority" \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v "${HOME}:/home/${USER}:rw" \
  -v "${TARGET_DIR}:/target:rw" \
  -w "/target" \
  mybsd-tomoyo-explorer:latest \
  ruby /usr/local/share/bsd-explorer/explorer_alone "/target"
