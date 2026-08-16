Name:           lazy-tools
Version:        1.0.0
Release:        1%{?dist}
Summary:        Universal Nim CLI Suite (play_140p, audioconvert, lazy_vault)

License:        MIT
URL:            https://github.com/ayushhacksethically-code/lazy-tools
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz

BuildRequires:  nim
BuildRequires:  gcc
Requires:       ffmpeg

%description
Lazy Tools is a suite of lightweight, high-performance CLI applications written in Nim:
- play_140p: YouTube player TUI tuned for digital wellbeing
- audioconvert: Parallel multi-core audio converter and speech transcriber
- lazy_vault: Encrypted password & file vault

%prep
%autosetup -n lazy-tools-%{version}

%build
nim c -d:release play_140p.nim
nim c -d:release audioconvert.nim
nim c -d:release projects/lazy_vault/lazy_vault.nim

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_mandir}/man1

install -m 0755 play_140p %{buildroot}%{_bindir}/play_140p
install -m 0755 audioconvert %{buildroot}%{_bindir}/audioconvert
install -m 0755 projects/lazy_vault/lazy_vault %{buildroot}%{_bindir}/lazy_vault

if [ -f play_140p.1 ]; then
    install -m 0644 play_140p.1 %{buildroot}%{_mandir}/man1/play_140p.1
fi

%files
%license LICENSE
%doc README.md
%{_bindir}/play_140p
%{_bindir}/audioconvert
%{_bindir}/lazy_vault
%{_mandir}/man1/play_140p.1*

%changelog
* Sun Aug 16 2026 Maintainer <maintainer@example.com> - 1.0.0-1
- Initial Fedora COPR Release
