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

  # Format the input into a table
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
      args = ""
      for (i = 1; i <= NF; i++) args = args sprintf(fmt, $i)
      print args
    }
  '
}

# Run the table conversion
to_table
