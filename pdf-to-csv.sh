#!/usr/bin/env bash
# @file pdf-to-csv.sh
# @brief Convert a credit card statement PDF to a Quicken Simplifi-compatible CSV.
# @author Alister Lewis-Bowen <alister@lewis-bowen.org>
# @version 1.2.0
# @date 2026-06-30
# @license MIT
#
# @usage pdf-to-csv.sh <path-to-pdf-file>
#
# @dependencies
#   pfb        - Terminal feedback library (https://github.com/ali5ter/pfb)
#   pdftotext  - Part of poppler-utils (brew install poppler)
#
# @exitcodes
#   0  Success
#   1  Error (wrong OS, missing dependency, bad input, conversion failure)

prerequisites() {
    if ! command -v pfb &> /dev/null; then
        echo "ERROR: pfb is not installed. See https://github.com/ali5ter/pfb" >&2
        exit 1
    fi
    if [[ "$OSTYPE" != "darwin"* ]]; then
        pfb error "This script is designed to run on macOS only."
        exit 1
    fi
    if ! command -v pdftotext &> /dev/null; then
        pfb error "pdftotext is not installed. Please install it using Homebrew: brew install poppler"
        exit 1
    fi
}

# @param $1  Path to the input PDF file (INPUT_FILE must be set)
# @side_effects Writes OUTPUT_FILE; removes temporary files
parse_pdf() {
    local date amount description count tags="" year tx_month tx_year
    local filtered_text_file
    local statement_month statement_year

    # Derive statement month/year from filename (expects *MMDDYYYY.pdf convention).
    # Transactions whose month is later than the statement month belong to the prior year
    # (e.g. December charges appearing on a February statement are from last year).
    if [[ "$(basename "$INPUT_FILE")" =~ ([0-9]{2})([0-9]{2})([0-9]{4})\.(pdf|PDF)$ ]]; then
        statement_month="${BASH_REMATCH[1]#0}"   # strip leading zero → 1-12
        statement_year="${BASH_REMATCH[3]}"
    else
        # Fallback: assume statement closed this month
        statement_month="$(date +%-m)"
        statement_year="$(date +%Y)"
    fi
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

    grep -E '^[0-9]{2}/[0-9]{2}' "$TEMP_TXT_FILE" > "$filtered_text_file"

    # Use Simplifi's required headers: Date,Payee,Amount,Category,Tags,Notes,Check_No
    echo '"Date","Payee","Amount","Category","Tags","Notes","Check_No"' > "$OUTPUT_FILE"

    pfb spinner start "Parsing transactions..."
    while read -r line; do
        date=$(echo "$line" | awk '{print $1}')
        # Format as M/D/YYYY (4-digit year required by Simplifi).
        # A transaction month later than the statement month must be from the prior year.
        tx_month="${date%%/*}"
        tx_month="${tx_month#0}"   # strip leading zero
        if [[ "$tx_month" -gt "$statement_month" ]]; then
            tx_year=$(( statement_year - 1 ))
        else
            tx_year="$statement_year"
        fi
        date="$date/$tx_year"

        amount=$(echo "$line" | sed -nE 's/.*[[:space:]](-?\$?[0-9,]+\.[0-9]{2})$/\1/p')
        # Remove $ and commas as required by Simplifi
        amount=$(echo "$amount" | tr -d '$,')

        # Simplifi expects negative for expenses; flip the sign from statement
        if [[ "$amount" == -* ]]; then
            amount="${amount#-}"
        else
            amount="-$amount"
        fi

        description=$(echo "$line" | \
            sed -E 's/^[0-9]{2}\/[0-9]{2}[[:space:]]+//' | \
            sed -E 's/[[:space:]]+-?\$?[0-9][0-9,]*\.[0-9][0-9]$//')
        # Remove bank reference numbers from description
        description=$(echo "$description" | sed -E 's/^[[:alnum:]]+[[:space:]]{2,}//')

        printf '"%s","%s","%s","%s","%s","%s","%s"\n' \
            "$date" "$description" "$amount" "" "" "" "" \
            >> "$OUTPUT_FILE"
        count=$((count + 1))

    done < "$filtered_text_file"
    pfb spinner stop

    rm -f "$filtered_text_file" "$TEMP_TXT_FILE"

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

[ "${BASH_SOURCE[0]}" -ef "$0" ] && main "$@"
