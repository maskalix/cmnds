#!/bin/bash

to_table() {
  local input
  local separator='|' # Separator for table columns
  local max_col_width=30 # Max width for a column

  # Read input
  input=$(cat)

  # Extract the header row to determine the number of columns
  header=$(echo "$input" | head -n 1)

  # Calculate column widths dynamically, but limit to max_col_width
  column_widths=$(echo "$input" | awk -v max_width="$max_col_width" '
    {
      for (i = 1; i <= NF; i++) {
        if (length($i) > max[i]) max[i] = (length($i) > max_width ? max_width : length($i))
      }
    }
    END {
      for (i = 1; i <= length(max); i++) printf "%d ", max[i] + 2
    }
  ')

  # Convert the column widths to an array
  IFS=' ' read -r -a widths <<< "$column_widths"

  # Generate the format string dynamically
  format_string=""
  for width in "${widths[@]}"; do
    format_string+="%-${width}s$separator"
  done
  format_string=${format_string%$separator} # Remove trailing separator

  # Function to truncate long text
  truncate_field() {
    local text="$1"
    local width="$2"
    if (( ${#text} > width )); then
      echo "${text:0:width-3}..."
    else
      echo "$text"
    fi
  }

  # Print the formatted table
  echo "Formatted Table:"
  echo "------------------------------------------"

  # Process each row
  echo "$input" | while read -r line; do
    # Split the line into fields
    IFS=' ' read -r -a fields <<< "$line"
    truncated_fields=()
    for i in "${!fields[@]}"; do
      # Truncate each field if necessary
      truncated_fields+=("$(truncate_field "${fields[i]}" "${widths[i]}")")
    done
    # Print the formatted row
    printf "$format_string\n" "${truncated_fields[@]}"
  done
}

# Run the table conversion
to_table
