function fzf-process-widget --description 'Manage processes'
  set reload_command 'ps -e --format user,pid,ppid,nice=NICE,start_time,etime,command --sort=-start_time'
  set choice \
      ( \
        FZF_DEFAULT_COMMAND="$reload_command" \
        FZF_HINTS='ctrl+alt+r: refresh process list\nalt+enter: select multiple items' \
        fzf \
            --ansi \
            --multi \
            --no-clear \
            # only search on PID, PPID, and the command
            --nth '2,3,7..' \
            --bind "change:first,ctrl-alt-r:reload@$reload_command@+first,alt-enter:toggle" \
            --header-lines=1 \
            --prompt 'processes: ' \
            # I 'echo' the fzf placeholder in the grep regex to get around the fact that fzf substitutions are single quoted and the quotes
            # would mess up the grep regex.
            --preview 'ps --pid {2} >/dev/null; or begin; echo "There is no running process with this ID."; exit; end; echo -s (set_color brwhite) {} (set_color normal); pstree --hide-threads --long --show-pids --unicode --show-parents --arguments {2} | GREP_COLORS="ms=00;36" grep --color=always --extended-regexp --regexp "[^└|─]+,$(echo {2})( .*|\$)" --regexp "^"' \
            --tiebreak=chunk,begin,end \
            --no-hscroll \
            --preview-window 'nowrap' \
      )
  or begin
    # necessary since I'm using the --no-clear option in fzf
    tput rmcup

    return
  end

  set process_ids (printf %s\n $choice | awk '{print $2}')
  set process_command_names (printf %s\n $choice | awk '{print $7}')
  for index in (seq (count $process_ids))
    set --append process_ids_names "$process_ids[$index] ($process_command_names[$index])"
  end

  set signal \
      ( \
        FZF_DEFAULT_COMMAND="string split ' ' (kill -l)" \
        fzf \
            --bind "change:first" \
            --header 'Select a signal to send or exit to print the PIDs' \
            --prompt 'signals: ' \
            --preview '' \
      )
  or begin
    printf %s\n $process_ids
    return
  end

  echo "Sending SIG$signal to the following processes: $(string join ', ' $process_ids_names)"
  kill --signal $signal $process_ids
end
