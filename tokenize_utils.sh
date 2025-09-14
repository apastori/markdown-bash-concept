#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/log_utils.sh"

# Tokenize from string
tokenize_string() {
    local input="$1"
    local line_num=1
	    
    declare -a TOKENS=()

    # Process line by line
    while IFS= read -r line || [[ -n "$line" ]]; do
        tokenize_line "$line" "$line_num"
        ((line_num++))
    done <<< "$input"
}

# Tokenize from file
tokenize_file() {
    local filepath="$1"
    local line_num=1

    # Check if file exists
    if [[ ! -f "$filepath" ]]; then
        log_error "Error: File '$filepath' not found"
        return 1
    fi

    declare -a TOKENS=()
  
    # Process file line by line
    while IFS= read -r line || [[ -n "$line" ]]; do
        tokenize_line "$line" "$line_num"
        ((line_num++))
    done < "$filepath"
}
