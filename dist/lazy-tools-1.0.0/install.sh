#!/usr/bin/env bash
# ==============================================================================
#  Installer Script for play_140p, audioconvert & lazy_vault
# ==============================================================================

set -e

echo "🚀 Installing play_140p, audioconvert & lazy_vault..."

INSTALL_BIN_DIR="$HOME/.local/bin"
INSTALL_MAN_DIR="$HOME/.local/share/man/man1"

mkdir -p "$INSTALL_BIN_DIR" "$INSTALL_MAN_DIR"

# 1. Compile Nim binaries if nim compiler is available
if command -v nim >/dev/null 2>&1; then
    echo "⚙️ Compiling Nim source files (release mode)..."
    nim c -d:release /home/narayanas/play_140p.nim
    nim c -d:release /home/narayanas/audioconvert.nim
    if [ -f "$(dirname "$0")/pdfcraft.nim" ]; then
        nim c -d:release "$(dirname "$0")/pdfcraft.nim"
    fi
    if [ -f "/home/narayanas/projects/lazy_vault/lazy_vault.nim" ]; then
        nim c -d:release /home/narayanas/projects/lazy_vault/lazy_vault.nim
    fi
fi

# 2. Copy binaries to ~/.local/bin safely
echo "📦 Installing binaries to $INSTALL_BIN_DIR..."
if [ -f "/home/narayanas/play_140p" ] && [ "$(realpath /home/narayanas/play_140p)" != "$(realpath "$INSTALL_BIN_DIR/play_140p" 2>/dev/null || echo "")" ]; then
    cp -f /home/narayanas/play_140p "$INSTALL_BIN_DIR/"
fi

if [ -f "/home/narayanas/audioconvert" ] && [ "$(realpath /home/narayanas/audioconvert)" != "$(realpath "$INSTALL_BIN_DIR/audioconvert" 2>/dev/null || echo "")" ]; then
    cp -f /home/narayanas/audioconvert "$INSTALL_BIN_DIR/"
fi

if [ -f "/home/narayanas/projects/lazy_vault/lazy_vault" ]; then
    if [ "$(realpath /home/narayanas/projects/lazy_vault/lazy_vault)" != "$(realpath "$INSTALL_BIN_DIR/lazy_vault" 2>/dev/null || echo "")" ]; then
        cp -f /home/narayanas/projects/lazy_vault/lazy_vault "$INSTALL_BIN_DIR/"
    fi
    ln -sf "$INSTALL_BIN_DIR/lazy_vault" "$INSTALL_BIN_DIR/v"
fi

if [ -f "$(dirname "$0")/pdfcraft" ]; then
    cp -f "$(dirname "$0")/pdfcraft" "$INSTALL_BIN_DIR/"
fi

chmod +x "$INSTALL_BIN_DIR/play_140p" "$INSTALL_BIN_DIR/audioconvert" "$INSTALL_BIN_DIR/pdfcraft" 2>/dev/null || true

# 3. Copy Man Pages safely
echo "📖 Installing man pages to $INSTALL_MAN_DIR..."
if [ -f "/home/narayanas/.local/share/man/man1/play_140p.1" ] && [ "$(realpath /home/narayanas/.local/share/man/man1/play_140p.1)" != "$(realpath "$INSTALL_MAN_DIR/play_140p.1" 2>/dev/null || echo "")" ]; then
    cp -f /home/narayanas/.local/share/man/man1/play_140p.1 "$INSTALL_MAN_DIR/"
fi

if [ -f "/home/narayanas/.local/share/man/man1/audioconvert.1" ] && [ "$(realpath /home/narayanas/.local/share/man/man1/audioconvert.1)" != "$(realpath "$INSTALL_MAN_DIR/audioconvert.1" 2>/dev/null || echo "")" ]; then
    cp -f /home/narayanas/.local/share/man/man1/audioconvert.1 "$INSTALL_MAN_DIR/"
fi

echo ""
echo "🎉 Setup complete! All tools installed successfully."
