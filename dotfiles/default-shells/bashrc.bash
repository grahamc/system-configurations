# bash only sources this file in interactive mode, but sometimes the default
# .bash_profile on a machine sources .bashrc if it exists so lets make sure the
# shell is in interactive mode.
if [[ $- == *i* ]]; then
  # As part of vscode's "shell resolution"[2] it starts the default shell in
  # interactive-login mode. `exec`ing into fish breaks that so I first check
  # to see if the shell was started for shell resolution using the environment
  # variable that vscode sets to indicate when shell resolution is being done[1].
  #
  # TODO: I don't think vscode should be starting a shell in interactive mode if
  # it won't actually be used interactively so maybe I should open an issue.
  #
  # [1]: https://github.com/microsoft/vscode/issues/163186
  # [2]: https://code.visualstudio.com/docs/supporting/FAQ#_resolving-shell-environment-fails
  if [[ -z "$VSCODE_RESOLVING_ENVIRONMENT" ]]; then
    # If the current shell isn't fish, exec into fish
    if [ "$(basename "$SHELL")" != 'fish' ]; then
      SHELL="$(command -v fish)" exec fish
    fi
  fi
fi
