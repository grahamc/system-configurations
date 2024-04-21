if shopt -q login_shell; then
  if [ -f ~/.config/default-shells/login-config.sh ]; then
    set -o posix
    # shellcheck source=login-config.sh
    . ~/.config/default-shells/login-config.sh
    set +o posix
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
if [[ (-n "$PS1" || $- == *i*) && -t 0 && -t 1 && -t 2 ]]; then
  # Set color palette for tty. It's the same as the dark theme I use in my
  # regular terminal.
  if [ "$TERM" = "linux" ]; then
    printf "\e]P0232731"
    printf "\e]P8333745"
    printf "\e]P1BF616A"
    printf "\e]P9BF616A"
    printf "\e]P2A3BE8C"
    printf "\e]PAA3BE8C"
    printf "\e]P3EBCB8B"
    printf "\e]PBEBCB8B"
    printf "\e]P481A1C1"
    printf "\e]PC81A1C1"
    printf "\e]P5B48EAD"
    printf "\e]PD232731"
    printf "\e]P688C0D0"
    printf "\e]PE8FBCBB"
    printf "\e]P7E5E9F0"
    printf "\e]PF626f89"

    # for background artifacting
    clear
  fi

  # If the current shell isn't fish, exec into fish
  if [ "$(basename "$SHELL")" != 'fish' ]; then
    SHELL="$(command -v fish)" exec fish
  fi
fi
