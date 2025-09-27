#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/env.sh" "$@"
source "$(dirname "$0")/log_utils.sh"
source "$(dirname "$0")/utils.sh"

# Initialize log file
init_log "mdbashtoto.log"

# Initialize Temporary Directory
init_temp

# If verbose flag is up, then shift first parameter
if [ "$VERBOSE" -eq 1 ]; then
    shift
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
        source "$(dirname "$0")/tokenizer.sh" $input "file"
    else
        source "$(dirname "$0")/tokenizer.sh" $input "string"
    fi
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    echo "${TOKENS[@]}"
fi

exit 0