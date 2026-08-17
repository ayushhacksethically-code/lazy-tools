# 📄 `pdfcraft` Documentation

`pdfcraft` is a lightweight, single-binary CLI tool for Linux written in **Nim** to perform all common PDF operations offline & privately.

---

## 🚀 Features & Commands

### 1. Merge & Split
```bash
# Combine multiple PDFs
pdfcraft merge doc1.pdf doc2.pdf doc3.pdf -o merged.pdf

# Extract specific page ranges
pdfcraft split document.pdf --pages 1-5,8 -o section.pdf

# Split every page into separate PDF files
pdfcraft split document.pdf
```

### 2. Compress & Repair
```bash
# Reduce PDF size (quality options: screen, ebook, printer, prepress)
pdfcraft compress large_document.pdf --quality ebook -o compressed.pdf

# Repair corrupted or damaged PDF structure
pdfcraft repair damaged.pdf -o fixed.pdf
```

### 3. OCR & Format Conversions
```bash
# Make scanned PDF text searchable and selectable
pdfcraft ocr scan.pdf -l eng+hin -o searchable.pdf

# Convert PDF pages to JPG images
pdfcraft to-jpg report.pdf -o ./output_images/ --dpi 200

# Convert JPG/PNG images to single PDF
pdfcraft jpg-to-pdf img1.jpg img2.png -o album.pdf

# Convert HTML webpage to PDF
pdfcraft html-to-pdf https://example.com -o webpage.pdf

# Convert PDF to ISO Standard PDF/A for archiving
pdfcraft to-pdfa doc.pdf -o archive.pdf

# Convert PDF to Markdown (LLM & notes ready)
pdfcraft to-md paper.pdf -o notes.md
```

### 4. Security & Watermark
```bash
# Password encrypt PDF (AES-256)
pdfcraft protect secret.pdf -p "MyPass123" -o protected.pdf

# Decrypt password protected PDF
pdfcraft unlock protected.pdf -p "MyPass123" -o unlocked.pdf

# Stamp text watermark
pdfcraft watermark input.pdf --text "CONFIDENTIAL" -o stamped.pdf

# Side-by-side visual PDF comparison
pdfcraft compare version1.pdf version2.pdf -o diff.pdf
```
