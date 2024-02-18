# If the current shell isn't fish, use fish in place of bash for an interactive shell.
#
# The `-t` checks are to make sure that we are at a terminal because as part of vscode's shell
# resolution it launches the shell in interactive mode and then I call `exec` which seems to break
# things so my environment variables don't get setup properly. Alternatively, I could check for the
# environment variable that vscode sets while doing shell resolution. It is set for scenarios like
# this. Feature request for setting the variable:
# https://github.com/microsoft/vscode/issues/163186
#
# WARNING: Keep this line at the bottom of the file since nothing after this line will be executed.
[[ -o interactive ]] && [ -t 0 ] && [ -t 1 ] && [ -t 2 ] && [ "$(basename "$SHELL")" != 'fish' ] && command -v fish >/dev/null 2>&1 && SHELL="$(command -v fish)" exec fish
