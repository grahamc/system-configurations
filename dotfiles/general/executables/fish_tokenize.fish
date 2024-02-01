#!/usr/bin/env fish

printf "$argv[1]" | read --tokenize --list tokens
# printing this way so there's no trailing newline
printf "$(string join -- \n $tokens)"
