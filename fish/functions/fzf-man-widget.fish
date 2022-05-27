function fzf-man-widget --description 'Search manpages'
  set choice \
      ( \
        FZF_DEFAULT_COMMAND='man -k . --long' \
         fzf  \
            --ansi \
            --no-clear \
            --tiebreak=begin \
            --prompt 'manpages: ' \
            --preview "man (string sub --start=2 --end=-1 {2}) {1}" \
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
