#!/bin/bash

# `djvused -e 'print-pure-txt'` adds page breaks for blank pages, but
# also for each non-page file included in the djvu file (shared image or
# annotation data and thumbnail data).
#
# `djvused -e 'ls'` gives the list of included files, page files and others.
# We can thus get the page number associated to a file number. The latter
# is what we get by counting page breaks in `djvused -e 'print-pure-txt'`’s
# output.

input_file="$1"

# Lines produced by `djvused -e 'ls'` are of the following forms:
#  45 P …
# 145 P …
#     I …
#     A …
#     T …
while IFS= read -r file_info; do
  page="${file_info%% [APIT]*}"
  page="${page// /}"
  file_to_page+=("$page")
done < <(djvused "$input_file" -e 'ls')

remove_non_pages() {
  # Remove all occurrences of \x0c due to a non-page.
  file=-1
  while IFS= read -r -d $'\x0c' file_text; do
    file=$((file + 1))
    [[ "${file_to_page[$file]}" == '' ]] && continue
    echo "$file_text"$'\x0c'
  done
}

djvused "$input_file" -e 'print-pure-txt' | remove_non_pages
