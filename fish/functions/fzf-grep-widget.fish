function fzf-grep-widget --description 'Search by line, recursively, from current directory'
  set rg_command 'rg --column --line-number --no-heading --color=always --smart-case'
  set choice \
      ( \
        FZF_DEFAULT_COMMAND="$rg_command ''" \
        fzf --ansi \
            --disabled \
            --bind "ctrl-v:execute(vim {1} +{2}  < /dev/tty > /dev/tty 2>&1),change:first+reload:sleep 0.1; $rg_command {q} || true" \
            --delimiter ':' \
            --header '(ctrl+v to open in vim)' \
            --prompt 'lines: ' \
            --preview-window '+{2}/3' \
            # the minus 2 prevents a weird line wrap issue
            --preview 'bat --paging=never --terminal-width (math $FZF_PREVIEW_COLUMNS - 2) {1} --highlight-line {2}' \
      )
    or return

  set tokens (string split ':' $choice)
  set filename $tokens[1]
  commandline --insert $filename
end
