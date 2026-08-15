# 🎬 play_140p - Complete Technical & User Documentation

`play_140p` is a high-performance terminal YouTube player and media utility written in **Nim**. Designed for extreme bandwidth efficiency, digital wellbeing, and seamless workflow integration.

---

## 🚀 Key Features

- ⚡ **Data Saver Mode (Default)**: Streams video at 144p/140p resolution at **1.5x speed** with auto English subtitles.
- 🧘 **Digital Wellbeing Control**: Automatically enforces a **60-minute daily watch limit** followed by a strict **4-hour cooldown lock**.
- 📋 **Zero-Typing Clipboard Auto-Detection**: Detects YouTube URLs from system clipboard on startup.
- 🖼️ **Terminal ANSI Thumbnail UI**: Interactive `fzf` search with live ASCII/ANSI graphics previews rendered via `chafa`.
- 🎙️ **Speech-to-Text Transcription**: Convert any video or voice recording to Hindi/English text (`play_140p transcribe <url/file>`).
- ⚡ **Auto-Dependency Installation**: Auto-detects Linux package managers (`apt`, `dnf`, `pacman`, `zypper`, `pip`) and installs missing tools on first run.

---

## 🛠️ CLI Usage & Examples

### 1. Basic Media Playback
```bash
# Play from clipboard link automatically
play_140p

# Play direct URL at 1.5x speed (default DataSaver)
play_140p "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

# Play at 2.0x speed in audio-only mode
play_140p "https://youtu.be/..." 2.0x audio

# Play in High Quality 1080p mode
play_140p "https://youtu.be/..." 1.0x hq
```

### 2. Interactive Search TUI
```bash
# Open fzf search menu with live thumbnail previews
play_140p "lofi hip hop"
```

### 3. Digital Wellbeing Status
```bash
# Check current watch time & cooldown status
play_140p status
```

### 4. Speech-to-Text Transcription
```bash
# Transcribe local audio or video file
play_140p transcribe ~/Music/voice_note.mp3

# Transcribe YouTube video directly
play_140p transcribe "https://youtu.be/..."
```

---

## 📊 Architecture & Configuration

- **Source Code**: [`play_140p.nim`](file:///home/narayanas/play_140p.nim)
- **Binary Location**: `~/.local/bin/play_140p`
- **Man Page**: `man play_140p`
- **Usage Tracker File**: `~/.config/play140p_usage.json`
