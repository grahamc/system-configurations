# I'm putting the login in the rc, as opposed to the profile, because I want it
# to run last and rc's get sourced after profiles. Running last will allow me
# to override anything in a vendor config and entries I add to the $PATH will
# precede any vendor config entries.

if [[ -o login ]]; then
  if [ -f ~/.config/default-shells/login-config.sh ]; then
    emulate sh -c '. ~/.config/default-shells/login-config.sh'
    emulate zsh
  fi
fi

# Interactive check. The `-t` checks are to make sure that we are at a terminal
# since some programs launch the shell in interactive mode without allow the
# shell to be used interactively. For example, vscode launches the shell in
# interactive mode as part of its "shell resolution" and my call to exec
# below breaks it.  Alternatively, I could check for the environment variable
# that vscode sets while doing shell resolution. It is set for scenarios like
# this. Feature request for setting the variable[1].
#
# [1]: https://github.com/microsoft/vscode/issues/163186
if [[ -o interactive && -t 0 && -t 1 && -t 2 ]]; then
  # If the current shell isn't fish, exec into fish
  if [ "$(basename "$SHELL")" != 'fish' ]; then
    SHELL="$(command -v fish)" exec fish
  fi
fi
