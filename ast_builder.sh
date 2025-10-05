#!/usr/bin/env bash

# Markdown AST Builder
# Converts tokenized markdown into an Abstract Syntax Tree

set -euo pipefail

source "$(dirname "$0")/utils.sh"
source "$(dirname "$0")/create_ast_node.sh"

init_temp_file_ast

declare -a ast_stack=()
declare -i node_counter=0

# Get current parent from stack
get_current_parent() {
    if [ ${#ast_stack[@]} -gt 0 ]; then
        last_index=$(( ${#ast_stack[@]} - 1 ))
        echo "${ast_stack[$last_index]}"
    else
        echo "0"  # root
    fi
}

# Push to stack
push_stack() {
    ast_stack+=("$1")
}

# Pop from stack
pop_stack() {
    if [ ${#ast_stack[@]} -gt 0 ]; then
        last_index=$(( ${#ast_stack[@]} - 1 ))
        unset "ast_stack[$last_index]"
    fi
}

# Parse token line
parse_token() {
    local line="$1"
    
    # Extract components using parameter expansion and cut
    local type=$(echo "$line" | cut -d'|' -f1)
    local content=$(echo "$line" | cut -d'|' -f2)
    local line_num=$(echo "$line" | cut -d'|' -f3)
    local context=$(echo "$line" | cut -d'|' -f4)
    
    case "$type" in
        "HEADING")
            local level=$(echo "$content" | cut -d':' -f1)
            local heading_text=$(echo "$content" | cut -d':' -f2)
            local parent_id=$(get_current_parent)
            
            # Close any open containers of same or higher level
            while [ ${#ast_stack[@]} -gt 0 ]; do
                if echo "${ast_stack[-1]}" | grep -q '^heading_[0-9][0-9]*$'; then
                local stack_level=$(echo "${ast_stack[-1]}" | grep -o '[0-9][0-9]*')
                if [ "$stack_level" -ge "$level" ]; then
                    pop_stack
                else
                    break
                fi
            else
                break
            fi
            done
            local node_id=$(create_node "heading" "$parent_id" "$heading_text" "$line_num" "level:$level")
            push_stack "heading_$level"
            ;;
            
        "PARAGRAPH")
            local parent_id=$(get_current_parent)
            local node_id=$(create_node "paragraph" "$parent_id" "$content" "$line_num" "")
            push_stack "$node_id"
            ;;
            
        "LINK")
            local link_data=$(echo "$content" | cut -d':' -f1,2 --output-delimiter=':')
            local link_text=$(echo "$link_data" | cut -d':' -f1)
            local link_url=$(echo "$link_data" | cut -d':' -f2-)
            local parent_id=$(get_current_parent)
            
            local node_id=$(create_node "link" "$parent_id" "$link_text" "$line_num" "url:$link_url,context:$context")
            ;;
            
        "IMAGE")
            local image_data=$(echo "$content" | cut -d':' -f1,2 --output-delimiter=':')
            local alt_text=$(echo "$image_data" | cut -d':' -f1)
            local image_url=$(echo "$image_data" | cut -d':' -f2-)
            local parent_id=$(get_current_parent)
            
            local node_id=$(create_node "image" "$parent_id" "$alt_text" "$line_num" "src:$image_url,context:$context")
            ;;
            
        "CODE_BLOCK")
            if [[ "$content" == start* ]]; then
                local lang=$(echo "$content" | cut -d':' -f2)
                local parent_id=$(get_current_parent)
                local node_id=$(create_node "code_block" "$parent_id" "" "$line_num" "language:$lang")
                push_stack "$node_id"
            else
                # End of code block
                pop_stack
            fi
            ;;
            
        "UNORDERED_LIST_ITEM")
            local parent_id=$(get_current_parent)
            
            # Check if we need to create a list container
            if [[ ! "${ast_stack[-1]}" =~ ^list_ ]]; then
                local list_id=$(create_node "unordered_list" "$parent_id" "" "$line_num" "")
                push_stack "list_$list_id"
                parent_id="$list_id"
            else
                parent_id=$(echo "${ast_stack[-1]}" | cut -d'_' -f2)
            fi
            
            local item_id=$(create_node "list_item" "$parent_id" "$content" "$line_num" "type:unordered")
            ;;
            
        "ORDERED_LIST_ITEM")
            local parent_id=$(get_current_parent)
            
            # Check if we need to create a list container
            if [[ ! "${ast_stack[-1]}" =~ ^list_ ]]; then
                local list_id=$(create_node "ordered_list" "$parent_id" "" "$line_num" "")
                push_stack "list_$list_id"
                parent_id="$list_id"
            else
                parent_id=$(echo "${ast_stack[-1]}" | cut -d'_' -f2)
            fi
            
            local item_id=$(create_node "list_item" "$parent_id" "$content" "$line_num" "type:ordered")
            ;;
            
        "EMPTY_LINE")
            # Pop paragraph context if we're in one
            if [[ "${ast_stack[-1]}" =~ ^[0-9]+$ ]] && [ ${#ast_nodes[@]} -gt 0 ]; then
                local last_node="${ast_nodes[-1]}"
                local last_type=$(echo "$last_node" | cut -d':' -f2)
                if [ "$last_type" = "paragraph" ]; then
                    pop_stack
                fi
            fi
            ;;
    esac
}

# Print AST in a readable format
print_ast() {
    echo "Abstract Syntax Tree:"
    echo "====================="
    
    for node in "${ast_nodes[@]}"; do
        local id=$(echo "$node" | cut -d':' -f1)
        local type=$(echo "$node" | cut -d':' -f2)
        local parent_id=$(echo "$node" | cut -d':' -f3)
        local content=$(echo "$node" | cut -d':' -f4)
        local line_num=$(echo "$node" | cut -d':' -f5)
        local metadata=$(echo "$node" | cut -d':' -f6-)
        
        # Calculate depth for indentation
        local depth=0
        local current_parent="$parent_id"
        while [ "$current_parent" != "0" ]; do
            ((depth++))
            # Find parent node
            for parent_node in "${ast_nodes[@]}"; do
                local parent_node_id=$(echo "$parent_node" | cut -d':' -f1)
                if [ "$parent_node_id" = "$current_parent" ]; then
                    current_parent=$(echo "$parent_node" | cut -d':' -f3)
                    break
                fi
            done
            # Prevent infinite loop
            if [ $depth -gt 10 ]; then break; fi
        done
        
        # Create indentation
        local indent=""
        for ((i=0; i<depth; i++)); do
            indent+="  "
        done
        
        printf "%s[%s] %s" "$indent" "$type" "$content"
        if [ -n "$metadata" ]; then
            printf " (%s)" "$metadata"
        fi
        printf " @line:%s\n" "$line_num"
    done
}

# Convert AST to JSON format (read nodes from AST_FILE)
print_ast_json() {
    echo "{"
    echo '  "type": "document",'
    echo '  "children": ['

    local first=true
    while IFS= read -r node; do
        local parent_id=$(echo "$node" | cut -d':' -f3)
        if [ "$parent_id" = "0" ]; then
            if [ "$first" = false ]; then
                echo ","
            fi
            print_node_json "$node" "    "
            first=false
        fi
    done < "$AST_FILE"

    echo ""
    echo "  ]"
    echo "}"
}

print_node_json() {
    local node="$1"
    local indent="$2"
    
    local id=$(echo "$node" | cut -d':' -f1)
    local type=$(echo "$node" | cut -d':' -f2)
    local content=$(echo "$node" | cut -d':' -f4)
    local line_num=$(echo "$node" | cut -d':' -f5)
    local metadata=$(echo "$node" | cut -d':' -f6-)
    
    printf '%s{\n' "$indent"
    printf '%s  "type": "%s",\n' "$indent" "$type"
    printf '%s  "line": %s' "$indent" "$line_num"
    
    if [ -n "$content" ]; then
        # Escape content for JSON
        local escaped_content=$(echo "$content" | sed 's/\\/\\\\/g; s/"/\\"/g')
        printf ',\n%s  "content": "%s"' "$indent" "$escaped_content"
    fi
    
    if [ -n "$metadata" ]; then
        printf ',\n%s  "metadata": "%s"' "$indent" "$metadata"
    fi
    
    # Check for children
    local has_children=false
    for child_node in "${ast_nodes[@]}"; do
        local child_parent=$(echo "$child_node" | cut -d':' -f3)
        if [ "$child_parent" = "$id" ]; then
            if [ "$has_children" = false ]; then
                printf ',\n%s  "children": [\n' "$indent"
                has_children=true
            else
                printf ',\n'
            fi
            print_node_json "$child_node" "$indent    "
        fi
    done
    
    if [ "$has_children" = true ]; then
        printf '\n%s  ]' "$indent"
    fi
    
    printf '\n%s}' "$indent"
}

# Main processing function
process_tokens() {
    local input_file="$1"
    
    # Initialize root
    ast_stack=()
    node_counter=0
    
    # Process each token line
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            parse_token "$line"
        fi
    done < "$input_file"
}

# ------------------------------- # Main function # -------------------------------

main() {
    # Example usage
    if [ "$#" -eq 0 ]; then
        echo "Usage: $0 <token_file> [--json]"
        echo "Example: $0 tokens.txt"
        echo "         $0 tokens.txt --json"
        exit 1
    fi

    input_file="$1"
    output_format="${2:-tree}"

    if [ ! -f "$input_file" ]; then
        echo "Error: File '$input_file' not found"
        exit 1
    fi

    # Process the tokens
    process_tokens "$input_file"

    # Output in requested format
    if [ "$output_format" = "--json" ]; then
        print_ast_json
    else
        print_ast
    fi
}

# Run the script even if it is sourced
main "$@"

return 0