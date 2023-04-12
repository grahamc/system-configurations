function my-fzf-file-widget --description 'Search by line, recursively, from current directory'
  set dir "$(commandline -t)"
  if test "$(string sub --length 1 "$dir")" = '~'
    set dir (string replace '~' "$HOME" "$dir")
  end
  if not test -d "$dir"
    set dir '.'
  end

  set prompt "$dir"
  if test "$(string sub --start -1 "$dir")" != '/'
    set prompt "$prompt/"
  end

  # Regarding the bat command:
  # - the minus 2 prevents a weird line wrap issue
  # - The head and tail commands are there to remove the first and last line of output of bat i.e. the top and bottom
  # border of bat since I don't like how they look
  set preview_command '
  if file --brief --mime-type {} | grep -q -i image
    if env | grep -q WEZTERM
      timg -g "$FZF_PREVIEW_COLUMNS"x"$FZF_PREVIEW_LINES" -p kitty {}
    else
      timg -g "$FZF_PREVIEW_COLUMNS"x"$FZF_PREVIEW_LINES" {}
    end
  else
    bat --paging=never --terminal-width (math $FZF_PREVIEW_COLUMNS - 2) {} | tail -n +2 | head -n -1
  end
  '

  set choice \
      ( \
        FZF_DEFAULT_COMMAND="test '$dir' = '.' && set _args '--strip-cwd-prefix' || set _args '.' '$dir'; fd \$_args --follow --hidden --type file --type symlink" \
        fzf-tmux-zoom \
            --ansi \
            --bind "change:first" \
            --prompt "$prompt" \
            --preview "$preview_command" \
      )
  or return

  commandline --current-token --replace $choice

  # this should be done whenever a binding produces output (see: man bind)
  commandline -f repaint
end
