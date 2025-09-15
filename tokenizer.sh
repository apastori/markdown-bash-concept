#!/usr/bin/env bash

## Markdown Tokenizer
# Supports both string input and file input

set -euo pipefail

source "$(dirname "$0")/env.sh" "$@"
source "$(dirname "$0")/log_utils.sh"

# Initialize log file
init_log "mdbashtoto.log"

# If verbose flag is up, then shift first parameter
if [ "$VERBOSE" -eq 1 ]; then
    shift
fi

if [ "$IS_OLD_MACHINE" -eq 0 ] && [ "$HAS_ASSOC" -eq 1 ]; then
    # Bash 4.0 or later: Use associative array
    declare -A TOKEN_TYPES=(
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
fi

# Main function
main() {
    local input="$1"

    if [[ -z "$input" ]]; then
        log_error "Usage: $0 <string|file>"
        log_error "Examples:"
        log_error "  $0 '# Hello World'"
        log_error "  $0 document.md"
        return 1
    fi

    # Check if input is a file or string
    if [[ -f "$input" ]]; then
        log "Tokenizing file: $input"
        tokenize_file "$input"
    else
        log "Tokenizing string: $input"
        tokenize_string "$input"
    fi
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    echo "${TOKENS[@]}"
fi

exit 0
