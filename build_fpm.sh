#!/usr/bin/env bash
# ==============================================================================
#  Universal FPM Package Generator for play_140p, audioconvert, lazy_vault
#  Outputs: DEB (.deb), RPM (.rpm), Arch (.pkg.tar.zst) via FPM
# ==============================================================================

set -e

VERSION="1.0.0"
BUILD_DIR="dist/fpm_packages"

echo "⚙️ Building Binaries with Nim (release mode)..."
nim c -d:release play_140p.nim
nim c -d:release audioconvert.nim
if [ -f "projects/lazy_vault/lazy_vault.nim" ]; then
    nim c -d:release projects/lazy_vault/lazy_vault.nim
fi

mkdir -p "${BUILD_DIR}"
rm -rf tmp_pkg_tree
mkdir -p tmp_pkg_tree/usr/local/bin tmp_pkg_tree/usr/local/share/man/man1

echo "📦 Preparing Filesystem Tree for FPM..."
cp play_140p audioconvert tmp_pkg_tree/usr/local/bin/
if [ -f "projects/lazy_vault/lazy_vault" ]; then
    cp projects/lazy_vault/lazy_vault tmp_pkg_tree/usr/local/bin/
    ln -sf lazy_vault tmp_pkg_tree/usr/local/bin/v 2>/dev/null || true
fi

# Copy Man pages
if [ -f "/home/narayanas/.local/share/man/man1/play_140p.1" ]; then
    cp /home/narayanas/.local/share/man/man1/play_140p.1 tmp_pkg_tree/usr/local/share/man/man1/
fi
if [ -f "/home/narayanas/.local/share/man/man1/audioconvert.1" ]; then
    cp /home/narayanas/.local/share/man/man1/audioconvert.1 tmp_pkg_tree/usr/local/share/man/man1/
fi

cd "${BUILD_DIR}"

echo "🚀 Generating DEB Packages using FPM..."
# 1. Full Suite DEB
fpm -s dir -t deb -n lazy-tools -v "${VERSION}" --description "Universal Nim CLI Suite (play_140p, audioconvert, lazy_vault)" -C "../../tmp_pkg_tree" .

# 2. Standalone DEBs
mkdir -p tmp_play140p/usr/local/bin
cp "../../play_140p" tmp_play140p/usr/local/bin/
fpm -s dir -t deb -n play_140p -v "${VERSION}" --description "YouTube player TUI tuned for digital wellbeing" -C tmp_play140p .
rm -rf tmp_play140p

mkdir -p tmp_audioconvert/usr/local/bin
cp "../../audioconvert" tmp_audioconvert/usr/local/bin/
fpm -s dir -t deb -n audioconvert -v "${VERSION}" --description "Parallel multi-core audio converter and speech transcriber" -C tmp_audioconvert .
rm -rf tmp_audioconvert

if [ -f "../../projects/lazy_vault/lazy_vault" ]; then
    mkdir -p tmp_lazyvault/usr/local/bin
    cp "../../projects/lazy_vault/lazy_vault" tmp_lazyvault/usr/local/bin/
    fpm -s dir -t deb -n lazy_vault -v "${VERSION}" --description "Encrypted password & file vault" -C tmp_lazyvault .
    rm -rf tmp_lazyvault
fi

echo "🚀 Generating RPM Packages using FPM..."
# 1. Full Suite RPM
fpm -s dir -t rpm -n lazy-tools -v "${VERSION}" --description "Universal Nim CLI Suite (play_140p, audioconvert, lazy_vault)" -C "../../tmp_pkg_tree" .

# 2. Standalone RPMs
mkdir -p tmp_play140p/usr/local/bin
cp "../../play_140p" tmp_play140p/usr/local/bin/
fpm -s dir -t rpm -n play_140p -v "${VERSION}" --description "YouTube player TUI tuned for digital wellbeing" -C tmp_play140p .
rm -rf tmp_play140p

mkdir -p tmp_audioconvert/usr/local/bin
cp "../../audioconvert" tmp_audioconvert/usr/local/bin/
fpm -s dir -t rpm -n audioconvert -v "${VERSION}" --description "Parallel multi-core audio converter and speech transcriber" -C tmp_audioconvert .
rm -rf tmp_audioconvert

if [ -f "../../projects/lazy_vault/lazy_vault" ]; then
    mkdir -p tmp_lazyvault/usr/local/bin
    cp "../../projects/lazy_vault/lazy_vault" tmp_lazyvault/usr/local/bin/
    fpm -s dir -t rpm -n lazy_vault -v "${VERSION}" --description "Encrypted password & file vault" -C tmp_lazyvault .
    rm -rf tmp_lazyvault
fi

cd ../..
rm -rf tmp_pkg_tree

echo "🎉 All DEB & RPM Packages Successfully Generated via FPM!"
