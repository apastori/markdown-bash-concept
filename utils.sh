#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/log_utils.sh"

# Create a temporary directory for our tokens
init_temp_dir() {
    if [ ! -d "$TEMP_DIR" ]; then
        log "Creating temporal directory..."
        mkdir "$TEMP_DIR"
    fi
    log "temporary directory: $TEMP_DIR correctly initialized"
}

# Clean up temporary files
cleanup_temp() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"/*
        log "Cleaned up temporary directory: $TEMP_DIR"
    fi
}

init_temp_file_tokens() {
    TEMP_FILE=$(mktemp "$TEMP_DIR/tmpfile.tokenizer.XXXXXX")
    export TEMP_FILE
    log "Created temporary file for tokens: $TEMP_FILE"
    date '+%Y-%m-%d %H:%M:%S' > "$TEMP_FILE"
}

init_temp_file_ast() {
    AST_FILE=$(mktemp "$TEMP_DIR/tmpfile.ast.XXXXXX")
    export AST_FILE
    log "Created temporary file for ast nodes: $AST_FILE"
    date '+%Y-%m-%d %H:%M:%S' > "$AST_FILE"
}

init_temp() {
    init_temp_dir
    cleanup_temp
    init_temp_file_tokens
}

export -f init_temp cleanup_temp init_temp_dir init_temp_file_tokens init_temp_file_ast   




