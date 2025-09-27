#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/log_utils.sh"
source "$(dirname "$0")/add_token.sh"
source "$(dirname "$0")/get_token_type.sh"

tokenize_inline_elements() {
    local text="$1"
    local line_num="$2"
    local context="$3"
	
	# Remove stray carriage returns (Windows CRLF) from inline text
    text="${text//$'\r'/}"

    local len=${#text}
    local pos=0
    local found_end=0

    while [ $pos -lt $len ]; do
        local char="${text:$pos:1}"
        local remaining="${text:$pos}"

        # Check for inline code first (highest precedence, no nesting allowed)
        if [ "$char" = '`' ]; then
            local end_pos=$((pos + 1))
            local backtick_count=1

            # Count consecutive backticks for multi-backtick code
            while [ $end_pos -lt $len ] && [ "${text:$end_pos:1}" = '`' ]; do
                backtick_count=$((backtick_count + 1))
                end_pos=$((end_pos + 1))
            done

            # Find matching closing backticks
            local content_start=$end_pos
            while [ $end_pos -lt $((len - backtick_count + 1)) ]; do
                local match_count=0
                local check_pos=$end_pos

                # Check if we have matching number of backticks
                while [ $check_pos -lt $len ] && [ "${text:$check_pos:1}" = '`' ] && [ $match_count -lt $backtick_count ]; do
                    match_count=$((match_count + 1))
                    check_pos=$((check_pos + 1))
                done

                if [ $match_count -eq $backtick_count ]; then
                    found_end=1
                    break
                fi
                end_pos=$((end_pos + 1))
            done

            if [ $found_end -eq 1 ]; then
                local code_content="${text:$content_start:$((end_pos - content_start))}"
                add_token "$(get_token_type "CODE_INLINE")" "$code_content" "$line_num" "$context"
                pos=$((end_pos + backtick_count))
                continue
            fi
            # Unclosed inline code - treat as literal text and emit warning
	    log_err "Warning: Unclosed inline code at line $line_num, position $((pos + 1))"
	    add_token "$(get_token_type "TEXT")" "$char" "$line_num" "$context"
	    pos=$((pos + 1))
            continue
        fi

        # Handle emphasis patterns: *, **, ***, *, *_, ___
	if [ "$char" = '*' ] || [ "$char" = '_' ]; then
	    local delim_count=0
	    local check_pos=$pos

	    # Count consecutive delimiters
	    while [ $check_pos -lt $len ] && [ "${text:$check_pos:1}" = "$char" ]; do
		delim_count=$((delim_count + 1))
		check_pos=$((check_pos + 1))
	    done

	    # Only process emphasis if we have 1-3 delimiters
	    if [ $delim_count -le 3 ] && [ $delim_count -ge 1 ]; then
		# Find matching closing delimiters
		local content_start=$check_pos
		local end_pos=$content_start
		found_end=0

		while [ $end_pos -lt $len ]; do
		    if [ "${text:$end_pos:1}" = "$char" ]; then
			local closing_count=0
			local closing_pos=$end_pos

			# Count closing delimiters
			while [ $closing_pos -lt $len ] && [ "${text:$closing_pos:1}" = "$char" ]; do
			    closing_count=$((closing_count + 1))
			    closing_pos=$((closing_pos + 1))
			done

			# Check if we have valid closing
			if [ $closing_count -ge $delim_count ]; then
			    found_end=1
			    break
			fi
		    fi
		    end_pos=$((end_pos + 1))
		done

		if [ $found_end -eq 1 ]; then
		    local content="${text:$content_start:$((end_pos - content_start))}"
		    # Don't allow empty emphasis content
		    if [ -z "$content" ]; then
			log_err "Warning: Empty emphasis content at line $line_num, position $((pos + 1))"
			add_token "$(get_token_type "TEXT")" "${text:$pos:$delim_count}" "$line_num" "$context"
			pos=$((pos + delim_count))
			continue
		    fi
		    # Determine token type based on delimiter count
		    case $delim_count in
			1)
			    add_token "$(get_token_type "ITALIC")" "$content" "$line_num" "$context"
			    ;;
			2)
			    add_token "$(get_token_type "BOLD")" "$content" "$line_num" "$context"
			    ;;
			3)
			    # Triple emphasis = bold + italic
			    add_token "$(get_token_type "BOLD_ITALIC")" "$content" "$line_num" "$context"
			    ;;
		    esac

		    # Recursively process content for nested formatting
		    if [ -n "$content" ]; then
			tokenize_inline_elements "$content" "$line_num" "${context}_nested"
		    fi
		    pos=$((end_pos + delim_count))
		    continue
		fi
		# Unclosed emphasis - treat as literal text and emit warning
		log_err "Warning: Unclosed emphasis at line $line_num, position $((pos + 1))"
		add_token "$(get_token_type "TEXT")" "$char" "$line_num" "$context"
		pos=$((pos + 1))
		continue
	     fi
        fi

        # Handle images ![alt](url) or ![alt](url "title")
	if [ "$char" = '!' ] && [ $((pos + 1)) -lt $len ] && [ "${text:$((pos + 1)):1}" = '[' ]; then
	    local bracket_start=$((pos + 1))
	    local bracket_end=$bracket_start
	    local bracket_count=1

	    # Find closing bracket for alt text
	    bracket_end=$((bracket_end + 1))
	    while [ $bracket_end -lt $len ] && [ $bracket_count -gt 0 ]; do
		local bracket_char="${text:$bracket_end:1}"
		if [ "$bracket_char" = '[' ]; then
		    bracket_count=$((bracket_count + 1))
		elif [ "$bracket_char" = ']' ]; then
		    bracket_count=$((bracket_count - 1))
		fi
		bracket_end=$((bracket_end + 1))
	    done

	    # Check for following parentheses
	    if [ $bracket_count -eq 0 ] && [ $bracket_end -lt $len ] && [ "${text:$bracket_end:1}" = '(' ]; then
		local paren_start=$bracket_end
		local paren_end=$paren_start
		local paren_count=1

		# Find closing parenthesis for URL (and optional title)
		paren_end=$((paren_end + 1))
		while [ $paren_end -lt $len ] && [ $paren_count -gt 0 ]; do
		    local paren_char="${text:$paren_end:1}"
		    if [ "$paren_char" = '(' ]; then
			paren_count=$((paren_count + 1))
		    elif [ "$paren_char" = ')' ]; then
			paren_count=$((paren_count - 1))
		    fi
		    paren_end=$((paren_end + 1))
		done

		if [ $paren_count -eq 0 ]; then
		    local alt_text="${text:$((bracket_start + 1)):$((bracket_end - bracket_start - 2))}"
		    local url_and_title="${text:$((paren_start + 1)):$((paren_end - paren_start - 2))}"

		    # Parse URL and optional title (title is in quotes)
		    local image_url="$url_and_title"
		    local image_title=""

		    # Check for title in quotes (simple parsing - handles "title" or 'title')
		    if [[ "$url_and_title" =~ ^(.+)[[:space:]]+[""](.*)[""]*$ ]]; then
			image_url="${BASH_REMATCH[1]}"
			image_title="${BASH_REMATCH[2]}"
		    fi

		    # Store image data (format: alt:url:title)
		    add_token "$(get_token_type "IMAGE")" "${alt_text}:${image_url}:${image_title}" "$line_num" "$context"

		    # Process alt text for nested formatting (if needed)
		    if [ -n "$alt_text" ]; then
			tokenize_inline_elements "$alt_text" "$line_num" "image_alt"
		    fi

		    pos=$paren_end
		    continue
		fi
	    fi
	    # If we get here, it's not a valid image syntax
	    # Fall through to handle the '!' as regular text
	    log_err "Warning: Unclosed image at line $line_num, position $((pos + 1))"
	    add_token "$(get_token_type "TEXT")" "$char" "$line_num" "$context"
	    pos=$((pos + 1))
	    continue
        fi

        # Handle links [text](url)
        if [ "$char" = '[' ]; then
            local bracket_end=$pos
            local bracket_count=1

            # Find closing bracket (handle nested brackets)
            bracket_end=$((bracket_end + 1))
            while [ $bracket_end -lt $len ] && [ $bracket_count -gt 0 ]; do
                local bracket_char="${text:$bracket_end:1}"
                if [ "$bracket_char" = '[' ]; then
                    bracket_count=$((bracket_count + 1))
                elif [ "$bracket_char" = ']' ]; then
                    bracket_count=$((bracket_count - 1))
                fi
                bracket_end=$((bracket_end + 1))
            done

            # Check for following parentheses
            if [ $bracket_count -eq 0 ] && [ $bracket_end -lt $len ] && [ "${text:$bracket_end:1}" = '(' ]; then
                local paren_end=$bracket_end
                local paren_count=1

                # Find closing parenthesis
                paren_end=$((paren_end + 1))
                while [ $paren_end -lt $len ] && [ $paren_count -gt 0 ]; do
                    local paren_char="${text:$paren_end:1}"
                    if [ "$paren_char" = '(' ]; then
                        paren_count=$((paren_count + 1))
                    elif [ "$paren_char" = ')' ]; then
                        paren_count=$((paren_count - 1))
                    fi
                    paren_end=$((paren_end + 1))
                done

                if [ $paren_count -eq 0 ]; then
                    local link_text="${text:$((pos + 1)):$((bracket_end - pos - 2))}"
                    local link_url="${text:$((bracket_end + 1)):$((paren_end - bracket_end - 2))}"

                    add_token "$(get_token_type "LINK")" "${link_text}:${link_url}" "$line_num" "$context"

                    # Process link text for nested formatting
                    if [ -n "$link_text" ]; then
                        tokenize_inline_elements "$link_text" "$line_num" "link_text"
                    fi

                    pos=$paren_end
                    continue
                fi
            fi
        fi

        # No pattern matched, advance one character
        pos=$((pos + 1))
    done
}

export -f tokenize_inline_elements
