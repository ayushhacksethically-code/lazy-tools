#!/usr/bin/env bash
# ==============================================================================
#  Linux Packaging Script for lazy-tools (DEB, RPM & Universal Tarball)
# ==============================================================================

set -e

VERSION="1.0.0"
BUILD_DIR="dist"
PKG_NAME="lazy-tools"

echo "📦 Packaging lazy-tools v${VERSION} for Linux..."

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 1. Ensure binaries are compiled
nim c -d:release play_140p.nim
nim c -d:release audioconvert.nim
if [ -f "projects/lazy_vault/lazy_vault.nim" ]; then
    nim c -d:release projects/lazy_vault/lazy_vault.nim
fi

# 2. Build Universal Binary Tarball Archive
TAR_DIR="${BUILD_DIR}/${PKG_NAME}-${VERSION}-linux-x86_64"
mkdir -p "${TAR_DIR}/bin" "${TAR_DIR}/man/man1"

cp play_140p audioconvert "${TAR_DIR}/bin/"
if [ -f "projects/lazy_vault/lazy_vault" ]; then
    cp projects/lazy_vault/lazy_vault "${TAR_DIR}/bin/"
fi
cp install.sh README.md LICENSE "${TAR_DIR}/"
cp PLAY_140P_DOCUMENTATION.md AUDIOCONVERT_DOCUMENTATION.md "${TAR_DIR}/"

if [ -f "/home/narayanas/.local/share/man/man1/play_140p.1" ]; then
    cp /home/narayanas/.local/share/man/man1/play_140p.1 "${TAR_DIR}/man/man1/"
fi
if [ -f "/home/narayanas/.local/share/man/man1/audioconvert.1" ]; then
    cp /home/narayanas/.local/share/man/man1/audioconvert.1 "${TAR_DIR}/man/man1/"
fi

cd "$BUILD_DIR"
tar -czvf "${PKG_NAME}-${VERSION}-linux-x86_64.tar.gz" "${PKG_NAME}-${VERSION}-linux-x86_64"
cd ..

echo "✅ Universal Tarball Created: ${BUILD_DIR}/${PKG_NAME}-${VERSION}-linux-x86_64.tar.gz"

# 3. Build RPM Package if rpmbuild is available
if command -v rpmbuild >/dev/null 2>&1; then
    echo "⚙️ Building RPM package..."
    RPM_ROOT="${BUILD_DIR}/rpmbuild"
    mkdir -p "${RPM_ROOT}"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

    cat << EOF > "${RPM_ROOT}/SPECS/lazy-tools.spec"
Name:           lazy-tools
Version:        ${VERSION}
Release:        1%{?dist}
Summary:        Nim CLI Productivity Tools Suite (play_140p, audioconvert, lazy_vault)
License:        MIT
URL:            https://github.com/ayushhacksethically-code/lazy-tools

%description
A suite of lightweight, high-performance CLI tools written in Nim:
- play_140p: YouTube Media Player with Digital Wellbeing & Speech-to-Text
- audioconvert: Multi-core Parallel Audio Converter & Downloader
- lazy_vault: Ultra-Frictionless Password Manager & Emergency Recovery Vault

%install
mkdir -p %{buildroot}/usr/local/bin
mkdir -p %{buildroot}/usr/local/share/man/man1
cp $(pwd)/play_140p %{buildroot}/usr/local/bin/
cp $(pwd)/audioconvert %{buildroot}/usr/local/bin/
if [ -f "$(pwd)/projects/lazy_vault/lazy_vault" ]; then
    cp $(pwd)/projects/lazy_vault/lazy_vault %{buildroot}/usr/local/bin/
fi
if [ -f "$(pwd)/PLAY_140P_DOCUMENTATION.md" ]; then
    cp $(pwd)/PLAY_140P_DOCUMENTATION.md %{buildroot}/usr/local/share/man/man1/
fi

%files
/usr/local/bin/play_140p
/usr/local/bin/audioconvert
/usr/local/bin/lazy_vault
/usr/local/share/man/man1/PLAY_140P_DOCUMENTATION.md

%changelog
* Sat Aug 15 2026 Developer <dev@lazy-tools.org> - 1.0.0-1
- Initial Release
EOF

    rpmbuild --define "_topdir $(pwd)/${RPM_ROOT}" -bb "${RPM_ROOT}/SPECS/lazy-tools.spec" || true
    if [ -d "${RPM_ROOT}/RPMS" ]; then
        find "${RPM_ROOT}/RPMS" -name "*.rpm" -exec cp {} "${BUILD_DIR}/" \;
        echo "✅ RPM Package Created in ${BUILD_DIR}/"
    fi
fi

echo ""
echo "🎉 Linux Package Bundles Generated in ${BUILD_DIR}/ directory!"
