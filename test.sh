#!/usr/bin/env bash

set -uo pipefail

# Test runner for the markdown tokenizer

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to run a single test
run_test() {
    local test_name="$1"
    local test_file="test/${test_name}.md"
    local snapshot_file="test/snapshots/${test_name}.snap"
    local output_file="test/output/${test_name}.out"

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
    local tmp_snapshot_file="test/output/${test_name}.snap.tmp"
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
    if [ ! -d "test/snapshots" ]; then
        echo "Creating snapshots directory..."
        mkdir "test/snapshots"
    fi
    if [ ! -d "test/output" ]; then
        echo "Creating output directory..."
        mkdir "test/output"
    fi

    # Find all test files
    for test_file in test/*.md; do
        local test_name=$(basename "$test_file" .md)
        run_test "$test_name" || ((failed_tests++))
        ((total_tests++))
    done

    echo
    if [ "$failed_tests" -eq 0 ]; then
        echo -e "${GREEN}All ${total_tests} tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}${failed_tests} of ${total_tests} tests failed.${NC}"
        exit 1
    fi
}

main "$@"
