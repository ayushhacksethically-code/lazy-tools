# 🚀 Universal Nim CLI Productivity Tools Suite

> **Lightweight, Bandwidth-Efficient YouTube Player, Parallel Audio Converter, Speech Transcriber & Encrypted Vault in Nim**

A suite of blazing-fast, single-binary CLI applications for Linux built with **Nim**. Includes automatic multi-distro package manager detection (`apt`, `dnf`, `pacman`, `zypper`, `pip`) to resolve dependencies out of the box on any Linux distribution!

---

## 📦 Tools Included

### 1. 🎬 `play_140p`
- **YouTube Media Player & TUI** tuned for digital wellbeing & bandwidth efficiency.
- **Data Saver Mode (144p @ 1.5x speed)** with automated 60-minute daily watch cutoff & 4-hour cooldown lock.
- **Interactive TUI Search** with ANSI thumbnail graphic previews powered by `fzf` & `chafa`.
- **Speech-to-Text Integration**: Transcribe any video or voice recording to Hindi/English text (`play_140p transcribe <url/file>`).
- **Image Conversion & Processing**: Quick sub-wrapper integration for image conversions (`play_140p imgconvert` or `play_140p img`).

### 2. 🎵 `audioconvert`
- **Multi-Core Parallel Audio Converter & YouTube Downloader**.
- **Auto CPU Scaling**: Uses all system CPU cores (`countProcessors()`) for unlimited file batch conversions.
- **Multi-Format Support**: Extract and convert to `mp3`, `opus`, `m4a`, `wav`, `flac`, `aac`.
- **Built-in Speech Transcriber**: `audioconvert transcribe <file_or_url>`.

### 3. 📄 `pdfcraft`
- **All-in-One Fast Nim PDF Manipulation & Converter Suite**.
- **Comprehensive PDF Toolbox**: Merge, Split, Organize, Compress (GS), Repair, OCR (Tesseract/ocrmypdf), Convert (PDF to JPG/PNG, JPG to PDF, HTML to PDF, PDF to PDF/A, PDF to LLM Markdown), Watermark, Rotate, Protect & Unlock (Encrypt/Decrypt), and Side-by-side Visual PDF Compare.
- **Auto Dependency Resolution**: Automatically detects missing CLI tools (`qpdf`, `poppler-utils`, `tesseract-ocr`, `ghostscript`, `img2pdf`, `pandoc`, `diff-pdf`) and offers automatic distro-native package installation (`apt`, `dnf`, `pacman`, `zypper`).

### 4. 🔐 `lazy_vault` (`v`)
- **Fast CLI Password & File Vault** for terminal privacy and encrypted data management.

---

## 🐧 Linux Distro Support

Auto-detects and installs missing dependencies on:
- **Ubuntu / Debian / Mint / Pop!_OS** (`apt`)
- **Fedora / RHEL / CentOS** (`dnf`)
- **Arch Linux / Manjaro** (`pacman`)
- **openSUSE / Tumbleweed** (`zypper`)

---

## 📥 Installation Guide per Distribution

### ⚡ Option 1: Universal One-Line Automatic Install (All Distros)
Auto-detects package manager (`apt`, `dnf`, `pacman`, `zypper`), resolves dependencies, and installs binaries to `~/.local/bin/`:
```bash
curl -fsSL https://raw.githubusercontent.com/ayushhacksethically-code/lazy-tools/main/install.sh | bash
```

---

### 📦 Option 2: Distro-Specific Native Packages (GitHub Releases)

#### 🟠 Ubuntu / Debian / Mint / Pop!_OS (`.deb`)
Download the `.deb` package from [Releases](https://github.com/ayushhacksethically-code/lazy-tools/releases) and install:
```bash
sudo apt update
sudo apt install ./lazy-tools_1.0.0_amd64.deb
```

#### 🔵 Fedora / RHEL / CentOS (`.rpm`)
Download the `.rpm` package from [Releases](https://github.com/ayushhacksethically-code/lazy-tools/releases) and install:
```bash
sudo dnf install ./lazy-tools-1.0.0-1.x86_64.rpm
```

#### 🟢 Arch Linux / Manjaro (`makepkg`)
Clone the repository and build via `PKGBUILD`:
```bash
git clone https://github.com/ayushhacksethically-code/lazy-tools.git
cd lazy-tools/aur/play_140p
makepkg -si
```

#### 🦎 openSUSE / Tumbleweed (`.rpm` / `.tar.gz`)
Download `.tar.gz` standalone binary or install `.rpm` package:
```bash
sudo zypper install ./lazy-tools-1.0.0-1.x86_64.rpm
```

---

### 🛠️ Option 3: Manual Build from Source (Nim Compiler)
```bash
git clone https://github.com/ayushhacksethically-code/lazy-tools.git
cd lazy-tools
nim c -d:release play_140p.nim
nim c -d:release audioconvert.nim
nim c -d:release pdfcraft.nim
nim c -d:release projects/lazy_vault/lazy_vault.nim
mkdir -p ~/.local/bin
cp play_140p audioconvert pdfcraft projects/lazy_vault/lazy_vault ~/.local/bin/
```

---

## 📖 Usage Examples

```bash
# 1. Play YouTube from Clipboard or Query
play_140p "lofi hip hop" 1.5x audio

# 2. Transcribe Audio/Video (Local or URL) to Text
play_140p transcribe "/path/to/voice_recording.mp3"
play_140p transcribe "https://youtu.be/..."

# 3. Image Conversion & Processing via play_140p
play_140p imgconvert -i:image.png -o:output.webp
play_140p img -i:input.jpg -o:output.png --quality:90

# 4. Batch Convert Unlimited Files in Parallel
audioconvert f1.mp4 f2.mkv f3.webm -f:mp3 -o:~/Music

# 4. View Built-in Man Pages
man audioconvert
man play_140p
```

---

## 📄 License
[MIT](LICENSE) © 2026
