function fzf-apt-install-widget --description 'Install packages with apt'
  set choices \
      ( \
        FZF_DEFAULT_COMMAND='apt-cache pkgnames' \
        fzf-tmux -B -p 100% -- \
        # TODO: Gotta wait until tmux has a release the contains the -e flag for popups.
        # PR: https://github.com/tmux/tmux/pull/2924/commits/8b3e46ce24a7948cf928f963d6765a8039cc84a8
        # fzf-tmux -B -p 100% -e "FZF_HINTS=alt+enter: select multiple items" -- \
            --ansi \
            --multi \
            --bind "alt-enter:toggle,change:first" \
            --prompt 'apt install: ' \
            --preview "apt show {} 2>/dev/null | GREP_COLORS='$GREP_COLORS' grep --color=always -E '(^[a-z|A-Z|-]*:|^)' | less" \
      )
  or return

  echo "Running command 'sudo apt-get install $choices'..."
  sudo apt-get install --assume-yes $choices
end
