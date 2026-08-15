import std/[os, strutils, osproc, json, random, times]

type
  PkgManager = enum
    pmDnf, pmApt, pmPacman, pmZypper, pmUnknown

proc detectPkgManager(): PkgManager =
  if findExe("dnf") != "": return pmDnf
  if findExe("apt-get") != "" or findExe("apt") != "": return pmApt
  if findExe("pacman") != "": return pmPacman
  if findExe("zypper") != "": return pmZypper
  return pmUnknown

proc installSystemPackage(pkgName: string): bool =
  let pm = detectPkgManager()
  var cmd = ""
  var pmName = ""
  case pm
  of pmDnf:
    pmName = "dnf"
    cmd = "sudo dnf install -y " & quoteShell(pkgName)
  of pmApt:
    pmName = "apt"
    cmd = "sudo apt update && sudo apt install -y " & quoteShell(pkgName)
  of pmPacman:
    pmName = "pacman"
    cmd = "sudo pacman -S --noconfirm " & quoteShell(pkgName)
  of pmZypper:
    pmName = "zypper"
    cmd = "sudo zypper install -y " & quoteShell(pkgName)
  of pmUnknown:
    echo "❌ Unknown package manager. Please manually install: ", pkgName
    return false

  echo "📦 Detected system package manager: ", pmName
  stdout.write "❓ Do you want to automatically install '" & pkgName & "' using " & pmName & "? [Y/n]: "
  stdout.flushFile()
  var resp = ""
  try:
    resp = readLine(stdin).strip().toLowerAscii()
  except EOFError:
    resp = "y"

  if resp == "" or resp == "y" or resp == "yes":
    echo "⚙️ Running installation: ", cmd
    let exitCode = execCmd(cmd)
    if exitCode == 0:
      echo "✅ Successfully installed ", pkgName
      return true
    else:
      echo "❌ Failed to install ", pkgName, " (exit code ", exitCode, ")"
      return false
  else:
    echo "Installation cancelled by user."
    return false

proc checkPythonModule(modName: string): bool =
  let pyCmd = findExe("python3")
  if pyCmd == "": return false
  let (_, code) = execCmdEx(quoteShell(pyCmd) & " -c \"import " & modName & "\"")
  return code == 0

proc installPythonPackage(pkgName: string): bool =
  let pyCmd = findExe("python3")
  if pyCmd == "":
    echo "❌ python3 not found."
    return false

  var pipCmd = findExe("pip3")
  if pipCmd == "": pipCmd = findExe("pip")

  if pipCmd == "":
    echo "⚠️ 'pip' not found. Attempting to install 'python3-pip'..."
    discard installSystemPackage("python3-pip")
    pipCmd = findExe("pip3")
    if pipCmd == "": pipCmd = findExe("pip")

  var installCmd = ""
  if pipCmd != "":
    installCmd = quoteShell(pipCmd) & " install " & quoteShell(pkgName)
  else:
    installCmd = quoteShell(pyCmd) & " -m pip install " & quoteShell(pkgName)

  echo "📦 Detected Python package installer: pip"
  stdout.write "❓ Do you want to automatically install Python package '" & pkgName & "' via pip? [Y/n]: "
  stdout.flushFile()
  var resp = ""
  try:
    resp = readLine(stdin).strip().toLowerAscii()
  except EOFError:
    resp = "y"

  if resp == "" or resp == "y" or resp == "yes":
    echo "⚙️ Running installation: ", installCmd
    let exitCode = execCmd(installCmd)
    if exitCode == 0:
      echo "✅ Successfully installed Python package ", pkgName
      return true
    else:
      echo "❌ Failed to install Python package ", pkgName
      return false
  else:
    echo "Installation cancelled by user."
    return false

proc ensureExe(exeName: string, pkgName: string = ""): bool =
  if findExe(exeName) != "":
    return true
  let actualPkg = if pkgName != "": pkgName else: exeName
  echo "⚠️ Missing required tool: '", exeName, "'"
  return installSystemPackage(actualPkg) and findExe(exeName) != ""

proc ensurePythonSpeechRecognition(): bool =
  if checkPythonModule("speech_recognition") or checkPythonModule("whisper"):
    return true
  echo "⚠️ Missing Python module for speech recognition ('speech_recognition' or 'whisper')."
  return installPythonPackage("SpeechRecognition") and (checkPythonModule("speech_recognition") or checkPythonModule("whisper"))

type
  PlayMode = enum
    modeDataSaver,  # 144p + 1.5x
    modeAudioOnly,  # No video + 1.5x
    modeHighQuality # Best video + 1.0x

# Digital Wellbeing / Addiction Control Constants
const
  MAX_WATCH_SECONDS = 3600       # 60 minutes max continuous usage
  COOLDOWN_SECONDS  = 14400      # 4 hours strict cooldown lock
  USAGE_LOG_FILE    = "play140p_usage.json"

proc getUsageLogPath(): string =
  return getHomeDir() / ".config" / USAGE_LOG_FILE

proc checkDigitalWellbeing(): bool =
  let logPath = getUsageLogPath()
  let now = getTime().toUnix()

  if not fileExists(logPath):
    return true

  try:
    let data = parseJson(readFile(logPath))
    let totalSecs = data.getOrDefault("session_seconds").getInt(0)
    let lockUntil = data.getOrDefault("locked_until").getInt(0)

    if now < lockUntil:
      let remainingSecs = lockUntil - now
      let remHours = (remainingSecs div 3600)
      let remMins = (remainingSecs mod 3600) div 60
      echo "\n🛑 [ADDICTION CONTROL LOCK ACTIVE]"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "⏰ Aapne 60 min (1 Ghanta) YouTube use kar liya hai!"
      echo "🔒 System 4 ghante ke liye locked hai taaki aapka time waste na ho."
      echo "⏳ Remaining Cooldown Time: ", remHours, " Ghante ", remMins, " Minutes."
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
      return false
    elif lockUntil != 0 and now >= lockUntil:
      # Cooldown expired! Reset tracker cleanly
      let resetNode = %*{
        "session_start": now,
        "session_seconds": 0,
        "locked_until": 0
      }
      writeFile(logPath, $resetNode)
      return true
    elif totalSecs >= MAX_WATCH_SECONDS:
      # Lock for 4 hours starting now
      let newLockUntil = now + COOLDOWN_SECONDS
      let node = %*{
        "session_start": now,
        "session_seconds": totalSecs,
        "locked_until": newLockUntil
      }
      writeFile(logPath, $node)
      echo "\n🛑 60 Minutes Daily Limit Reached! Locking for 4 hours."
      return false
  except:
    discard

  return true

proc updateUsageTime(durationSecs: int) =
  let logPath = getUsageLogPath()
  let now = getTime().toUnix()
  var sessionStart = now
  var totalSecs = 0

  if fileExists(logPath):
    try:
      let data = parseJson(readFile(logPath))
      sessionStart = data.getOrDefault("session_start").getInt(now)
      totalSecs = data.getOrDefault("session_seconds").getInt(0)
    except: discard

  # Reset session counter if last activity was more than 4 hours ago
  if (now - sessionStart) > COOLDOWN_SECONDS and totalSecs < MAX_WATCH_SECONDS:
    sessionStart = now
    totalSecs = 0

  totalSecs += durationSecs
  var lockUntil = 0

  if totalSecs >= MAX_WATCH_SECONDS:
    lockUntil = now + COOLDOWN_SECONDS
    echo "\n⚠️ [ADDICTION WARNING] 60 minutes limit reached! App locked for 4 hours."

  let node = %*{
    "session_start": sessionStart,
    "session_seconds": totalSecs,
    "locked_until": lockUntil
  }
  let configDir = getHomeDir() / ".config"
  createDir(configDir)
  writeFile(logPath, $node)

proc getClipboardUrl(): string =
  let clipCmds = ["wl-paste", "xclip -selection clipboard -o", "pbpaste"]
  for cmd in clipCmds:
    let exe = cmd.split(' ')[0]
    if findExe(exe) != "":
      let res = execCmdEx(cmd).output.strip()
      if res.startsWith("http://") or res.startsWith("https://") or res.startsWith("www.") or "youtu" in res or "vimeo" in res or "twitch" in res or "dailymotion" in res:
        return res
  return ""

proc renderThumbnail(imgPath: string) =
  if not fileExists(imgPath):
    return

  var chafaExe = findExe("chafa")
  var convertExe = findExe("convert")

  if chafaExe == "" and convertExe == "":
    if ensureExe("chafa"):
      chafaExe = findExe("chafa")

  if chafaExe != "":
    let (outp, code) = execCmdEx(quoteShell(chafaExe) & " --size=45x20 --symbols=block+border+space " & quoteShell(imgPath))
    if code == 0:
      echo outp
      return

  if convertExe != "":
    let (outp, code) = execCmdEx(quoteShell(convertExe) & " -resize 50x20! ascii:- " & quoteShell(imgPath))
    if code == 0:
      echo outp
      return

  echo "[Thumbnail downloaded at: ", imgPath, "]"

proc previewHandler(id: string, title: string, channel: string, duration: string, thumbUrl: string) =
  echo "=========================================="
  echo " TITLE:    ", title
  echo " CHANNEL:  ", channel
  echo " DURATION: ", duration
  echo " LINK:     https://youtu.be/", id
  echo "=========================================="
  echo ""

  if thumbUrl != "":
    let tmpDir = getTempDir()
    let imgPath = tmpDir / ("yt_thumb_" & id & ".jpg")
    if not fileExists(imgPath):
      discard execCmdEx("curl -s -o " & quoteShell(imgPath) & " " & quoteShell(thumbUrl))
    renderThumbnail(imgPath)

proc interactiveSearchUI(query: string): string =
  if not ensureExe("yt-dlp") or not ensureExe("fzf"):
    echo "Error: 'yt-dlp' and 'fzf' are required for the interactive UI."
    return ""

  let ytdlpCmd = findExe("yt-dlp")
  let fzfCmd = findExe("fzf")

  echo "Searching YouTube and preparing thumbnail UI for: \"", query, "\"..."

  let args = [
    "ytsearch10:" & query,
    "--dump-single-json",
    "--flat-playlist",
    "--skip-download"
  ]

  let (output, exitCode) = execCmdEx(ytdlpCmd & " " & args.join(" "))
  if exitCode != 0 or output.strip() == "":
    echo "Failed to fetch search results from YouTube."
    return ""

  try:
    let data = parseJson(output)
    var entries: JsonNode
    if data.hasKey("entries"):
      entries = data["entries"]
    else:
      entries = newJArray()

    if entries.len == 0:
      echo "No results found."
      return ""

    let selfBinary = getAppFilename()
    var fzfInputLines: seq[string] = @[]

    for item in entries:
      let title = item.getOrDefault("title").getStr("Unknown Title").replace("\t", " ").replace("\n", " ").replace("\r", " ")
      let uploader = item.getOrDefault("uploader").getStr(item.getOrDefault("channel").getStr("Unknown Channel")).replace("\t", " ").replace("\n", " ").replace("\r", " ")
      let duration = item.getOrDefault("duration_string").getStr("N/A").replace("\t", " ")
      let id = item.getOrDefault("id").getStr("").replace("\t", " ")

      var thumbUrl = ""
      if item.hasKey("thumbnails") and item["thumbnails"].len > 0:
        thumbUrl = item["thumbnails"][^1].getOrDefault("url").getStr("")
      elif item.hasKey("thumbnail"):
        thumbUrl = item.getOrDefault("thumbnail").getStr("")
      thumbUrl = thumbUrl.replace("\t", " ")

      let videoUrl = if id != "": "https://www.youtube.com/watch?v=" & id else: item.getOrDefault("url").getStr("")

      if id != "":
        fzfInputLines.add(title & "\t" & uploader & "\t" & duration & "\t" & id & "\t" & thumbUrl & "\t" & videoUrl)

    let tmpDir = getTempDir()
    let listFile = tmpDir / "yt_fzf_list.txt"
    writeFile(listFile, fzfInputLines.join("\n"))

    let previewCmd = quoteShell(selfBinary) & " --internal-preview {4} {1} {2} {3} {5}"
    let fzfScript = fzfCmd & " --delimiter='\\t' --with-nth=1,2,3 --preview=" & quoteShell(previewCmd) &
                 " --preview-window=right:50%:wrap --header='Use UP/DOWN arrows to navigate, ENTER to play, ESC to exit' < " & quoteShell(listFile)

    let (selectedLine, fzfExit) = execCmdEx(fzfScript)
    removeFile(listFile)

    if fzfExit != 0 or selectedLine.strip() == "":
      echo "Selection cancelled."
      return ""

    let parts = selectedLine.strip().split('\t')
    if parts.len >= 6:
      return parts[5]
    elif parts.len >= 4:
      return "https://www.youtube.com/watch?v=" & parts[3]

  except JsonParsingError:
    echo "Error parsing search results."
    return ""
  except KeyError:
    echo "Error reading JSON keys."
    return ""

  return ""

proc playYoutube(target: string, speed: float, mode: PlayMode) =
  if target.strip() == "":
    return

  if not checkDigitalWellbeing():
    return

  if not ensureExe("mpv"):
    echo "Error: 'mpv' executable not found in PATH."
    return

  let mpvCmd = findExe("mpv")
  let speedFormatted = formatFloat(speed, ffDecimal, 2)
  let ipcSocketPath = getTempDir() / "mpv_140p_ipc.sock"

  # Enforce automatic cutoff limit: max remaining seconds until 60 min limit is reached!
  let logPath = getUsageLogPath()
  var usedSecs = 0
  if fileExists(logPath):
    try: usedSecs = parseJson(readFile(logPath)).getOrDefault("session_seconds").getInt(0)
    except: discard

  let remainingSecs = max(10, MAX_WATCH_SECONDS - usedSecs)
  echo "⏱️ Session Time Remaining: ", (remainingSecs div 60), " Minutes (Auto-shutoff configured)."

  var commonArgs = @[
    "--input-ipc-server=" & ipcSocketPath,
    "--speed=" & speedFormatted,
    "--length=" & $remainingSecs, # Automatic hard exit after 60 min total continuous usage!
    "--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
  ]
  var args: seq[string] = @[]

  case mode
  of modeAudioOnly:
    args = commonArgs & @["--no-video", target]
  of modeHighQuality:
    args = commonArgs & @["--ytdl-format=bestvideo+bestaudio/best", target]
  of modeDataSaver:
    args = commonArgs & @[
      "--ytdl-format=bestvideo[height<=?144]+bestaudio/bestvideo[height<=?240]+bestaudio/bestvideo[height<=?360]+bestaudio/best/worst",
      "--ytdl-raw-options=write-sub=,write-auto-sub=,sub-langs=en.*",
      "--slang=en,eng",
      "--sid=1",
      target
    ]

  let startTime = getTime().toUnix()
  try:
    let process = startProcess(mpvCmd, args = args, options = {poParentStreams, poUsePath})
    let exitCode = process.waitForExit()
    let elapsed = int(getTime().toUnix() - startTime)
    updateUsageTime(elapsed)

    if exitCode != 0:
      echo "mpv exited."
    process.close()
  except OSError as e:
    echo "Error executing mpv: ", e.msg

proc transcribeAudio*(target: string) =
  if target.strip() == "":
    echo "❌ Error: No target file or URL provided for transcription."
    return

  let lowerTarget = target.toLowerAscii()
  let isUrlTarget = lowerTarget.startsWith("http://") or 
                    lowerTarget.startsWith("https://") or 
                    lowerTarget.startsWith("www.") or 
                    "youtu" in lowerTarget or 
                    "vimeo" in lowerTarget or
                    "twitch" in lowerTarget

  if isUrlTarget:
    if not ensureExe("yt-dlp"):
      echo "❌ Error: 'yt-dlp' is required for URL transcription."
      return
  else:
    if not ensureExe("ffmpeg"):
      echo "❌ Error: 'ffmpeg' is required for local file transcription."
      return

  if not ensurePythonSpeechRecognition():
    echo "❌ Error: Python speech recognition dependency is missing."
    return

  echo "🎙️ Transcribing audio: ", target, "..."

  let tmpWav = getTempDir() / ("transcribe_" & $getTime().toUnix() & ".wav")
  var extractSuccess = false

  if isUrlTarget:
    let ytdlpCmd = findExe("yt-dlp")
    let (outp, code) = execCmdEx(ytdlpCmd & " -x --audio-format wav --postprocessor-args \"-ar 16000 -ac 1\" -o " & quoteShell(tmpWav) & " " & quoteShell(target))
    extractSuccess = (code == 0 and fileExists(tmpWav))
  else:
    let ffmpegCmd = findExe("ffmpeg")
    if not fileExists(target):
      echo "❌ Error: File not found: ", target
      return
    let (outp, code) = execCmdEx(ffmpegCmd & " -y -i " & quoteShell(target) & " -ar 16000 -ac 1 " & quoteShell(tmpWav))
    extractSuccess = (code == 0 and fileExists(tmpWav))

  if not extractSuccess:
    echo "❌ Error: Failed to extract audio into WAV format for speech recognition."
    if fileExists(tmpWav): removeFile(tmpWav)
    return

  let pyScript = """import sys, os

wav_path = sys.argv[1]
if not os.path.exists(wav_path):
    print("Error: Audio file not found", file=sys.stderr)
    sys.exit(1)

try:
    import speech_recognition as sr
    r = sr.Recognizer()
    with sr.AudioFile(wav_path) as source:
        duration = int(source.DURATION)
        chunk_duration = 30
        full_text = []
        if duration <= 0:
            try:
                audio = r.record(source)
                res = r.recognize_google(audio, language="hi-IN")
                if res: full_text.append(res)
            except Exception:
                try:
                    audio = r.record(source)
                    res = r.recognize_google(audio, language="en-US")
                    if res: full_text.append(res)
                except Exception: pass
        else:
            for offset in range(0, duration, chunk_duration):
                chunk_len = min(chunk_duration, duration - offset)
                if chunk_len <= 0: break
                try:
                    audio = r.record(source, duration=chunk_len)
                    try:
                        res = r.recognize_google(audio, language="hi-IN")
                    except Exception:
                        res = r.recognize_google(audio, language="en-US")
                    if res: full_text.append(res)
                except Exception: pass

        result = " ".join(full_text).strip()
        if result:
            print(result)
            sys.exit(0)
        else:
            print("[No speech detected or unrecognized speech]")
            sys.exit(0)
except ImportError:
    pass
except Exception as e:
    print(f"speech_recognition error: {e}", file=sys.stderr)

try:
    import whisper
    model = whisper.load_model("base")
    res = model.transcribe(wav_path)
    print(res.get("text", "").strip())
    sys.exit(0)
except ImportError:
    pass
except Exception as e:
    print(f"whisper error: {e}", file=sys.stderr)

print("Error: Neither 'speech_recognition' nor 'whisper' python module is installed.", file=sys.stderr)
sys.exit(1)
"""

  let pyCmd = findExe("python3")
  if pyCmd == "":
    echo "❌ Error: 'python3' executable not found."
    if fileExists(tmpWav): removeFile(tmpWav)
    return

  let tmpScript = getTempDir() / ("transcribe_script_" & $getTime().toUnix() & ".py")
  writeFile(tmpScript, pyScript)

  let (outp, code) = execCmdEx(pyCmd & " " & quoteShell(tmpScript) & " " & quoteShell(tmpWav))

  if fileExists(tmpScript): removeFile(tmpScript)
  if fileExists(tmpWav): removeFile(tmpWav)

  if code == 0:
    echo "\n📝 --- TRANSCRIPTION RESULT ---"
    echo outp.strip()
    echo "-------------------------------\n"
  else:
    echo "❌ Transcription failed:"
    echo outp.strip()

proc main() =
  let rawArgs = commandLineParams()

  if rawArgs.len >= 5 and rawArgs[0] == "--internal-preview":
    let id = rawArgs[1]
    let title = rawArgs[2]
    let channel = rawArgs[3]
    let duration = rawArgs[4]
    let thumbUrl = if rawArgs.len >= 6: rawArgs[5] else: ""
    previewHandler(id, title, channel, duration, thumbUrl)
    quit(0)

  if not checkDigitalWellbeing():
    quit(1)

  randomize()

  if rawArgs.len == 0:
    let clipUrl = getClipboardUrl()
    if clipUrl != "":
      echo "Auto-detected URL from clipboard: ", clipUrl
      playYoutube(clipUrl, 1.5, modeDataSaver)
      quit(0)
    else:
      stdout.write "Enter YouTube Link or Search Query: "
      stdout.flushFile()
      let inputStr = readLine(stdin).strip()
      if inputStr == "": quit(0)
      if inputStr.startsWith("http://") or inputStr.startsWith("https://") or inputStr.startsWith("www."):
        playYoutube(inputStr, 1.5, modeDataSaver)
      else:
        let selectedUrl = interactiveSearchUI(inputStr)
        if selectedUrl != "": playYoutube(selectedUrl, 1.5, modeDataSaver)
      quit(0)

  let firstArg = rawArgs[0].toLowerAscii()

  if firstArg in ["-h", "--help", "help"]:
    echo """play_140p - Simple & Clean YouTube Player with Digital Wellbeing & Speech Recognition

USAGE:
  play_140p <URL | QUERY> [SPEED] [MODE]
  play_140p status
  play_140p convert <input>... [options]
  play_140p transcribe <file_or_url>

POSITIONAL ARGUMENTS:
  <URL|QUERY>   YouTube URL or search query terms
  [SPEED]       Playback speed (e.g. 1.5, 1.5x, 2.0x - default: 1.5x)
  [MODE]        Playback mode: datasaver (default), audio, hq

EXAMPLES:
  play_140p "lofi hip hop"
  play_140p https://youtu.be/dQw4w9WgXcQ 1.5x audio
  play_140p transcribe audio.mp3
  play_140p convert video.mp4 mp3 192k
  play_140p convert -r /path/to/music
"""
    quit(0)

  if firstArg in ["transcribe", "-t", "--transcribe"]:
    if rawArgs.len < 2:
      echo "❌ Error: Please specify audio file or URL to transcribe."
      quit(1)
    transcribeAudio(rawArgs[1])
    quit(0)

  if firstArg in ["status", "-s", "--status"]:
    let logPath = getUsageLogPath()
    if fileExists(logPath):
      try:
        let d = parseJson(readFile(logPath))
        let sec = d.getOrDefault("session_seconds").getInt(0)
        let lock = d.getOrDefault("locked_until").getInt(0)
        let now = getTime().toUnix()
        echo "📊 Total Session Usage: ", (sec div 60), " / 60 mins."
        if now < lock:
          echo "🔒 App Locked: ", (lock - now) div 60, " mins remaining in 4-hour cooldown."
        else:
          echo "✅ App Active & Ready to use."
      except: discard
    else:
      echo "📊 Total Session Usage: 0 / 60 mins. (App Ready)"
    quit(0)

  if firstArg in ["convert", "audioconvert"]:
    if rawArgs.len >= 2 and rawArgs[1].toLowerAscii() in ["transcribe", "-t", "--transcribe"]:
      if rawArgs.len < 3:
        echo "❌ Error: Please specify audio file or URL to transcribe."
        quit(1)
      transcribeAudio(rawArgs[2])
      quit(0)

    let subArgs = rawArgs[1..^1]
    let audioConvertExe = findExe("audioconvert")
    let targetExe = if audioConvertExe != "": audioConvertExe else: getAppDir() / "audioconvert"
    if fileExists(targetExe) or audioConvertExe != "":
      let process = startProcess(targetExe, args = subArgs, options = {poParentStreams, poUsePath})
      let exitCode = process.waitForExit()
      process.close()
      quit(exitCode)
    else:
      echo "❌ 'audioconvert' command binary not found."
      quit(1)

  var speed = 1.5
  var mode = modeDataSaver
  var queryParts: seq[string] = @[]
  var isExplicitSearch = (firstArg == "search")
  let startIdx = if isExplicitSearch: 1 else: 0

  for i in startIdx..<rawArgs.len:
    let arg = rawArgs[i]
    let lowerArg = arg.toLowerAscii()

    if lowerArg in ["audio", "music", "a", "sound"]:
      mode = modeAudioOnly
    elif lowerArg in ["hd", "hq", "max", "high"]:
      mode = modeHighQuality
      speed = 1.0
    elif lowerArg in ["140p", "144p", "datasaver", "saver", "low"]:
      mode = modeDataSaver
    elif (block:
      var isNum = false
      try:
        discard parseFloat(lowerArg.replace("x", ""))
        isNum = true
      except ValueError:
        isNum = false
      isNum):
      let numStr = lowerArg.replace("x", "")
      try:
        speed = parseFloat(numStr)
      except ValueError:
        queryParts.add(arg)
    else:
      queryParts.add(arg)

  let queryOrUrl = queryParts.join(" ").strip()

  if queryOrUrl == "":
    let clipUrl = getClipboardUrl()
    if clipUrl != "":
      echo "Auto-detected URL from clipboard: ", clipUrl
      playYoutube(clipUrl, speed, mode)
      quit(0)
    else:
      echo "Error: No URL or search query specified."
      quit(1)

  if queryOrUrl.startsWith("http://") or queryOrUrl.startsWith("https://") or queryOrUrl.startsWith("www.") or "youtu" in queryOrUrl or "vimeo" in queryOrUrl:
    let finalTarget = if queryOrUrl.startsWith("www."): "https://" & queryOrUrl else: queryOrUrl
    playYoutube(finalTarget, speed, mode)
    quit(0)

  let selectedTarget = interactiveSearchUI(queryOrUrl)
  if selectedTarget != "":
    playYoutube(selectedTarget, speed, mode)

when isMainModule:
  main()
