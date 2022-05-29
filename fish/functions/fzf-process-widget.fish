function fzf-process-widget --description 'Manage processes'
  set reload_command 'date; ps -e --format user,pid,ppid,nice=NICE,start_time,etime,command --sort=-start_time'
  set choice \
      ( \
        FZF_DEFAULT_COMMAND="$reload_command" \
        FZF_HINTS='ctrl+r or input any character: refresh process list' \
        fzf \
            --ansi \
            --no-clear \
            # only search on PID, PPID, and the command
            --nth '2,3,7..' \
            --bind "change:reload(sleep 0.1; $reload_command)+first,ctrl-r:reload($reload_command)+first,ctrl-/:preview(fzf-help-preview)+change-preview-window(~0),ctrl-\\:refresh-preview+change-preview-window(~1)" \
            --header-lines=2 \
            --prompt 'processes: ' \
            --preview-window '~1' \
            # I 'echo' the fzf placeholder in the grep regex to get around the fact that fzf substitutions are single quoted and the quotes
            # would mess up the grep regex.
            --preview 'echo -s (set_color black) {} (set_color normal); pstree --hide-threads --long --show-pids --unicode --show-parents --arguments {2} | GREP_COLORS="ms=00;36" grep --color=always --extended-regexp --regexp "[^└|─]+,$(echo {2})( .*|\$)" --regexp "^"' \
      )
  or begin
    # necessary since I'm using the --no-clear option in fzf
    tput rmcup

    return
  end
  set choice (echo $choice | awk '{print $2}')

  set signal \
      ( \
        FZF_DEFAULT_COMMAND="string split ' ' (kill -l)" \
        fzf \
            --bind "change:first" \
            --header 'Select a signal to send or exit to print the PIDs' \
            --prompt 'signals: ' \
      )
  or begin
    echo $choice
    return
  end

  echo "Sending SIG$signal to the processes with the following ids: $choice"
  kill --signal $signal $choice
end
