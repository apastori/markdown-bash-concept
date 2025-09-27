#!/usr/bin/env bash

set -uo pipefail

# Load environment scripts
source "$(dirname "$0")/env.sh"

# Test runner for the markdown tokenizer

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to run a single test
run_test() {
    local test_name="$1"
    local test_file="${TEST_DIR}/${test_name}.md"
    local snapshot_file="${TEST_DIR}/${SNAPSHOT_DIR}/${test_name}.snap"
    local output_file="${TEST_DIR}/${OUTPUT_DIR}/${test_name}.out"

    echo "Running test: ${test_name}..."

    # Run the tokenizer and filter the output
    bash tokenizer.sh "$test_file" | grep -v "Config script finished without errors" > "$output_file"

    # Check if snapshot file exists
    if [ ! -f "$snapshot_file" ]; then
        echo -e "${RED}FAIL${NC}: Snapshot file not found for ${test_name}. Creating it."
        echo "# Tokenizer Snapshot" > "$snapshot_file"
        cat "$output_file" >> "$snapshot_file"
        return 1
    fi

    # Compare the output with the snapshot
    local tmp_snapshot_file="${TEST_DIR}/${OUTPUT_DIR}/${test_name}.snap.tmp"
    tail -n +2 "$snapshot_file" > "$tmp_snapshot_file"
    if diff -u "$tmp_snapshot_file" "$output_file"; then
        echo -e "${GREEN}PASS${NC}: ${test_name}"
        rm "$output_file"
        rm "$tmp_snapshot_file"
        return 0
    else
        echo -e "${RED}FAIL${NC}: ${test_name}. Output does not match snapshot."
        rm "$tmp_snapshot_file"
        echo "To accept the new output, run:"
        echo "echo \"# Tokenizer Snapshot\" > ${snapshot_file} && cat ${output_file} >> ${snapshot_file}"
        return 1
    fi
}

# Main function to run all tests
main() {
    local failed_tests=0
    local total_tests=0

    # Create test directories if they don't exist
    if [ ! -d "$TEST_DIR" ]; then
        echo "Creating test directory..."
        mkdir "$TEST_DIR"
    fi
    if [ ! -d "$SNAPSHOT_DIR" ]; then
        echo "Creating snapshots directory..."
        mkdir "$TEST_DIR/snapshots"
    fi
    if [ ! -d "$OUTPUT_DIR" ]; then
        echo "Creating output directory..."
        mkdir "$TEST_DIR/output"
    fi

    # Find all test files
    for test_file in "$TEST_DIR"/*.md; do
        local test_name=$(basename "$test_file" .md)
        run_test "$test_name" || ((failed_tests++))
        ((total_tests++))
    done
    echo "-----------------------------------"
    echo "Test Summary:"
    if [ "$failed_tests" -eq 0 ]; then
        echo -e "${GREEN}All ${total_tests} tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}${failed_tests} of ${total_tests} tests failed.${NC}"
        exit 1
    fi
}

main "$@"
