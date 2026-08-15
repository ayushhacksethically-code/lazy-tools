Name:           lazy-tools
Version:        1.0.0
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
cp /home/narayanas/projects/lazy-tools/play_140p %{buildroot}/usr/local/bin/
cp /home/narayanas/projects/lazy-tools/audioconvert %{buildroot}/usr/local/bin/
if [ -f "/home/narayanas/projects/lazy-tools/projects/lazy_vault/lazy_vault" ]; then
    cp /home/narayanas/projects/lazy-tools/projects/lazy_vault/lazy_vault %{buildroot}/usr/local/bin/
fi
if [ -f "/home/narayanas/projects/lazy-tools/PLAY_140P_DOCUMENTATION.md" ]; then
    cp /home/narayanas/projects/lazy-tools/PLAY_140P_DOCUMENTATION.md %{buildroot}/usr/local/share/man/man1/
fi

%files
/usr/local/bin/play_140p
/usr/local/bin/audioconvert
/usr/local/bin/lazy_vault
/usr/local/share/man/man1/PLAY_140P_DOCUMENTATION.md

%changelog
* Sat Aug 15 2026 Developer <dev@lazy-tools.org> - 1.0.0-1
- Initial Release
