#!/usr/bin/env bash

# Node structure: node_id:type:parent_id:content:line_number:metadata
create_node() {
    local type="$1"
    local parent_id="$2"
    local content="$3"
    local line_number="$4"
    local metadata="$5"
    
    ((node_counter++))
    local node="${node_counter}:${type}:${parent_id}:${content}:${line_number}:${metadata}"
    echo "$node" >> "$AST_FILE"
    echo "$node_counter"
}

export -f create_node