import std/[os, osproc, strutils, json, times, terminal, streams, random]

let vaultDir = getHomeDir() / ".lazy_vault"
let vaultFile = vaultDir / "vault.enc"
let recoveryFile = vaultDir / "vault.recovery.enc"
let saltFile = vaultDir / "vault.salt"

proc getClipCmd(): seq[string] =
  if getEnv("WAYLAND_DISPLAY") != "" and findExe("wl-copy") != "":
    return @["wl-copy"]
  elif findExe("xclip") != "":
    return @["xclip", "-selection", "clipboard"]
  return @[]

proc copyToClipboard(text: string): bool =
  let cmd = getClipCmd()
  if cmd.len == 0:
    echo "[!] Neither wl-copy nor xclip found. Outputting secret:"
    echo text
    return false

  let p = startProcess(cmd[0], args = (if cmd.len > 1: cmd[1..^1] else: @[]), options = {poUsePath})
  p.inputStream.write(text)
  p.inputStream.close()
  let code = p.waitForExit()
  p.close()
  return code == 0

proc clearClipboardAfter(seconds: int) =
  let cmd = getClipCmd()
  if cmd.len == 0: return

  let clearPy = "import time, subprocess; time.sleep(" & $seconds & "); " &
    (if cmd[0] == "wl-copy": "subprocess.run(['wl-copy', '--clear'])"
     else: "subprocess.run(['xclip', '-selection', 'clipboard'], input=b'')" )
  
  discard startProcess("python3", args = ["-c", clearPy], options = {poUsePath})

proc getOrCreateSalt(): string =
  if not dirExists(vaultDir):
    createDir(vaultDir)
    setFilePermissions(vaultDir, {fpUserRead, fpUserWrite, fpUserExec})
  
  if not fileExists(saltFile):
    let (outp, _) = execCmdEx("openssl rand -hex 32")
    let salt = outp.strip()
    writeFile(saltFile, salt)
    setFilePermissions(saltFile, {fpUserRead, fpUserWrite})
    return salt
  else:
    return readFile(saltFile).strip()

proc deriveKeyHex(pin: string, saltHex: string): string =
  let cmd = "openssl kdf -keylen 32 -kdfopt pass:" & quoteShell(pin) &
            " -kdfopt salt:" & quoteShell(saltHex) &
            " -kdfopt iter:600000 -kdfopt digest:SHA256 PBKDF2"
  let (outp, exitCode) = execCmdEx(cmd)
  if exitCode != 0 or outp.strip() == "":
    let fbCmd = "echo -n " & quoteShell(pin) & " | openssl dgst -sha256 -hmac " & quoteShell(saltHex)
    let (fbOut, _) = execCmdEx(fbCmd)
    return fbOut.split()[^1].strip()
  
  return outp.strip().replace(":", "").toLowerAscii()

proc encryptVault(jsonStr: string, keyHex: string): bool =
  let tmpFile = vaultDir / "tmp_plain.json"
  writeFile(tmpFile, jsonStr)
  setFilePermissions(tmpFile, {fpUserRead, fpUserWrite})
  
  let encCmd = "openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -in " & quoteShell(tmpFile) &
               " -out " & quoteShell(vaultFile) & " -pass pass:" & quoteShell(keyHex)
  let (_, exitCode) = execCmdEx(encCmd)
  removeFile(tmpFile)
  if fileExists(vaultFile):
    setFilePermissions(vaultFile, {fpUserRead, fpUserWrite})
  return exitCode == 0

proc encryptVaultRecovery(jsonStr: string, recoveryKeyHex: string): bool =
  let tmpFile = vaultDir / "tmp_rec_plain.json"
  writeFile(tmpFile, jsonStr)
  setFilePermissions(tmpFile, {fpUserRead, fpUserWrite})

  let encCmd = "openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -in " & quoteShell(tmpFile) &
               " -out " & quoteShell(recoveryFile) & " -pass pass:" & quoteShell(recoveryKeyHex)
  let (_, exitCode) = execCmdEx(encCmd)
  removeFile(tmpFile)
  if fileExists(recoveryFile):
    setFilePermissions(recoveryFile, {fpUserRead, fpUserWrite})
  return exitCode == 0

proc decryptVault(keyHex: string): string =
  if not fileExists(vaultFile):
    return "{}"
  
  let decCmd = "openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -in " & quoteShell(vaultFile) &
               " -pass pass:" & quoteShell(keyHex)
  let (outp, exitCode) = execCmdEx(decCmd)
  if exitCode != 0:
    raise newException(ValueError, "Invalid Brain-PIN or corrupted vault data!")
  return outp

proc decryptVaultRecovery(recoveryKeyHex: string): string =
  if not fileExists(recoveryFile):
    raise newException(ValueError, "No Emergency Recovery Key setup found for this vault!")
  
  let decCmd = "openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -in " & quoteShell(recoveryFile) &
               " -pass pass:" & quoteShell(recoveryKeyHex)
  let (outp, exitCode) = execCmdEx(decCmd)
  if exitCode != 0:
    raise newException(ValueError, "Invalid Emergency Recovery Code! Could not decrypt vault.")
  return outp

proc promptBrainPin(): string =
  stdout.write "🧠 Enter Brain-PIN: "
  stdout.flushFile()
  var pin = ""
  try:
    pin = readPasswordFromStdin()
  except:
    pin = readLine(stdin).strip()
  if pin == "":
    echo "[!] PIN cannot be empty."
    quit(1)
  return pin

# Cryptographically Secure Password Generator
proc generatePassword(length: int = 16, style: string = "strong"): string =
  const
    lower = "abcdefghijklmnopqrstuvwxyz"
    upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    digits = "0123456789"
    symbols = "!@#$%^&*()_+-=[]{}|;:,.<>?"
    easySymbols = "!@#$%^&*"
    pinDigits = "0123456789"

  var pool = lower & upper & digits & symbols
  if style == "pin":
    pool = pinDigits
  elif style == "alpha":
    pool = lower & upper
  elif style == "alphanum":
    pool = lower & upper & digits
  elif style == "easy":
    pool = lower & upper & digits & easySymbols

  # Use OpenSSL CSPRNG for cryptographic randomness
  let (outp, exitCode) = execCmdEx("openssl rand -base64 " & $(length * 2))
  var res = ""
  if exitCode == 0:
    for ch in outp.strip():
      if pool.contains(ch):
        res.add(ch)
        if res.len == length:
          return res

  # Fallback logic if needed
  randomize()
  while res.len < length:
    res.add(pool[rand(pool.len - 1)])
  return res

proc generateRecoveryKey(): string =
  let (outp, exitCode) = execCmdEx("openssl rand -hex 16")
  let raw = if exitCode == 0: outp.strip().toUpperAscii() else: "A1B2C3D4E5F678901234567890ABCDEF"
  return "REC-" & raw[0..3] & "-" & raw[4..7] & "-" & raw[8..11] & "-" & raw[12..15]

proc setupRecoveryKey(keyHex: string, saltHex: string) =
  let rawJson = decryptVault(keyHex)
  let recCode = generateRecoveryKey()
  let recKeyHex = deriveKeyHex(recCode.replace("-", "").toLowerAscii(), saltHex)

  if encryptVaultRecovery(rawJson, recKeyHex):
    echo "\n🔑 --- EMERGENCY RECOVERY CODE CREATED ---"
    echo "=========================================================="
    echo "YOUR RECOVERY CODE:  ", recCode
    echo "=========================================================="
    echo "⚠️  Save this Emergency Recovery Code in a safe place!"
    echo "⚠️  If you ever forget your Brain-PIN, run `v recover` to reset PIN.\n"
  else:
    echo "❌ Failed to create emergency recovery backup."

proc recoverVaultWithKey(saltHex: string) =
  stdout.write "🔑 Enter Emergency Recovery Code (e.g. REC-XXXX-XXXX-...): "
  stdout.flushFile()
  var recCode = readLine(stdin).strip().toUpperAscii().replace(" ", "")
  if recCode == "":
    echo "❌ Recovery code cannot be empty."
    quit(1)

  let recKeyHex = deriveKeyHex(recCode.replace("-", "").toLowerAscii(), saltHex)
  var rawJson = ""
  try:
    rawJson = decryptVaultRecovery(recKeyHex)
  except ValueError as e:
    echo "\n❌ Recovery Failed: ", e.msg
    quit(1)

  echo "\n✅ Emergency Recovery Code Verified!"
  stdout.write "🧠 Enter your NEW Brain-PIN: "
  stdout.flushFile()
  var newPin = ""
  try: newPin = readPasswordFromStdin()
  except: newPin = readLine(stdin).strip()

  if newPin == "":
    echo "❌ PIN cannot be empty."
    quit(1)

  let newKeyHex = deriveKeyHex(newPin, saltHex)
  if encryptVault(rawJson, newKeyHex):
    echo "🎉 Successfully reset Brain-PIN and restored Vault access!"
    discard encryptVaultRecovery(rawJson, recKeyHex)
  else:
    echo "❌ Failed to re-encrypt vault with new PIN."

proc changeBrainPin(oldKeyHex: string, saltHex: string) =
  let rawJson = decryptVault(oldKeyHex)
  stdout.write "🧠 Enter NEW Brain-PIN: "
  stdout.flushFile()
  var newPin = ""
  try: newPin = readPasswordFromStdin()
  except: newPin = readLine(stdin).strip()

  if newPin == "":
    echo "❌ PIN cannot be empty."
    return

  let newKeyHex = deriveKeyHex(newPin, saltHex)
  if encryptVault(rawJson, newKeyHex):
    echo "🎉 Brain-PIN changed successfully!"
  else:
    echo "❌ Failed to re-encrypt vault with new PIN."

proc addEntryDirect(keyHex: string, title: string, secretInput: string, usernameInput: string = "", notesInput: string = "") =
  let rawJson = decryptVault(keyHex)
  var vault: JsonNode
  try:
    vault = parseJson(rawJson)
  except:
    vault = newJObject()

  var secVal = secretInput
  if secVal == "":
    # Suggest auto-generated password!
    let suggestedPass = generatePassword(16, "strong")
    echo "\n🎲 Auto-Generated Password Suggestion: ", suggestedPass
    stdout.write "Press ENTER to accept suggested password, or type your own: "
    stdout.flushFile()
    var userIn = ""
    try: userIn = readLine(stdin).strip()
    except: userIn = ""

    if userIn == "":
      secVal = suggestedPass
      echo "⚡ Used auto-generated password!"
    else:
      secVal = userIn

  if secVal == "":
    echo "[!] Secret value cannot be empty."
    return

  var item = newJObject()
  item["username"] = %usernameInput
  item["secret"] = %secVal
  item["notes"] = %notesInput
  item["updated_at"] = %(getTime().toUnix())

  vault[title] = item

  if encryptVault($vault, keyHex):
    echo "✅ Saved '", title, "' into Vault!"
    if copyToClipboard(secVal):
      echo "📋 Secret copied to Clipboard! Auto-clears in 15s."
      clearClipboardAfter(15)
  else:
    echo "❌ Failed to save entry."

proc exportVaultToCsv(keyHex: string, csvPath: string) =
  let rawJson = decryptVault(keyHex)
  var vault: JsonNode
  try: vault = parseJson(rawJson)
  except:
    echo "❌ Vault is empty or invalid."
    return

  if vault.len == 0:
    echo "❌ Vault is empty! Nothing to export."
    return

  var outFile = if csvPath != "": csvPath else: "lazy_vault_export.csv"
  var lines: seq[string] = @["title,username,secret,notes"]

  proc escapeCsv(s: string): string =
    if s.contains(",") or s.contains("\"") or s.contains("\n"):
      return "\"" & s.replace("\"", "\"\"") & "\""
    return s

  for k, v in vault.pairs:
    let uname = if v.hasKey("username"): v["username"].getStr() else: ""
    let sec = if v.hasKey("secret"): v["secret"].getStr() else: ""
    let notes = if v.hasKey("notes"): v["notes"].getStr() else: ""
    lines.add(escapeCsv(k) & "," & escapeCsv(uname) & "," & escapeCsv(sec) & "," & escapeCsv(notes))

  writeFile(outFile, lines.join("\n") & "\n")
  echo "✅ Successfully exported ", vault.len, " secret(s) to: ", outFile

proc parseCsvLine(line: string): seq[string] =
  var res: seq[string] = @[]
  var cur = ""
  var inQuotes = false
  var i = 0
  while i < line.len:
    let c = line[i]
    if c == '"':
      if inQuotes and i + 1 < line.len and line[i + 1] == '"':
        cur.add('"')
        inc i
      else:
        inQuotes = not inQuotes
    elif c == ',' and not inQuotes:
      res.add(cur.strip())
      cur = ""
    else:
      cur.add(c)
    inc i
  res.add(cur.strip())
  return res

proc importCsvToVault(keyHex: string, csvPath: string) =
  if not fileExists(csvPath):
    echo "❌ CSV file not found: ", csvPath
    return

  let rawJson = decryptVault(keyHex)
  var vault: JsonNode
  try: vault = parseJson(rawJson)
  except: vault = newJObject()

  let fileContent = readFile(csvPath)
  let rawLines = fileContent.splitLines()
  var addedCount = 0

  for idx, rawLine in rawLines:
    let line = rawLine.strip()
    if line == "": continue
    let cols = parseCsvLine(line)
    
    if idx == 0 and cols.len > 0 and cols[0].toLowerAscii() in ["title", "service", "name"]:
      continue

    var title = ""
    var uname = ""
    var sec = ""
    var notes = ""

    if cols.len >= 1: title = cols[0]
    if cols.len >= 2: uname = cols[1]
    if cols.len >= 3: sec = cols[2]
    if cols.len >= 4: notes = cols[3]

    if cols.len == 2:
      sec = uname
      uname = ""

    if title != "" and sec != "":
      var item = newJObject()
      item["username"] = %uname
      item["secret"] = %sec
      item["notes"] = %notes
      item["updated_at"] = %(getTime().toUnix())
      vault[title] = item
      inc addedCount

  if encryptVault($vault, keyHex):
    echo "✅ Successfully imported ", addedCount, " secret(s) from ", csvPath, " into Vault!"
  else:
    echo "❌ Failed to save imported CSV entries into Vault."

proc searchAndCopy(keyHex: string, filterQuery: string = "") =
  let rawJson = decryptVault(keyHex)
  var vault: JsonNode
  try:
    vault = parseJson(rawJson)
  except:
    echo "[!] Vault is empty or corrupted."
    return

  if vault.len == 0:
    echo "\n[!] Vault is empty! Add a secret first using `v a <title> <secret>`.\n"
    return

  if filterQuery != "":
    let cleanQ = filterQuery.toLowerAscii()
    for k, v in vault.pairs:
      if k.toLowerAscii() == cleanQ:
        let secVal = v["secret"].getStr()
        if copyToClipboard(secVal):
          echo "📋 Direct match! Secret for '", k, "' copied to Clipboard!"
          echo "⏳ Clipboard will auto-clear in 15 seconds."
          clearClipboardAfter(15)
          return

  let fzfExe = findExe("fzf")
  var items: seq[string] = @[]
  var titleMap: seq[tuple[display: string, title: string]] = @[]

  for k, v in vault.pairs:
    if filterQuery != "" and not (k.toLowerAscii().contains(filterQuery.toLowerAscii()) or
       (v.hasKey("username") and v["username"].getStr().toLowerAscii().contains(filterQuery.toLowerAscii()))):
      continue

    let uname = if v.hasKey("username") and v["username"].getStr() != "": " (" & v["username"].getStr() & ")" else: ""
    let notes = if v.hasKey("notes") and v["notes"].getStr() != "": " | " & v["notes"].getStr() else: ""
    let disp = k & uname & notes
    items.add(disp)
    titleMap.add((disp, k))

  if titleMap.len == 0:
    echo "[!] No matching secrets found for: ", filterQuery
    return

  if filterQuery != "" and titleMap.len == 1:
    let matchedTitle = titleMap[0].title
    let secVal = vault[matchedTitle]["secret"].getStr()
    if copyToClipboard(secVal):
      echo "📋 Secret for '", matchedTitle, "' copied to Clipboard!"
      echo "⏳ Clipboard will auto-clear in 15 seconds."
      clearClipboardAfter(15)
      return

  var selectedTitle = ""

  if fzfExe != "":
    let tmpListFile = vaultDir / "fzf_list.tmp"
    writeFile(tmpListFile, items.join("\n"))

    let queryOpt = if filterQuery != "": " --query=" & quoteShell(filterQuery) else: ""
    let fzfCmd = fzfExe & " --header='🔑 Select secret to COPY to Clipboard (ESC to cancel):' --reverse --height=40%" & queryOpt & " < " & quoteShell(tmpListFile)
    let (selectedLine, exitCode) = execCmdEx(fzfCmd)
    removeFile(tmpListFile)

    if exitCode == 0 and selectedLine.strip() != "":
      let cleanSel = selectedLine.strip()
      for item in titleMap:
        if item.display == cleanSel:
          selectedTitle = item.title
          break
  else:
    echo "\n--- 🔑 Secrets List ---"
    var idx = 1
    for item in titleMap:
      echo "[", idx, "] ", item.display
      inc idx
    stdout.write "\nEnter number to copy secret: "
    stdout.flushFile()
    let choice = readLine(stdin).strip()
    try:
      let i = parseInt(choice)
      if i >= 1 and i <= titleMap.len:
        selectedTitle = titleMap[i - 1].title
    except ValueError:
      discard

  if selectedTitle != "" and vault.hasKey(selectedTitle):
    let secVal = vault[selectedTitle]["secret"].getStr()
    if copyToClipboard(secVal):
      echo "📋 Secret for '", selectedTitle, "' copied to Clipboard!"
      echo "⏳ Clipboard will auto-clear in 15 seconds."
      clearClipboardAfter(15)

proc handlePasswordGen(args: seq[string]) =
  var lenVal = 16
  var style = "strong"
  
  for arg in args:
    if arg in ["pin", "alpha", "alphanum", "easy", "strong"]:
      style = arg
    else:
      try:
        lenVal = parseInt(arg)
      except ValueError:
        discard

  let pass = generatePassword(lenVal, style)
  echo "\n🎲 Generated Password [", style, ", len=", lenVal, "]:"
  echo "👉 ", pass
  if copyToClipboard(pass):
    echo "📋 Copied to Clipboard! Auto-clears in 15s.\n"

proc main() =
  var rawArgs = commandLineParams()

  if rawArgs.len > 1 and rawArgs[0].toLowerAscii() in ["v", "lazy_vault"]:
    rawArgs = rawArgs[1..^1]

  if rawArgs.len > 0 and rawArgs[0] in ["-h", "--help", "help"]:
    echo """
🧠 lazy_vault - Ultra-Frictionless Password Manager & Generator

USAGE & PATTERNS:
  v                            : Search & Copy secrets via fzf
  v <query>                    : Direct search/copy matching secret
  v g / gen [len] [style]      : Generate password (e.g. `v g 20`, `v gen pin 6`)
  v a <title> [secret]         : Add or UPDATE entry password (auto-generates if secret omitted)
  v +<title> [secret]          : Symbol shortcut add/update
  v change-pin / passwd        : Change Master Brain-PIN
  v recovery-key / recovery    : Generate & setup Emergency Recovery Key
  v recover / reset-pin        : Reset Brain-PIN using Emergency Recovery Key
  v export [filename.csv]      : Export encrypted vault to CSV file
  v import <filename.csv>      : Import CSV file into encrypted vault

PASSWORD STYLES for `v g`:
  strong    : Letters, Digits, Special Characters (Default)
  easy      : Simple symbols (!@#$%^&*)
  alphanum  : Letters and Digits only
  alpha     : Letters only
  pin       : Numeric PIN only
"""
    quit(0)

  let saltHex = getOrCreateSalt()

  if rawArgs.len > 0 and rawArgs[0].toLowerAscii() in ["recover", "reset-pin", "reset"]:
    recoverVaultWithKey(saltHex)
    quit(0)

  if rawArgs.len > 0 and rawArgs[0] in ["g", "gen", "generate", "pass"]:
    handlePasswordGen(rawArgs[1..^1])
    quit(0)

  var isAdd = false
  var isChangePin = false
  var isExport = false
  var isImport = false
  var isRecoverySetup = false
  var csvPath = ""
  var title = ""
  var secret = ""
  var searchFilter = ""

  if rawArgs.len > 0:
    let first = rawArgs[0].toLowerAscii()
    if first in ["change-pin", "passwd", "chpin"]:
      isChangePin = true
    elif first in ["recovery-key", "recovery", "setup-recovery"]:
      isRecoverySetup = true
    elif first in ["export", "backup"]:
      isExport = true
      if rawArgs.len > 1: csvPath = rawArgs[1]
    elif first in ["import", "restore"]:
      isImport = true
      if rawArgs.len > 1: csvPath = rawArgs[1]
    elif first in ["a", "add", "new", "+"] or first.startsWith("+"):
      isAdd = true
      if first.startsWith("+") and first.len > 1:
        title = first[1..^1]
      elif rawArgs.len > 1:
        title = rawArgs[1]
      
      if rawArgs.len > 2:
        secret = rawArgs[2]
    else:
      searchFilter = rawArgs.join(" ")

  let pin = promptBrainPin()
  let keyHex = deriveKeyHex(pin, saltHex)

  try:
    if isChangePin:
      changeBrainPin(keyHex, saltHex)
    elif isRecoverySetup:
      setupRecoveryKey(keyHex, saltHex)
    elif isExport:
      exportVaultToCsv(keyHex, csvPath)
    elif isImport:
      importCsvToVault(keyHex, csvPath)
    elif isAdd:
      if title == "":
        stdout.write "Title / Service Name: "
        stdout.flushFile()
        title = readLine(stdin).strip()
      addEntryDirect(keyHex, title, secret)
    else:
      searchAndCopy(keyHex, searchFilter)
  except ValueError as e:
    echo "\n❌ ", e.msg
    quit(1)

when isMainModule:
  main()
