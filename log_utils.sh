#!/usr/bin/env bash

# Initialize log file if verbose
init_log() {
    if [[ -n "$1" ]]; then
        LOG_FILE="$1"
    else
        LOG_FILE="mdbashtoto.log"
    fi
    if [[ VERBOSE -eq 1 ]]; then
        # Create log directory if it doesn't exist
        if [[ ! -d "$LOG_DIR" ]]; then
            mkdir -p "$LOG_DIR"
        fi
        # Remove old log if it exists
        if [[ -f "$LOG_DIR/$LOG_FILE" ]]; then
            rm "$LOG_DIR/$LOG_FILE"
        fi
        # Create a new empty log file
        touch "$LOG_DIR/$LOG_FILE"
        # Add timestamp for execution start
        echo "Execution started at: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_DIR/$LOG_FILE"
    fi
}

# Log normal messages
log() {
    local msg="$1"
    # print to stdout
    echo "$msg"
    if [[ $VERBOSE -eq 1 ]]; then
        echo "$msg" >> "$LOG_DIR/$LOG_FILE"
    fi
}

# Log error messages
log_err() {
    local msg="$1"
    # print to stderr
    echo "$msg" >&2
    if [[ $VERBOSE -eq 1 ]]; then
        echo "$msg" >> "$LOG_DIR/$LOG_FILE"
    fi
}

# Export functions so other scripts can use them
export -f init_log log log_err

