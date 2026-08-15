#!/usr/bin/env bash
# ==============================================================================
#  Universal Packaging Script for Each Tool (play_140p, audioconvert, lazy_vault)
# ==============================================================================

set -e

VERSION="1.0.0"
BUILD_DIR="dist"

echo "📦 Creating Universal Packages for Each Tool (v${VERSION})..."

mkdir -p "${BUILD_DIR}/individual"

# 1. Compile Binaries
nim c -d:release play_140p.nim
nim c -d:release audioconvert.nim
if [ -f "projects/lazy_vault/lazy_vault.nim" ]; then
    nim c -d:release projects/lazy_vault/lazy_vault.nim
fi

# 2. Package 1: play_140p Standalone Tarball & RPM
mkdir -p "${BUILD_DIR}/individual/play_140p-${VERSION}"
cp play_140p README.md LICENSE PLAY_140P_DOCUMENTATION.md "${BUILD_DIR}/individual/play_140p-${VERSION}/"
if [ -f "/home/narayanas/.local/share/man/man1/play_140p.1" ]; then
    cp /home/narayanas/.local/share/man/man1/play_140p.1 "${BUILD_DIR}/individual/play_140p-${VERSION}/"
fi
cd "${BUILD_DIR}/individual"
tar -czvf "play_140p-${VERSION}-linux-x86_64.tar.gz" "play_140p-${VERSION}"
cd ../..

# 3. Package 2: audioconvert Standalone Tarball & RPM
mkdir -p "${BUILD_DIR}/individual/audioconvert-${VERSION}"
cp audioconvert README.md LICENSE AUDIOCONVERT_DOCUMENTATION.md "${BUILD_DIR}/individual/audioconvert-${VERSION}/"
if [ -f "/home/narayanas/.local/share/man/man1/audioconvert.1" ]; then
    cp /home/narayanas/.local/share/man/man1/audioconvert.1 "${BUILD_DIR}/individual/audioconvert-${VERSION}/"
fi
cd "${BUILD_DIR}/individual"
tar -czvf "audioconvert-${VERSION}-linux-x86_64.tar.gz" "audioconvert-${VERSION}"
cd ../..

# 4. Package 3: lazy_vault Standalone Tarball & RPM
if [ -f "projects/lazy_vault/lazy_vault" ]; then
    mkdir -p "${BUILD_DIR}/individual/lazy_vault-${VERSION}"
    cp projects/lazy_vault/lazy_vault README.md LICENSE "${BUILD_DIR}/individual/lazy_vault-${VERSION}/"
    if [ -f "projects/lazy_vault/README.md" ]; then
        cp projects/lazy_vault/README.md "${BUILD_DIR}/individual/lazy_vault-${VERSION}/LAZY_VAULT_DOCUMENTATION.md"
    fi
    cd "${BUILD_DIR}/individual"
    tar -czvf "lazy_vault-${VERSION}-linux-x86_64.tar.gz" "lazy_vault-${VERSION}"
    cd ../..
fi

# 5. Full Suite Tarball
mkdir -p "${BUILD_DIR}/lazy-tools-${VERSION}"
cp play_140p audioconvert install.sh README.md LICENSE "${BUILD_DIR}/lazy-tools-${VERSION}/"
if [ -f "projects/lazy_vault/lazy_vault" ]; then
    cp projects/lazy_vault/lazy_vault "${BUILD_DIR}/lazy-tools-${VERSION}/"
fi
cd "${BUILD_DIR}"
tar -czvf "lazy-tools-${VERSION}-linux-x86_64.tar.gz" "lazy-tools-${VERSION}"
cd ..

echo "✅ All Standalone & Suite Packages Successfully Generated in ${BUILD_DIR}/"
