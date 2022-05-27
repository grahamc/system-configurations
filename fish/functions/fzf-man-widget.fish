function fzf-man-widget --description 'Search manpages'
  set choice \
      ( \
        FZF_DEFAULT_COMMAND='man -k . --long' \
         fzf  \
            --ansi \
            --no-clear \
            --tiebreak=begin \
            --prompt 'manpages: ' \
            # Setting a very large MANWIDTH so that man will not truncate lines and instead allow
            # them to wrap. This way if I increase the terminal window size, the lines will take
            # up the new width.
            #
            # Because of the large MANWIDTH the man formatters (e.g. troff) print errors so we suppress
            # stderr.
            #
            # If fzf allowed refreshing the preview on SIGWINCH, we could remove MANWIDTH and just
            # refresh the preview in the larger terminal window.
            # Issue: https://github.com/junegunn/fzf/issues/2248
            #
            # The 'string sub' is to remove the parentheses around the manpage section
            --preview "MANWIDTH=1000000 man (string sub --start=2 --end=-1 {2}) {1} 2>/dev/null" \
      )
  or begin
    # necessary since I'm using the --no-clear option in fzf
    tput rmcup

    return
  end

  set manpage_name (echo $choice | awk '{print $1}')
  set manpage_section (echo $choice | awk '{print $2}' | string sub --start=2 --end=-1)
  man $manpage_section $manpage_name
  # Since I'm using --no-clear in fzf, I'm expecting man to set the terminal back to the primary screen.
  # If man fails, then I'll set the primary screen
  or tput rmcup
end
