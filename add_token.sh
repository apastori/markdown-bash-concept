#!/usr/bin/env bash

set -euo pipefail

# Function to add a token to the Temporary File with Tokens

add_token() {
    local token_type="$1"
    local token_value="$2"
    local line_num="$3"
    local context="${4:-}" # Optional context

    local token_string="$token_type|$token_value|$line_num|$context"
    echo "$token_string" >> "$TEMP_FILE"
}
