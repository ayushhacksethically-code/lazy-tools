# 🎵 audioconvert - Complete Technical & User Documentation

`audioconvert` is a high-performance command-line utility written in **Nim** for multi-core parallel audio conversion, online media downloading, and speech-to-text transcription.

---

## 🚀 Key Features

- ⚡ **Auto CPU Core Scaling**: Uses all system CPU cores (`countProcessors()`) for maximum parallel worker throughput.
- ♾️ **Unlimited Batch Conversions**: Process unlimited files or entire directory trees recursively (`-r`).
- 🎵 **Multi-Format Extraction**: Convert to `mp3`, `opus`, `m4a`, `wav`, `flac`, `aac`.
- 📥 **Web Media Downloading**: Download and extract audio directly from YouTube, Vimeo, Twitch, and SoundCloud URLs via `yt-dlp`.
- 🎙️ **Speech Transcriber Integration**: Transcribe audio to Hindi/English text (`audioconvert transcribe <file_or_url>`).
- 📦 **Auto-Dependency Installation**: Auto-installs missing dependencies (`ffmpeg`, `yt-dlp`, `speech_recognition`) via `apt`, `dnf`, `pacman`, `zypper`, or `pip`.

---

## 🛠️ CLI Usage & Examples

### 1. File Conversion
```bash
# Simple single file conversion (default mp3 192k)
audioconvert song.mp4

# Custom format & bitrate
audioconvert video.mkv -f:m4a -b:320k

# Speed adjustment (1.5x tempo pitch-corrected)
audioconvert podcast.mp3 -s:1.5
```

### 2. Multi-File Parallel Conversion
```bash
# Convert 5 files simultaneously using max CPU cores
audioconvert f1.mp4 f2.mkv f3.webm f4.wav f5.mov

# Batch convert an entire folder recursively
audioconvert -r ~/Videos/ -f:mp3 -o:~/Music
```

### 3. Audio Downloading & Transcription
```bash
# Direct YouTube URL Audio Download
audioconvert "https://youtu.be/..."

# Speech-to-text transcription
audioconvert transcribe audio_recording.mp3
```

---

## 📊 Architecture & Configuration

- **Source Code**: [`audioconvert.nim`](file:///home/narayanas/audioconvert.nim)
- **Binary Location**: `~/.local/bin/audioconvert`
- **Man Page**: `man audioconvert`
