#!/usr/bin/env bash
# @file pdf-to-csv.sh
# Take a PDF file of a credit card statement and convert it to a CSV file
# that's importable to something like Quiken Simplifi.
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>

prerequisites() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo "This script is designed to run on macOS only."
        exit 1
    fi
    if ! command -v pdftotext &> /dev/null; then
        echo "pdftotext is not installed. Please install it using Homebrew: brew install poppler"
        exit 1
    fi
}

parse_pdf() {
    local date amount description count tags="" year
    local tmp_text_file

    year="$(date +%Y)"
    # shellcheck disable=2046
    tmp_text_file="$(mktemp /tmp/pdf-to-csv-$(date +%s).tmp.txt)"

    pdftotext -layout "$INPUT_FILE" "$TEMP_TXT_FILE"
    
    # shellcheck disable=2181
    if [[ $? -ne 0 ]]; then
        echo "Failed to convert PDF to text."
        exit 1
    fi

    count=0

    # Assuming the PDF has a consistent format, grep for lines that look like
    # transaction entries starting with a date.
    # grep -E '^[0-9]{2}/[0-9]{2}/[0-9]{4}' "$TEMP_TXT_FILE" > "$tmp_text_file"
    grep -E '^[0-9]{2}/[0-9]{2}' "$TEMP_TXT_FILE" > "$tmp_text_file"

    echo '"Date","Payee","Amount","Tags"' > "$OUTPUT_FILE"

    while read -r line; do
        # Split line: date, description, amount
        # Assume format like: 06/21/2025 1234567890 Grocery Store    -45.23

        # You may need to adjust this parsing if your statement differs
        date=$(echo "$line" | awk '{print $1}')
        date="$date/$year"  # Append the current year
        amount=$(echo "$line" | sed -nE 's/.*[[:space:]](-?\$?[0-9,]+\.[0-9]{2})$/\1/p')
        amount=$(echo "$amount" | tr -d '$,')
        description=$(echo "$line" | \
            sed -E 's/^[0-9]{2}\/[0-9]{2}[[:space:]]+//' | \
            sed -E 's/[[:space:]]+-?\$?[0-9][0-9,]*\.[0-9][0-9]$//')
        # Clean up description by removing any bank reference #
        description=$(echo "$description" | sed -E 's/^[[:alnum:]]+[[:space:]]{2,}//')

        # Output as CSV row
        printf '"%s","%s","%s","%s"\n' "$date" "$description" "$amount" "$tags" \
            >> "$OUTPUT_FILE"
        count=$((count + 1))

    done < "$tmp_text_file"

    # Report
    echo "✅ CSV saved to $OUTPUT_FILE"
    echo "📊 $count transactions parsed successfully."
}

main() {
    [[ -n $DEBUG ]] && set -x
    set -eou pipefail

    if [[ $# -ne 1 ]]; then
        echo "Usage: $0 <path-to-pdf-file>"
        exit 1
    fi

    prerequisites

    INPUT_FILE="$1"
    # shellcheck disable=2046
    TEMP_TXT_FILE="$(mktemp /tmp/pdf-to-csv-$(date +%s).txt)"
    OUTPUT_FILE="${INPUT_FILE%.pdf}.csv"

    rm "$OUTPUT_FILE" 2>/dev/null || true

    parse_pdf
}

# Run the script so it is being executed directly
[ "${BASH_SOURCE[0]}" -ef "$0" ] && main "$@"
