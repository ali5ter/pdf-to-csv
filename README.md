# pdf-to-csv

A simple Bash script for macOS to convert PDF statements into CSV format for Quicken Simplifi import.
Uses the correct Simplifi import format (which differs from their documentation).

## Features

- Extracts transaction data from PDF files
- Converts to Quicken Simplifi-compatible CSV format with proper headers and formatting
- Interactive confirmation before overwriting files
- Visual feedback with spinners and colored status messages
- Easy to use from the command line

## Requirements

- macOS
- `bash` 4.0+
- `pdftotext` (part of [poppler-utils](https://poppler.freedesktop.org/))
- `awk`, `sed`, and other standard Unix utilities
- [pfb](https://github.com/ali5ter/pfb) - terminal feedback library (must be installed and on `PATH`)

## Installation

1. Clone this repository:

    ```bash
    git clone https://github.com/ali5ter/pdf-to-csv.git
    cd pdf-to-csv
    ```

2. Install dependencies:

    ```bash
    brew install poppler
    ```

    Install [pfb](https://github.com/ali5ter/pfb) and ensure it is available on your `PATH`.

3. Make the script executable:

    ```bash
    chmod +x pdf-to-csv.sh
    ```

## Usage

```bash
./pdf-to-csv.sh input.pdf
```

- `input.pdf`: The PDF statement to convert
- The resulting CSV file is created in the same directory as the input PDF with a matching name.

## Example

```bash
./pdf-to-csv.sh statement.pdf
```

This will generate `statement.csv` in the same directory.

## Output Format

The script generates CSV files in the correct Quicken Simplifi import format:

- **Headers**: Date,Payee,Amount,Category,Tags,Notes,Check_No
- **Date format**: M/D/YYYY (4-digit year required)
- **Amount format**: No `$` or commas, negative for expenses (e.g., `-50.00`)
- **All fields quoted**: Ensures compatibility with Simplifi's import
- **Category field**: Left empty (will import as "Uncategorized" in Simplifi)

**Note**: Simplifi's documentation incorrectly shows 2-digit years (M/D/YY),
but the actual import requires 4-digit years (M/D/YYYY).

## License

MIT License

## Disclaimer

This script is provided as-is. Please verify the output before importing into Simplifi.
