# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Bash script for macOS that converts PDF credit card statements into CSV format compatible with Quicken Simplifi. The script extracts transaction data from PDFs and formats it with Date, Payee, Amount, and Tags columns.

## Requirements

- macOS only (checked at runtime in pdf-to-csv.sh:8-11)
- `pdftotext` from poppler-utils (install via `brew install poppler`)
- Standard Unix utilities: `awk`, `sed`, `grep`

## Usage

Run the script directly:
```bash
./pdf-to-csv.sh input.pdf
```

The output CSV file is created in the same directory as the input PDF with the `.csv` extension.

Enable debug mode:
```bash
DEBUG=1 ./pdf-to-csv.sh input.pdf
```

## Architecture

**Single-file bash script** (pdf-to-csv.sh) with three main functions:

1. **prerequisites()** - Validates macOS environment and checks for `pdftotext` binary
2. **parse_pdf()** - Core conversion logic:
   - Uses `pdftotext -layout` to extract text from PDF
   - Filters transaction lines with date pattern `^[0-9]{2}/[0-9]{2}`
   - Parses each line to extract: date (MM/DD, current year appended), description (cleaned of bank reference numbers), and amount
   - **Important**: Inverts transaction amounts (positive becomes negative, negative becomes positive) to represent expenses as negative values
   - Outputs CSV with headers: Date, Payee, Amount, Tags
3. **main()** - Entry point that orchestrates the workflow

## Key Implementation Details

- Script uses temporary files in `/tmp/` for intermediate text processing
- Transaction amount signs are flipped at pdf-to-csv.sh:52-57 to match Quicken Simplifi's expense convention
- Date format assumes MM/DD in PDF, current year is appended automatically
- Bank reference numbers are stripped from descriptions via regex at pdf-to-csv.sh:62
- The script is sourceable (doesn't execute unless called directly, check at pdf-to-csv.sh:98)

## Git Configuration

`.gitignore` excludes PDF and CSV files from version control.
