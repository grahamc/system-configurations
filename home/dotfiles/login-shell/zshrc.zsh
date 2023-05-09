[[ -o interactive ]] && [ "$(basename "$SHELL")" != 'fish' ] && command -v fish >/dev/null 2>&1 && SHELL="$(command -v fish)" exec fish
