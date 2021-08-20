#!/usr/bin/env python3

import os
import sys
from pathlib import Path 
################################################################################
# functions
################################################################################
def search_string_in_file(file_name, string_to_search):
    """Search for the given string in file and return lines containing that string,
    along with line numbers"""
    line_number = 0
    list_of_results = []
    try:
      # Open the file in read only mode
      with open(file_name, 'r') as read_obj:
          # Read all lines in the file one by one
          for line in read_obj:
              # For each line, check if line contains the string
              line_number += 1
              if string_to_search in line:
                  # If yes, then add the line number & line as a tuple in the list
                  print(line)
                  list_of_results.append((line_number, line.rstrip()))
      # Return list of tuples containing line numbers and lines where string is found
    except Exception : pass

    return list_of_results
################################################################################
# main
################################################################################
srcdir = sys.argv[1]
pattern = sys.argv[2]

excluded = ['a']

fmask = "**/*.cpp"

for fpath in Path(srcdir).glob(fmask):
  entry = ''
  occurs = search_string_in_file(fpath,pattern)
  for occur in occurs:
    if ', radius)' in occur[1]:
      entry = f'break {fpath}:{occur[0]} if (radius < 20.0f && radius > 10.0f)'
    elif ', dist)' in occur[1]:
      entry = f'break {fpath}:{occur[0]} if (dist < 20.0 && dist > 10.0f)'
    elif ', textRange)' in occur[1]:
      entry = f'break {fpath}:{occur[0]} if (textRange < 20.0 && textRange > 10.0f)'
    else:
      entry = f'break {fpath}:{occur[0]}'
    if entry not in excluded:
      print(entry)
