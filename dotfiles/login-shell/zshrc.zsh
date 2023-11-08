# The `-t` checks are to make sure that we are at a terminal because as part of vscode's shell resolution it launches
# the shell in interactive mode and then I call `exec` which seems to break things so my environment variables don't
# get setup properly.
[[ -o interactive ]] && [ -t 0 ] && [ -t 1 ] && [ -t 2 ] && [ "$(basename "$SHELL")" != 'fish' ] && command -v fish >/dev/null 2>&1 && SHELL="$(command -v fish)" exec fish
