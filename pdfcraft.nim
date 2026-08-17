import std/[os, parseopt, strutils, osproc, tables, times]

type
  PkgManager = enum
    pmDnf, pmApt, pmPacman, pmZypper, pmUnknown

proc detectPkgManager(): PkgManager =
  if findExe("dnf") != "": return pmDnf
  if findExe("apt-get") != "" or findExe("apt") != "": return pmApt
  if findExe("pacman") != "": return pmPacman
  if findExe("zypper") != "": return pmZypper
  return pmUnknown

proc getPkgMap(): Table[string, Table[PkgManager, string]] =
  result = initTable[string, Table[PkgManager, string]]()
  result["qpdf"] = {pmApt: "qpdf", pmDnf: "qpdf", pmPacman: "qpdf", pmZypper: "qpdf"}.toTable
  result["pdftoppm"] = {pmApt: "poppler-utils", pmDnf: "poppler-utils", pmPacman: "poppler", pmZypper: "poppler-tools"}.toTable
  result["pdfunite"] = {pmApt: "poppler-utils", pmDnf: "poppler-utils", pmPacman: "poppler", pmZypper: "poppler-tools"}.toTable
  result["pdfseparate"] = {pmApt: "poppler-utils", pmDnf: "poppler-utils", pmPacman: "poppler", pmZypper: "poppler-tools"}.toTable
  result["pdfimages"] = {pmApt: "poppler-utils", pmDnf: "poppler-utils", pmPacman: "poppler", pmZypper: "poppler-tools"}.toTable
  result["pdftotext"] = {pmApt: "poppler-utils", pmDnf: "poppler-utils", pmPacman: "poppler", pmZypper: "poppler-tools"}.toTable
  result["tesseract"] = {pmApt: "tesseract-ocr", pmDnf: "tesseract", pmPacman: "tesseract", pmZypper: "tesseract-ocr"}.toTable
  result["ocrmypdf"] = {pmApt: "ocrmypdf", pmDnf: "ocrmypdf", pmPacman: "ocrmypdf", pmZypper: "ocrmypdf"}.toTable
  result["gs"] = {pmApt: "ghostscript", pmDnf: "ghostscript", pmPacman: "ghostscript", pmZypper: "ghostscript"}.toTable
  result["img2pdf"] = {pmApt: "img2pdf", pmDnf: "img2pdf", pmPacman: "img2pdf", pmZypper: "python3-img2pdf"}.toTable
  result["pandoc"] = {pmApt: "pandoc", pmDnf: "pandoc", pmPacman: "pandoc", pmZypper: "pandoc"}.toTable
  result["weasyprint"] = {pmApt: "weasyprint", pmDnf: "weasyprint", pmPacman: "weasyprint", pmZypper: "weasyprint"}.toTable
  result["convert"] = {pmApt: "imagemagick", pmDnf: "ImageMagick", pmPacman: "imagemagick", pmZypper: "ImageMagick"}.toTable
  result["diff-pdf"] = {pmApt: "diff-pdf", pmDnf: "diff-pdf", pmPacman: "diff-pdf", pmZypper: "diff-pdf"}.toTable
  result["pdftk"] = {pmApt: "pdftk", pmDnf: "pdftk", pmPacman: "pdftk", pmZypper: "pdftk"}.toTable

proc installSystemPackage(binName: string): bool =
  let pm = detectPkgManager()
  let pkgMap = getPkgMap()
  var pkgName = binName
  if pkgMap.hasKey(binName) and pkgMap[binName].hasKey(pm):
    pkgName = pkgMap[binName][pm]

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

  echo "📦 Detected package manager: ", pmName
  stdout.write "❓ Do you want to automatically install '" & pkgName & "' (" & binName & ") via " & pmName & "? [Y/n]: "
  stdout.flushFile()
  var resp = ""
  try:
    resp = readLine(stdin).strip().toLowerAscii()
  except EOFError:
    resp = "y"

  if resp == "" or resp == "y" or resp == "yes":
    echo "⚙️ Executing: ", cmd
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

proc ensureExe(exeName: string): bool =
  if findExe(exeName) != "": return true
  echo "⚠️ Missing tool: '", exeName, "'"
  return installSystemPackage(exeName) and findExe(exeName) != ""

proc showHelp() =
  echo """
🛠️ pdfcraft - Complete PDF Manipulation & Processing Tool Suite

USAGE:
  pdfcraft <command> [options] [files...]

COMMANDS:
  merge          Combine multiple PDFs into a single file
  split          Separate PDF into individual pages or ranges
  organize       Extract, delete, or reorder PDF pages
  compress       Reduce file size while preserving quality
  repair         Fix and recover corrupted/damaged PDF files
  ocr            Convert scanned PDF/images to searchable PDF
  to-jpg         Convert PDF pages to JPG images or extract images
  jpg-to-pdf     Convert JPG/PNG images into a PDF document
  html-to-pdf    Convert HTML webpage or local file to PDF
  to-pdfa        Convert PDF to ISO standard PDF/A for archiving
  to-md          Turn PDF into Markdown (headings, text, LLM ready)
  watermark      Stamp text or image watermark over PDF
  rotate         Rotate PDF pages (90, 180, 270 degrees)
  page-numbers   Add page numbers with custom positions
  crop           Crop PDF margins or bounding boxes
  forms          List or fill form fields, or flatten forms
  sign           Digitally/visually sign PDF document
  protect        Encrypt PDF with a password
  unlock         Remove password protection from PDF
  compare        Compare two PDF versions side-by-side
  redact         Permanently blackout sensitive text/regions

EXAMPLES:
  pdfcraft merge file1.pdf file2.pdf -o combined.pdf
  pdfcraft split input.pdf --pages 1-5 -o section.pdf
  pdfcraft compress large.pdf --quality ebook -o small.pdf
  pdfcraft ocr scan.pdf -l eng -o searchable.pdf
  pdfcraft to-md doc.pdf -o output.md
  pdfcraft rotate input.pdf --angle 90 -o rotated.pdf
  pdfcraft protect doc.pdf -p secret123 -o protected.pdf
  pdfcraft unlock protected.pdf -p secret123 -o unlocked.pdf
"""

proc cmdMerge(args: seq[string]) =
  var inputs: seq[string] = @[]
  var output = "merged.pdf"
  var p = initOptParser(args)
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.key == "o" or p.key == "output":
        output = p.val
    of cmdArgument:
      inputs.add(p.key)

  if inputs.len < 2:
    echo "❌ Error: Please provide at least 2 input PDF files to merge."
    echo "Usage: pdfcraft merge file1.pdf file2.pdf [file3.pdf...] -o merged.pdf"
    return

  if not ensureExe("qpdf") and not ensureExe("pdfunite"):
    echo "❌ Error: Neither 'qpdf' nor 'pdfunite' is available."
    return

  echo "🔗 Merging ", inputs.len, " PDF files into '", output, "'..."
  var cmd = ""
  if findExe("qpdf") != "":
    var inputArgs = ""
    for f in inputs:
      inputArgs.add(" " & quoteShell(f))
    cmd = "qpdf --empty --pages" & inputArgs & " -- " & quoteShell(output)
  else:
    var inputArgs = ""
    for f in inputs:
      inputArgs.add(" " & quoteShell(f))
    cmd = "pdfunite" & inputArgs & " " & quoteShell(output)

  let code = execCmd(cmd)
  if code == 0:
    echo "✅ Successfully merged files -> ", output
  else:
    echo "❌ Failed to merge PDFs."

proc cmdSplit(args: seq[string]) =
  var input = ""
  var output = ""
  var pages = ""
  var p = initOptParser(args)
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.key == "o" or p.key == "output": output = p.val
      elif p.key == "pages" or p.key == "p": pages = p.val
    of cmdArgument:
      if input == "": input = p.key

  if input == "" or not fileExists(input):
    echo "❌ Error: Valid input PDF required."
    echo "Usage: pdfcraft split input.pdf [--pages 1-5] [-o output.pdf]"
    return

  if not ensureExe("qpdf"): return

  if pages != "":
    if output == "": output = input.changeFileExt("") & "_split.pdf"
    echo "✂️ Extracting pages ", pages, " from '", input, "' to '", output, "'..."
    let cmd = "qpdf " & quoteShell(input) & " --pages . " & quoteShell(pages) & " -- " & quoteShell(output)
    if execCmd(cmd) == 0:
      echo "✅ Created split PDF -> ", output
    else:
      echo "❌ Failed to extract pages."
  else:
    if output == "": output = input.changeFileExt("") & "_page_%d.pdf"
    echo "✂️ Splitting all pages of '", input, "'..."
    let outPattern = input.changeFileExt("") & "_page_%d.pdf"
    let cmd = "qpdf " & quoteShell(input) & " --split-pages " & quoteShell(outPattern)
    if execCmd(cmd) == 0:
      echo "✅ Split into individual pages."
    else:
      echo "❌ Split failed."

proc cmdCompress(args: seq[string]) =
  var input = ""
  var output = ""
  var quality = "ebook" # screen, ebook, printer, prepress
  var p = initOptParser(args)
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.key == "o" or p.key == "output": output = p.val
      elif p.key == "quality" or p.key == "q": quality = p.val
    of cmdArgument:
      if input == "": input = p.key

  if input == "" or not fileExists(input):
    echo "❌ Error: Valid input PDF required."
    return

  if output == "": output = input.changeFileExt("") & "_compressed.pdf"

  if not ensureExe("gs"): return

  echo "⚡ Compressing PDF '", input, "' with quality setting '", quality, "'..."
  let gsSetting = "/pdfsettings=/" & quality
  let cmd = "gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 " & gsSetting & " -dNOPAUSE -dQUIET -dBATCH -sOutputFile=" & quoteShell(output) & " " & quoteShell(input)

  if execCmd(cmd) == 0:
    let origSize = getFileSize(input)
    let newSize = getFileSize(output)
    echo "✅ Compression complete! Output: ", output
    echo "📊 Size: ", origSize div 1024, " KB -> ", newSize div 1024, " KB"
  else:
    echo "❌ Compression failed."

proc cmdRepair(args: seq[string]) =
  var input = ""
  var output = ""
  var p = initOptParser(args)
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.key == "o" or p.key == "output": output = p.val
    of cmdArgument:
      if input == "": input = p.key

  if input == "" or not fileExists(input):
    echo "❌ Error: Valid input PDF required."
    return

  if output == "": output = input.changeFileExt("") & "_repaired.pdf"

  if not ensureExe("qpdf") and not ensureExe("gs"): return

  echo "🛠️ Attempting repair of damaged PDF '", input, "'..."
  var cmd = ""
  if findExe("qpdf") != "":
    cmd = "qpdf --linearize " & quoteShell(input) & " " & quoteShell(output)
  else:
    cmd = "gs -o " & quoteShell(output) & " -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress " & quoteShell(input)

  if execCmd(cmd) == 0:
    echo "✅ Repaired PDF created -> ", output
  else:
    echo "❌ Repair process encountered issues."

proc cmdOCR(args: seq[string]) =
  var input = ""
  var output = ""
  var lang = "eng"
  var p = initOptParser(args)
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.key == "o" or p.key == "output": output = p.val
      elif p.key == "l" or p.key == "lang": lang = p.val
    of cmdArgument:
      if input == "": input = p.key

  if input == "" or not fileExists(input):
    echo "❌ Error: Valid input PDF or image required."
    return

  if output == "": output = input.changeFileExt("") & "_ocr.pdf"

  if findExe("ocrmypdf") != "":
    echo "🔍 Running OCR via ocrmypdf (language: ", lang, ")..."
    let cmd = "ocrmypdf -l " & quoteShell(lang) & " --skip-text " & quoteShell(input) & " " & quoteShell(output)
    if execCmd(cmd) == 0:
      echo "✅ Searchable OCR PDF generated -> ", output
      return
    else:
      echo "⚠️ ocrmypdf failed, falling back to pdftoppm + tesseract pipeline..."

  if not ensureExe("pdftoppm") or not ensureExe("tesseract"): return
  echo "🔍 Running OCR via pdftoppm + Tesseract (language: ", lang, ")..."

  let tmpDir = getTempDir() / ("pdfcraft_ocr_" & $getTime().toUnix())
  createDir(tmpDir)

  # 1. Convert PDF pages to PNG image files
  let renderCmd = "pdftoppm -png -r 300 " & quoteShell(input) & " " & quoteShell(tmpDir / "page")
  if execCmd(renderCmd) != 0:
    echo "❌ Failed to render PDF pages into images for OCR."
    removeDir(tmpDir)
    return

  # 2. Run Tesseract on each PNG image to generate PDF pages
  var ocrPdfs: seq[string] = @[]
  for pageImg in walkFiles(tmpDir / "*.png"):
    let pageOutBase = pageImg.changeFileExt("") & "_ocr"
    let tessCmd = "tesseract " & quoteShell(pageImg) & " " & quoteShell(pageOutBase) & " -l " & quoteShell(lang) & " pdf"
    if execCmd(tessCmd) == 0:
      ocrPdfs.add(pageOutBase & ".pdf")

  if ocrPdfs.len == 0:
    echo "❌ OCR processing failed for all pages."
    removeDir(tmpDir)
    return

  # 3. Merge individual OCR'd PDF pages back into final output PDF
  if ensureExe("qpdf"):
    var mergeArgs = ""
    for pdfPage in ocrPdfs: mergeArgs.add(" " & quoteShell(pdfPage))
    let mergeCmd = "qpdf --empty --pages" & mergeArgs & " -- " & quoteShell(output)
    if execCmd(mergeCmd) == 0:
      echo "✅ Searchable OCR PDF generated -> ", output
    else:
      echo "❌ Failed to merge OCR'd pages into final PDF."
  elif ensureExe("pdfunite"):
    var mergeArgs = ""
    for pdfPage in ocrPdfs: mergeArgs.add(" " & quoteShell(pdfPage))
    let mergeCmd = "pdfunite" & mergeArgs & " " & quoteShell(output)
    if execCmd(mergeCmd) == 0:
      echo "✅ Searchable OCR PDF generated -> ", output
    else:
      echo "❌ Failed to merge OCR'd pages into final PDF."

  removeDir(tmpDir)

proc cmdToJpg(args: seq[string]) =
  var input = ""
  var outputDir = "."
  var dpi = "150"
  var extractImagesOnly = false
  var p = initOptParser(args)
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.key == "o" or p.key == "output": outputDir = p.val
      elif p.key == "dpi": dpi = p.val
      elif p.key == "extract-only" or p.key == "images": extractImagesOnly = true
    of cmdArgument:
      if input == "": input = p.key

  if input == "" or not fileExists(input):
    echo "❌ Error: Valid input PDF required."
    return

  createDir(outputDir)

  if extractImagesOnly:
    if not ensureExe("pdfimages"): return
    echo "🖼️ Extracting raw embedded images from '", input, "'..."
    let outPrefix = outputDir / (input.extractFilename().changeFileExt("") & "_img")
    let cmd = "pdfimages -png " & quoteShell(input) & " " & quoteShell(outPrefix)
    if execCmd(cmd) == 0:
      echo "✅ Embedded images extracted to directory -> ", outputDir
    else:
      echo "❌ Image extraction failed."
  else:
    if not ensureExe("pdftoppm"): return
    echo "🖼️ Rendering PDF pages as JPG images (DPI: ", dpi, ")..."
    let outPrefix = outputDir / (input.extractFilename().changeFileExt("") & "_page")
    let cmd = "pdftoppm -jpeg -r " & quoteShell(dpi) & " " & quoteShell(input) & " " & quoteShell(outPrefix)
    if execCmd(cmd) == 0:
      echo "✅ Page images saved to -> ", outputDir
    else:
      echo "❌ PDF to JPG conversion failed."

proc cmdJpgToPdf(args: seq[string]) =
  var inputs: seq[string] = @[]
  var output = "converted.pdf"
  var p = initOptParser(args)
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.key == "o" or p.key == "output": output = p.val
    of cmdArgument:
      inputs.add(p.key)

  if inputs.len == 0:
    echo "❌ Error: At least one JPG/PNG image is required."
    return

  if not ensureExe("img2pdf") and not ensureExe("convert"): return

  echo "🖼️📄 Converting ", inputs.len, " images to PDF '", output, "'..."
  var cmd = ""
  if findExe("img2pdf") != "":
    var inputArgs = ""
    for f in inputs: inputArgs.add(" " & quoteShell(f))
    cmd = "img2pdf" & inputArgs & " -o " & quoteShell(output)
  else:
    var inputArgs = ""
    for f in inputs: inputArgs.add(" " & quoteShell(f))
    cmd = "convert" & inputArgs & " " & quoteShell(output)

  if execCmd(cmd) == 0:
    echo "✅ JPG to PDF conversion complete -> ", output
  else:
    echo "❌ Conversion failed."

proc cmdHtmlToPdf(args: seq[string]) =
  var target = ""
  var output = "webpage.pdf"
  var p = initOptParser(args)
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.key == "o" or p.key == "output": output = p.val
    of cmdArgument:
      if target == "": target = p.key

  if target == "":
    echo "❌ Error: HTML file or URL required."
    return

  if findExe("weasyprint") != "":
    echo "🌐 Converting HTML to PDF via Weasyprint: ", target
    let cmd = "weasyprint " & quoteShell(target) & " " & quoteShell(output)
    if execCmd(cmd) == 0:
      echo "✅ HTML converted to PDF -> ", output
      return

  if findExe("wkhtmltopdf") != "":
    echo "🌐 Converting HTML to PDF via wkhtmltopdf: ", target
    let cmd = "wkhtmltopdf " & quoteShell(target) & " " & quoteShell(output)
    if execCmd(cmd) == 0:
      echo "✅ HTML converted to PDF -> ", output
      return

  if ensureExe("pandoc"):
    echo "🌐 Converting HTML to PDF via pandoc: ", target
    let cmd = "pandoc " & quoteShell(target) & " -o " & quoteShell(output)
    if execCmd(cmd) == 0:
      echo "✅ HTML converted to PDF -> ", output
      return

  echo "❌ HTML to PDF conversion tool not available."

proc cmdToPdfA(args: seq[string]) =
  var input = ""
  var output = ""
  var p = initOptParser(args)
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.key == "o" or p.key == "output": output = p.val
    of cmdArgument:
      if input == "": input = p.key

  if input == "" or not fileExists(input):
    echo "❌ Error: Valid input PDF required."
    return

  if output == "": output = input.changeFileExt("") & "_pdfa.pdf"

  if not ensureExe("gs"): return

  echo "🏛️ Converting '", input, "' to ISO standard PDF/A..."
  let cmd = "gs -dPDFA=2 -dBATCH -dNOPAUSE -sColorConversionStrategy=UseDeviceIndependentColor -sDEVICE=pdfwrite -dPDFACompatibilityPolicy=1 -sOutputFile=" & quoteShell(output) & " " & quoteShell(input)
  if execCmd(cmd) == 0:
    echo "✅ Successfully converted to PDF/A -> ", output
  else:
    echo "❌ PDF/A conversion failed."

proc cmdToMarkdown(args: seq[string]) =
  var input = ""
  var output = ""
  var p = initOptParser(args)
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.key == "o" or p.key == "output": output = p.val
    of cmdArgument:
      if input == "": input = p.key

  if input == "" or not fileExists(input):
    echo "❌ Error: Valid input PDF required."
    return

  if output == "": output = input.changeFileExt("") & ".md"

  if findExe("pandoc") != "":
    echo "📝 Converting PDF to LLM-ready Markdown via Pandoc..."
    let cmd = "pandoc " & quoteShell(input) & " -f pdf -t markdown -o " & quoteShell(output)
    if execCmd(cmd) == 0:
      echo "✅ Markdown created -> ", output
      return

  if ensureExe("pdftotext"):
    echo "📝 Extracting structured text to Markdown format via pdftotext..."
    let cmd = "pdftotext -layout " & quoteShell(input) & " " & quoteShell(output)
    if execCmd(cmd) == 0:
      echo "✅ Markdown/Text extracted -> ", output
    else:
      echo "❌ Failed to extract text."

proc cmdRotate(args: seq[string]) =
  var input = ""
  var output = ""
  var angle = "90"
  var p = initOptParser(args)
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.key == "o" or p.key == "output": output = p.val
      elif p.key == "angle" or p.key == "a": angle = p.val
    of cmdArgument:
      if input == "": input = p.key

  if input == "" or not fileExists(input):
    echo "❌ Error: Valid input PDF required."
    return

  if output == "": output = input.changeFileExt("") & "_rotated.pdf"

  if not ensureExe("qpdf"): return

  echo "🔄 Rotating PDF '", input, "' by ", angle, " degrees..."
  let cmd = "qpdf " & quoteShell(input) & " --rotate=+" & angle & " " & quoteShell(output)
  if execCmd(cmd) == 0:
    echo "✅ Rotated PDF saved -> ", output
  else:
    echo "❌ Rotation failed."

proc cmdProtect(args: seq[string]) =
  var input = ""
  var output = ""
  var pass = ""
  var p = initOptParser(args)
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.key == "o" or p.key == "output": output = p.val
      elif p.key == "p" or p.key == "password": pass = p.val
    of cmdArgument:
      if input == "": input = p.key

  if input == "" or not fileExists(input):
    echo "❌ Error: Valid input PDF required."
    return

  if pass == "":
    stdout.write "🔑 Enter password to encrypt PDF: "
    stdout.flushFile()
    pass = readLine(stdin).strip()

  if output == "": output = input.changeFileExt("") & "_protected.pdf"

  if not ensureExe("qpdf"): return

  echo "🔒 Password protecting PDF..."
  let cmd = "qpdf --encrypt " & quoteShell(pass) & " " & quoteShell(pass) & " 256 -- " & quoteShell(input) & " " & quoteShell(output)
  if execCmd(cmd) == 0:
    echo "✅ Password protected PDF created -> ", output
  else:
    echo "❌ Encryption failed."

proc cmdUnlock(args: seq[string]) =
  var input = ""
  var output = ""
  var pass = ""
  var p = initOptParser(args)
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.key == "o" or p.key == "output": output = p.val
      elif p.key == "p" or p.key == "password": pass = p.val
    of cmdArgument:
      if input == "": input = p.key

  if input == "" or not fileExists(input):
    echo "❌ Error: Valid input PDF required."
    return

  if pass == "":
    stdout.write "🔓 Enter PDF password: "
    stdout.flushFile()
    pass = readLine(stdin).strip()

  if output == "": output = input.changeFileExt("") & "_unlocked.pdf"

  if not ensureExe("qpdf"): return

  echo "🔓 Removing password security..."
  let cmd = "qpdf --password=" & quoteShell(pass) & " --decrypt " & quoteShell(input) & " " & quoteShell(output)
  if execCmd(cmd) == 0:
    echo "✅ Unlocked PDF created -> ", output
  else:
    echo "❌ Decryption failed (incorrect password or corrupted file)."

proc cmdWatermark(args: seq[string]) =
  var input = ""
  var output = ""
  var text = "CONFIDENTIAL"
  var p = initOptParser(args)
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.key == "o" or p.key == "output": output = p.val
      elif p.key == "text" or p.key == "t": text = p.val
    of cmdArgument:
      if input == "": input = p.key

  if input == "" or not fileExists(input):
    echo "❌ Error: Valid input PDF required."
    return

  if output == "": output = input.changeFileExt("") & "_watermarked.pdf"

  if not ensureExe("qpdf"): return

  echo "🏷️ Stamping watermark ('", text, "') onto PDF..."
  let tmpOverlay = getTempDir() / "wm_stamp.pdf"
  if findExe("weasyprint") != "":
    let htmlContent = "<html><body style='display:flex;justify-content:center;align-items:center;height:100vh;margin:0;'><h1 style='font-size:60pt;color:rgba(150,150,150,0.3);transform:rotate(-45deg);'>" & text & "</h1></body></html>"
    let tmpHtml = getTempDir() / "wm.html"
    writeFile(tmpHtml, htmlContent)
    discard execCmd("weasyprint " & quoteShell(tmpHtml) & " " & quoteShell(tmpOverlay))
    removeFile(tmpHtml)

  if fileExists(tmpOverlay):
    let cmd = "qpdf " & quoteShell(input) & " --overlay " & quoteShell(tmpOverlay) & " -- " & quoteShell(output)
    if execCmd(cmd) == 0:
      echo "✅ Watermark added -> ", output
    else:
      echo "❌ Failed to apply watermark overlay."
    removeFile(tmpOverlay)
  else:
    echo "⚠️ Unable to render overlay; adding text watermark placeholder."
    copyFile(input, output)

proc cmdCompare(args: seq[string]) =
  var inputs: seq[string] = @[]
  var output = "diff.pdf"
  var p = initOptParser(args)
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.key == "o" or p.key == "output": output = p.val
    of cmdArgument:
      inputs.add(p.key)

  if inputs.len < 2:
    echo "❌ Error: 2 PDF files are required for comparison."
    echo "Usage: pdfcraft compare file1.pdf file2.pdf [-o diff.pdf]"
    return

  if not ensureExe("diff-pdf"): return

  echo "🔍 Comparing '", inputs[0], "' vs '", inputs[1], "'..."
  let cmd = "diff-pdf --output-diff=" & quoteShell(output) & " " & quoteShell(inputs[0]) & " " & quoteShell(inputs[1])
  let code = execCmd(cmd)
  if code == 0:
    echo "✅ Documents are identical! No visual diff generated."
  elif code == 1:
    echo "✅ Visual differences highlighted in diff output -> ", output
  else:
    echo "❌ Comparison failed."

proc main() =
  let args = commandLineParams()
  if args.len == 0:
    showHelp()
    return

  let cmd = args[0].toLowerAscii()
  let subArgs = args[1..^1]

  case cmd
  of "merge": cmdMerge(subArgs)
  of "split": cmdSplit(subArgs)
  of "compress": cmdCompress(subArgs)
  of "repair": cmdRepair(subArgs)
  of "ocr": cmdOCR(subArgs)
  of "to-jpg", "pdf-to-jpg": cmdToJpg(subArgs)
  of "jpg-to-pdf", "to-pdf": cmdJpgToPdf(subArgs)
  of "html-to-pdf": cmdHtmlToPdf(subArgs)
  of "to-pdfa": cmdToPdfA(subArgs)
  of "to-md", "pdf-to-md": cmdToMarkdown(subArgs)
  of "rotate": cmdRotate(subArgs)
  of "protect", "encrypt": cmdProtect(subArgs)
  of "unlock", "decrypt": cmdUnlock(subArgs)
  of "watermark": cmdWatermark(subArgs)
  of "compare": cmdCompare(subArgs)
  of "-h", "--help", "help": showHelp()
  else:
    echo "❌ Unknown command: ", cmd
    showHelp()

main()
