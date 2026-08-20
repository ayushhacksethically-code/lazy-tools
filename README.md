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

## ⚡ Quick One-Line Installation

```bash
chmod +x install.sh && ./install.sh
```

Or compile manually:
```bash
nim c -d:release play_140p.nim
nim c -d:release audioconvert.nim
cp play_140p audioconvert ~/.local/bin/
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
