#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/get_token_type.sh"
source "$(dirname "$0")/tokenize_inline.sh"

# Tokenize a single line
tokenize_line() {
    local line="$1"
    local line_num="$2"
    
    # Empty line
    if echo "$line" | grep -q '^[[:space:]]*$'; then
        add_token "$(get_token_type "EMPTY_LINE")" "" "$line_num"
        return
    fi
    
    # Horizontal rule (--- or *** or ___)
    if echo "$line" | grep -q '^[[:space:]]*\([-*_]\)\([[:space:]]*\1\)\{2,\}[[:space:]]*$'; then
        add_token "$(get_token_type "HORIZONTAL_RULE")" "" "$line_num"
        return
    fi
    
    # Indented code block (4+ spaces or 1+ tabs)
    if echo "$line" | grep -q '^[[:space:]]\{4,\}'; then
        local content=$(echo "$line" | sed 's/^[[:space:]]\{4\}//')
        add_token "$(get_token_type "CODE_BLOCK")" "content:${content}" "$line_num"
        return
    fi
    
    # Code block start (```)
    if echo "$line" | grep -q '^[[:space:]]*\(`\{3,\}\|~\{3,\}\)'; then
        local fence=$(echo "$line" | sed 's/^[[:space:]]*\(\(`\{3,\}\|~\{3,\}\)\).*/\1/')
        local lang=$(echo "$line" | sed 's/^[[:space:]]*\(`\{3,\}\|~\{3,\}\)\([^[:space:]]*\).*/\2/')
        # Store the fence type/length to match closing fence later
        add_token "$(get_token_type "CODE_BLOCK")" "start:${lang}:${fence}" "$line_num"
        return
    fi
    
    # Heading (# ## ### #### ##### ######)
    if echo "$line" | grep -q '^[[:space:]]*#{1,6}[[:space:]]\+'; then
        local hashes=$(echo "$line" | sed 's/^[[:space:]]*\(#\{1,6\}\).*/\1/')
	local level=${#hashes}
        local text=$(echo "$line" | sed 's/^[[:space:]]*#{1,6}[[:space:]]\+\(.*\)$/\1/')
        add_token "$(get_token_type "HEADING")" "${level}:${text}" "$line_num"
        tokenize_inline_elements "$text" "$line_num" "heading"
        return
    fi
    
    # Blockquote (> text)
    if echo "$line" | grep -q '^[[:space:]]*>'; then
        local quote_text=$(echo "$line" | sed 's/^[[:space:]]*>[[:space:]]*//')
        add_token "$(get_token_type "BLOCKQUOTE")" "$quote_text" "$line_num"
        if [ -n "$quote_text" ]; then
            tokenize_inline_elements "$quote_text" "$line_num" "blockquote"
        fi
        return
    fi
    
    # Unordered list item (- * +)
    if echo "$line" | grep -q '^[[:space:]]*[-*+][[:space:]]\+'; then
        local item_text=$(echo "$line" | sed 's/^[[:space:]]*[-*+][[:space:]]\+\(.*\)$/\1/')
        add_token "$(get_token_type "UNORDERED_LIST_ITEM")" "$item_text" "$line_num"
        tokenize_inline_elements "$item_text" "$line_num" "list_item"
        return
    fi
    
    # Ordered list item (1. 2. etc.)
    if echo "$line" | grep -q '^[[:space:]]*[0-9]\+\.[[:space:]]\+'; then
        local item_text=$(echo "$line" | sed 's/^[[:space:]]*[0-9]\+\.[[:space:]]\+\(.*\)$/\1/')
        add_token "$(get_token_type "ORDERED_LIST_ITEM")" "$item_text" "$line_num"
        tokenize_inline_elements "$item_text" "$line_num" "list_item"
        return
    fi
    
    # Regular paragraph
    add_token "$(get_token_type "PARAGRAPH")" "$line" "$line_num"
    tokenize_inline_elements "$line" "$line_num" "paragraph"
}

export -f tokenize_line
