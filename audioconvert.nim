import std/[os, parseopt, strutils, osproc, streams, times]

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
    let (outp, code) = execCmdEx(quoteShell(ytdlpCmd) & " -x --audio-format wav --postprocessor-args \"-ar 16000 -ac 1\" -o " & quoteShell(tmpWav) & " " & quoteShell(target))
    extractSuccess = (code == 0 and fileExists(tmpWav))
  else:
    let ffmpegCmd = findExe("ffmpeg")
    if not fileExists(target):
      echo "❌ Error: File not found: ", target
      return
    let (outp, code) = execCmdEx(quoteShell(ffmpegCmd) & " -y -i " & quoteShell(target) & " -ar 16000 -ac 1 " & quoteShell(tmpWav))
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

  let (outp, code) = execCmdEx(quoteShell(pyCmd) & " " & quoteShell(tmpScript) & " " & quoteShell(tmpWav))

  if fileExists(tmpScript): removeFile(tmpScript)
  if fileExists(tmpWav): removeFile(tmpWav)

  if code == 0:
    echo "\n📝 --- TRANSCRIPTION RESULT ---"
    echo outp.strip()
    echo "-------------------------------\n"
  else:
    echo "❌ Transcription failed:"
    echo outp.strip()

type
  TaskType = enum
    ttFile, ttUrl

  ConvertTask = object
    kind: TaskType
    target: string

proc printHelp() =
  let cores = countProcessors()
  echo """audioconvert - Fast Audio Converter, Downloader & Speech Transcriber

USAGE:
  audioconvert [OPTIONS] <FILE_OR_URL_OR_DIR>...
  audioconvert transcribe <FILE_OR_URL>

OPTIONS:
  -t, --transcribe       Transcribe audio to text using speech recognition
  -f, --format:<fmt>     Target audio format: mp3, opus, m4a, wav, flac, aac (Default: mp3)
  -b, --bitrate:<rate>   Target bitrate, e.g. 128k, 192k, 320k (Default: 192k)
  -o, --output:<path>    Output filename or output directory
  -s, --speed:<factor>   Playback speed multiplier (e.g. 1.5 for 1.5x speed audio)
  -j, --jobs:<num>       Number of parallel workers (Default: max CPU cores [""" & $cores & """], pass 0 for max CPU cores)
  -r, --recursive        Recursively process input directory for unlimited video/audio files
  -h, --help             Show this help message

EXAMPLES:
  audioconvert song.mp4                      # Converts song.mp4 -> song.mp3 (192k)
  audioconvert transcribe voice.mp3          # Transcribe audio file to text
  audioconvert -t "https://youtu.be/..."     # Transcribe online video/audio
  audioconvert -r /path/to/music             # Batch convert unlimited files recursively
"""

proc getSupportedMediaExtensions(): seq[string] =
  return @[".mp4", ".mkv", ".webm", ".avi", ".mov", ".flv", ".wmv", ".m4v", ".mp3", ".wav", ".ogg", ".opus", ".m4a", ".flac", ".aac", ".wma"]

proc isUrl(str: string): bool =
  let s = str.toLowerAscii()
  return s.startsWith("http://") or s.startsWith("https://") or s.startsWith("www.") or "youtu" in s or "vimeo" in s or "twitch" in s

proc main() =
  let rawArgs = commandLineParams()

  if rawArgs.len == 0:
    printHelp()
    quit(0)

  var format = "mp3"
  var bitrate = "192k"
  var outputTarget = ""
  var speed = 1.0
  var recursive = false
  var maxJobs = countProcessors()
  var rawTargets: seq[string] = @[]
  var isTranscribe = false

  if rawArgs.len >= 1 and rawArgs[0].toLowerAscii() in ["transcribe", "-t", "--transcribe"]:
    isTranscribe = true

  var p = initOptParser(rawArgs)

  for kind, key, val in p.getopt():
    case kind
    of cmdLongOption, cmdShortOption:
      case key.toLowerAscii()
      of "h", "help":
        printHelp()
        quit(0)
      of "t", "transcribe":
        isTranscribe = true
      of "f", "format":
        if val != "": format = val.toLowerAscii()
      of "b", "bitrate":
        if val != "": bitrate = val.toLowerAscii()
      of "o", "output":
        if val != "": outputTarget = val
      of "s", "speed":
        if val != "":
          try: speed = parseFloat(val)
          except ValueError: echo "⚠️ Invalid speed value: ", val
      of "j", "jobs", "parallel":
        if val != "":
          try:
            let parsedJobs = parseInt(val)
            if parsedJobs <= 0:
              maxJobs = countProcessors()
            else:
              maxJobs = parsedJobs
          except ValueError: echo "⚠️ Invalid jobs value: ", val
      of "r", "recursive":
        recursive = true
    of cmdArgument:
      if key.toLowerAscii() != "transcribe":
        rawTargets.add(key)
    of cmdEnd:
      discard

  maxJobs = max(1, maxJobs)

  if isTranscribe:
    if rawTargets.len == 0:
      echo "❌ Error: Please specify audio file or URL to transcribe."
      printHelp()
      quit(1)
    transcribeAudio(rawTargets[0])
    quit(0)

  if rawTargets.len == 0:
    echo "❌ Error: No input file, directory, or URL specified."
    printHelp()
    quit(1)

  let validExts = getSupportedMediaExtensions()
  var tasks: seq[ConvertTask] = @[]

  for target in rawTargets:
    if isUrl(target):
      tasks.add(ConvertTask(kind: ttUrl, target: target))
    elif dirExists(target):
      if recursive:
        for file in walkDirRec(target):
          let (_, _, ext) = splitFile(file)
          if ext.toLowerAscii() in validExts:
            tasks.add(ConvertTask(kind: ttFile, target: file))
      else:
        for kind, file in walkDir(target):
          if kind == pcFile:
            let (_, _, ext) = splitFile(file)
            if ext.toLowerAscii() in validExts:
              tasks.add(ConvertTask(kind: ttFile, target: file))
    elif fileExists(target):
      tasks.add(ConvertTask(kind: ttFile, target: target))
    else:
      echo "❌ Error: Target not found or invalid: ", target

  if tasks.len == 0:
    echo "❌ Error: No valid files or URLs to process."
    quit(1)

  var hasFiles = false
  var hasUrls = false
  for t in tasks:
    if t.kind == ttFile: hasFiles = true
    if t.kind == ttUrl: hasUrls = true

  if hasFiles and not ensureExe("ffmpeg"):
    echo "❌ Error: 'ffmpeg' binary not found in PATH."
    quit(1)
  let ffmpegExe = findExe("ffmpeg")

  if hasUrls and not ensureExe("yt-dlp"):
    echo "❌ Error: 'yt-dlp' binary not found in PATH."
    quit(1)
  let ytdlpExe = findExe("yt-dlp")

  if outputTarget != "":
    if tasks.len > 1 or not outputTarget.contains("."):
      createDir(outputTarget)

  type
    RunningJob = object
      process: Process
      task: ConvertTask
      outFile: string
      taskNum: int

  var activeJobs: seq[RunningJob] = @[]
  var nextTaskIdx = 0
  let totalTasks = tasks.len

  echo "🚀 Starting parallel audio conversion of " & $totalTasks & " task(s) [max " & $maxJobs & " worker(s)]..."

  while nextTaskIdx < totalTasks or activeJobs.len > 0:
    while activeJobs.len < maxJobs and nextTaskIdx < totalTasks:
      let task = tasks[nextTaskIdx]
      let taskNum = nextTaskIdx + 1
      nextTaskIdx += 1

      var job: RunningJob
      job.task = task
      job.taskNum = taskNum

      if task.kind == ttFile:
        let (dir, name, _) = splitFile(task.target)
        var outFile = ""
        if outputTarget != "":
          if dirExists(outputTarget):
            outFile = outputTarget / (name & "." & format)
          else:
            outFile = outputTarget
        else:
          outFile = dir / (name & "." & format)

        if absolutePath(task.target) == absolutePath(outFile):
          outFile = dir / (name & "_converted." & format)

        job.outFile = outFile

        var filterChain: seq[string] = @[]
        if speed != 1.0:
          var s = speed
          while s > 2.0:
            filterChain.add("atempo=2.0")
            s = s / 2.0
          while s < 0.5:
            filterChain.add("atempo=0.5")
            s = s / 0.5
          filterChain.add("atempo=" & formatFloat(s, ffDecimal, 2))

        var args: seq[string] = @["-y", "-loglevel", "error", "-i", task.target, "-vn"]
        if filterChain.len > 0:
          args.add("-af")
          args.add(filterChain.join(","))
        if format in ["mp3", "m4a", "opus", "aac"]:
          args.add("-b:a")
          args.add(bitrate)
        args.add(outFile)

        echo "[" & $taskNum & "/" & $totalTasks & "] 🔄 Converting: " & task.target & " ➔ " & outFile
        try:
          job.process = startProcess(ffmpegExe, args = args, options = {poUsePath, poStdErrToStdOut})
          activeJobs.add(job)
        except OSError as e:
          echo "[" & $taskNum & "/" & $totalTasks & "] ❌ Failed to start ffmpeg: " & e.msg

      elif task.kind == ttUrl:
        var args: seq[string] = @["-x", "--audio-format", format, "--audio-quality", "0"]
        if outputTarget != "":
          if dirExists(outputTarget):
            args.add("-o")
            args.add(outputTarget / "%(title)s.%(ext)s")
          else:
            args.add("-o")
            args.add(outputTarget)
        args.add(task.target)

        echo "[" & $taskNum & "/" & $totalTasks & "] 📥 Downloading URL: " & task.target
        try:
          job.process = startProcess(ytdlpExe, args = args, options = {poUsePath, poStdErrToStdOut})
          activeJobs.add(job)
        except OSError as e:
          echo "[" & $taskNum & "/" & $totalTasks & "] ❌ Failed to start yt-dlp: " & e.msg

    if activeJobs.len > 0:
      sleep(50)
      var remainingJobs: seq[RunningJob] = @[]
      for job in activeJobs:
        if job.process.running():
          remainingJobs.add(job)
        else:
          let exitCode = job.process.waitForExit()
          let output = try: job.process.outputStream.readAll().strip() except: ""
          job.process.close()

          if exitCode == 0:
            if job.task.kind == ttFile:
              echo "[" & $job.taskNum & "/" & $totalTasks & "] ✅ Completed: " & job.outFile
            else:
              echo "[" & $job.taskNum & "/" & $totalTasks & "] ✅ URL downloaded & converted: " & job.task.target
          else:
            echo "[" & $job.taskNum & "/" & $totalTasks & "] ❌ Failed: " & job.task.target
            if output.len > 0:
              echo "   Error log: ", output

      activeJobs = remainingJobs

  echo "🎉 All audio conversions completed!"

when isMainModule:
  main()

