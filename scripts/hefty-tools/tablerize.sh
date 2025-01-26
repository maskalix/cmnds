#!/bin/bash

# Function to format list output into a clean table
to_table() {
  local input
  local separator='|' # Separator for table columns

  # Read input into a variable
  input=$(cat)

  # Calculate the column widths
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

  # Format each line into a fixed-width table
  echo "$input" | awk -v widths="$column_widths" -v sep="$separator" '
    BEGIN {
      split(widths, w)
      fmt = ""
      for (i in w) fmt = fmt "%-" w[i] "s" sep
      fmt = substr(fmt, 1, length(fmt) - 1) "\n"
      print "Formatted Table:"
      print "------------------------------------------"
    }
    {
      printf fmt, $1, $2, $3, $4, $5, $6, $7
    }
  '
}

# Run the table conversion
to_table
