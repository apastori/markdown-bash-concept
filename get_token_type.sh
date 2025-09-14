#!/usr/bin/env bash

set -euo pipefail

get_token_type() {
    local token_name="$1"

    if [[ $IS_OLD_MACHINE -eq 0 && $HAS_ASSOC -eq 1 ]]; then
        # Modern Bash with associative arrays
        echo "${TOKEN_TYPES[$token_name]}"
    else
        # Old Bash - use positional lookup in string
        case "$token_name" in
            "HEADING") echo "$(echo $TOKEN_TYPES | cut -d' ' -f1)" ;;
            "PARAGRAPH") echo "$(echo $TOKEN_TYPES | cut -d' ' -f2)" ;;
            "CODE_BLOCK") echo "$(echo $TOKEN_TYPES | cut -d' ' -f3)" ;;
            "CODE_INLINE") echo "$(echo $TOKEN_TYPES | cut -d' ' -f4)" ;;
            "BOLD") echo "$(echo $TOKEN_TYPES | cut -d' ' -f5)" ;;
            "ITALIC") echo "$(echo $TOKEN_TYPES | cut -d' ' -f6)" ;;
            "BOLD_ITALIC") echo "$(echo $TOKEN_TYPES | cut -d' ' -f7)" ;;
            "LINK") echo "$(echo $TOKEN_TYPES | cut -d' ' -f8)" ;;
            "IMAGE") echo "$(echo $TOKEN_TYPES | cut -d' ' -f9)" ;;
            "UNORDERED_LIST_ITEM") echo "$(echo $TOKEN_TYPES | cut -d' ' -f10)" ;;
            "ORDERED_LIST_ITEM") echo "$(echo $TOKEN_TYPES | cut -d' ' -f11)" ;;
            "BLOCKQUOTE") echo "$(echo $TOKEN_TYPES | cut -d' ' -f12)" ;;
            "HORIZONTAL_RULE") echo "$(echo $TOKEN_TYPES | cut -d' ' -f13)" ;;
            "LINE_BREAK") echo "$(echo $TOKEN_TYPES | cut -d' ' -f14)" ;;
            "TEXT") echo "$(echo $TOKEN_TYPES | cut -d' ' -f15)" ;;
            "EMPTY_LINE") echo "$(echo $TOKEN_TYPES | cut -d' ' -f16)" ;;
            *) echo "UNKNOWN" ;;
        esac
    fi
}

export -f get_token_type
