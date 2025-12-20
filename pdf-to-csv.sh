#!/usr/bin/env bash

# @file pdf-to-csv.sh
# Take a PDF file of a credit card statement and convert it to a CSV file
# that's importable to something like Quiken Simplifi.
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/pfb/pfb.sh"

prerequisites() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        pfb error "This script is designed to run on macOS only."
        exit 1
    fi
    if ! command -v pdftotext &> /dev/null; then
        pfb error "pdftotext is not installed. Please install it using Homebrew: brew install poppler"
        exit 1
    fi
}

parse_pdf() {
    local date amount description count tags="" year
    local filtered_text_file

    year="$(date +%Y)"
    # shellcheck disable=2046
    filtered_text_file="$(mktemp /tmp/pdf-to-csv-$(date +%s).filtered.txt)"

    pfb spinner start "Converting PDF to text..."
    pdftotext -layout "$INPUT_FILE" "$TEMP_TXT_FILE" 2>/dev/null
    local exit_code=$?
    pfb spinner stop

    if [[ $exit_code -ne 0 ]]; then
        pfb error "Failed to convert PDF to text."
        rm -f "$TEMP_TXT_FILE"
        exit 1
    fi
    pfb success "PDF converted successfully"
    echo

    count=0

    # Assuming the PDF has a consistent format, grep for lines that look like
    # transaction entries starting with a date.
    # grep -E '^[0-9]{2}/[0-9]{2}/[0-9]{4}' "$TEMP_TXT_FILE" > "$filtered_text_file"
    grep -E '^[0-9]{2}/[0-9]{2}' "$TEMP_TXT_FILE" > "$filtered_text_file"

    echo '"Date","Payee","Amount","Tags"' > "$OUTPUT_FILE"

    pfb spinner start "Parsing transactions..."
    while read -r line; do
        # Split line: date, description, amount
        # Assume format like: 06/21/2025 1234567890 Grocery Store    -45.23

        # You may need to adjust this parsing if your statement differs
        date=$(echo "$line" | awk '{print $1}')
        date="$date/$year"  # Append the current year
        amount=$(echo "$line" | sed -nE 's/.*[[:space:]](-?\$?[0-9,]+\.[0-9]{2})$/\1/p')
        amount=$(echo "$amount" | tr -d '$,')
        # Flip the sign: turn positive to negative and vice versa
        if [[ "$amount" == -* ]]; then
            amount="${amount#-}"  # remove leading minus
        else
            amount="-$amount"     # prepend minus
        fi
        description=$(echo "$line" | \
            sed -E 's/^[0-9]{2}\/[0-9]{2}[[:space:]]+//' | \
            sed -E 's/[[:space:]]+-?\$?[0-9][0-9,]*\.[0-9][0-9]$//')
        # Clean up description by removing any bank reference #
        description=$(echo "$description" | sed -E 's/^[[:alnum:]]+[[:space:]]{2,}//')

        # Output as CSV row
        printf '"%s","%s","%s","%s"\n' "$date" "$description" "$amount" "$tags" \
            >> "$OUTPUT_FILE"
        count=$((count + 1))

    done < "$filtered_text_file"
    pfb spinner stop

    # Cleanup temporary files
    rm -f "$filtered_text_file" "$TEMP_TXT_FILE"

    # Report
    pfb success "CSV saved to $OUTPUT_FILE"
    pfb subheading "$count transactions parsed successfully"
}

main() {
    [[ -n $DEBUG ]] && set -x
    set -eou pipefail

    if [[ $# -ne 1 ]]; then
        pfb error "Usage: $0 <path-to-pdf-file>"
        exit 1
    fi

    prerequisites

    INPUT_FILE="$1"
    # shellcheck disable=2046
    TEMP_TXT_FILE="$(mktemp /tmp/pdf-to-csv-$(date +%s).txt)"
    OUTPUT_FILE="${INPUT_FILE%.pdf}.csv"

    pfb heading "Converting $(basename "$INPUT_FILE")"
    echo

    # Check if output file exists and confirm overwrite
    if [[ -f "$OUTPUT_FILE" ]]; then
        if ! pfb confirm "Output file already exists. Overwrite?"; then
            pfb info "Operation cancelled"
            exit 0
        fi
        rm "$OUTPUT_FILE"
        echo
    fi

    parse_pdf
}

# Run the script so it is being executed directly
[ "${BASH_SOURCE[0]}" -ef "$0" ] && main "$@"