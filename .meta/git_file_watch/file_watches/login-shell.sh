#!/bin/sh

if has_changes 'login-shell/profile.sh'; then
  echo "The login shell profile has changed. To apply these changes you can log out. Press enter to continue (This will not log you out)"

  # To hide any keys the user may press before enter I disable echo. After prompting them, I re-enable it.
  stty_original="$(stty -g)"
  stty -echo
  # I don't care if read mangles backslashes since I'm not using the input anyway.
  # shellcheck disable=2162
  read _unused
  stty "$stty_original"
fi
