# pdf-to-csv

A simple Bash script for macOS to convert PDF statements into a csv format. This particular csv format is compatible with Quicken Simplifi.

## Features

- Extracts data from PDF files
- Converts data to Quicken Simplifi-compatible CSV format
- Easy to use from the command line

## Requirements

- macOS
- `bash`
- `pdftotext` (part of [poppler-utils](https://poppler.freedesktop.org/))
- `awk`, `sed`, and other standard Unix utilities

## Usage

```bash
./pdf-to-csv.sh input.pdf
```

- `input.pdf`: The PDF statement to convert  
- The resulting CSV file will be created automatically in the same directory as the input PDF, with a similar name.

## Installation

1. Clone this repository:

    ```bash
    git clone https://github.com/ali5ter/pdf-to-csv.git
    cd pdf-to-csv
    ```

2. Make the script executable:

    ```bash
    chmod +x pdf-to-csv.sh
    ```

## Example

```bash
./pdf-to-csv.sh statement.pdf
```

This will generate `statement.csv` in the same directory.

## License

MIT License

## Disclaimer

This script is provided as-is. Please verify the output before importing into Simplifi.
