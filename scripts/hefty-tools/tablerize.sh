#!/bin/bash

to_table() {
  local input
  local separator='|' # Separator for table columns

  # Read the input
  input=$(cat)

  # Extract the header row to determine the number of columns
  header=$(echo "$input" | head -n 1)

  # Calculate column widths dynamically
  column_widths=$(echo "$input" | awk '
    {
      for (i = 1; i <= NF; i++) {
        if (length($i) > max[i]) max[i] = length($i)
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

  # Print the formatted table
  echo "Formatted Table:"
  echo "------------------------------------------"
  echo "$input" | awk -v fmt="$format_string" -v sep="$separator" '
    {
      printf fmt "\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18
    }
  '
}

# Run the table conversion
to_table
