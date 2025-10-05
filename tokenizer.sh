#!/usr/bin/env bash

## Markdown Tokenizer
# Supports both string input and file input

set -euo pipefail

source "$(dirname "$0")/tokenize_utils.sh"

if [ "$IS_OLD_MACHINE" -eq 0 ] && [ "$HAS_ASSOC" -eq 1 ]; then
    # Bash 4.0 or later: Use associative array
    declare -A -x TOKEN_TYPES=(
        [HEADING]="HEADING"
        [PARAGRAPH]="PARAGRAPH"
        [CODE_BLOCK]="CODE_BLOCK"
        [CODE_INLINE]="CODE_INLINE"
        [BOLD]="BOLD"
        [ITALIC]="ITALIC"
        [BOLD_ITALIC]="BOLD_ITALIC"
        [LINK]="LINK"
        [IMAGE]="IMAGE"
        [UNORDERED_LIST_ITEM]="UNORDERED_LIST_ITEM"
        [ORDERED_LIST_ITEM]="ORDERED_LIST_ITEM"
        [BLOCKQUOTE]="BLOCKQUOTE"
        [HORIZONTAL_RULE]="HORIZONTAL_RULE"
        [LINE_BREAK]="LINE_BREAK"
        [TEXT]="TEXT"
        [EMPTY_LINE]="EMPTY_LINE"
    )
else
    # Bash < 4.0: Use space-separated string as fallback
    declare -r TOKEN_TYPES="HEADING PARAGRAPH CODE_BLOCK CODE_INLINE BOLD ITALIC BOLD_ITALIC LINK IMAGE UNORDERED_LIST_ITEM ORDERED_LIST_ITEM BLOCKQUOTE HORIZONTAL_RULE LINE_BREAK TEXT EMPTY_LINE"
    export TOKEN_TYPES
fi

# Main function
main() {
    local input_content="$1"
    local input_type="$2"
    # Check if input is a file or string
    if [ "$input_type" = "file" ]; then
        log "Tokenizing file: $input_content"
        tokenize_file "$input_content"
    elif [ "$input_type" = "string" ]; then
        log "Tokenizing string: $input_content"
        tokenize_string "$input_content"
    else
        log_err "Invalid input type: $input_type. Must be 'file' or 'string'."
        exit 1
    fi
}

# Run the script even if it is sourced
main "$@"

return 0
