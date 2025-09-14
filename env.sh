#!/usr/bin/env bash

# Env Definition
# Supports both string input and file input

set -euo pipefail

# Declare IS_OLD_MACHINE as integer and export
declare -i IS_OLD_MACHINE=0
export IS_OLD_MACHINE

# Declare HAS_ASSOC as integer and export
declare -i HAS_ASSOC=0
export HAS_ASSOC

# Declare VERBOSE as integer and export
declare -i VERBOSE=0
export VERBOSE

# Check Bash version and set IS_OLD_MACHINE
if (( BASH_VERSINFO[0] < 4 )); then
    IS_OLD_MACHINE=1  # Old machine (Bash < 4.0)
fi

# Check if associative array can be created
if declare -A __test_assoc 2>/dev/null; then
  HAS_ASSOC=1
  unset __test_assoc
fi

# Check if verbose flag is up
if [ "$1" = "-v" ]; then
  VERBOSE=1
fi

echo "Config script finished without errors"

return 0
