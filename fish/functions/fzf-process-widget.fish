function fzf-process-widget --description 'Manage processes'
  set reload_command 'date; ps -eo user,pid,ppid,nice,start_time,etime,command'
  set choice \
      ( \
        FZF_DEFAULT_COMMAND="$reload_command" \
        fzf-tmux -B -p 100% -- \
            --ansi \
            --tac \
            --bind "change:first,ctrl-r:reload($reload_command)+first,ctrl-k:execute(clear > /dev/tty 2>&1; echo 'Are you sure? (y/n):' > /dev/tty 2>&1; read --prompt='echo -n \"> \" > /dev/tty 2>&1' --nchars 1 response; test \$response = y; and kill --signal SIGKILL {2})+reload($reload_command)" \
            --header '(ctrl+r to refresh, ctrl+k to send SIGKILL)' \
            --header-lines=2 \
            --prompt 'processes: ' \
            --preview-window '~1' \
            # I 'echo' the fzf placeholder in the grep regex to get around the fact that fzf substitutions are single quoted and the quotes
            # would mess up the grep regex.
            --preview 'echo -s (set_color black) {} (set_color normal); pstree --hide-threads --long --show-pids --unicode --show-parents --arguments {2} | GREP_COLORS="ms=00;36" grep --color=always --extended-regexp --regexp "[^└|─]+,$(echo {2})( .*|\$)" --regexp "^"' \
      )
  or return

  echo $choice | awk '{print $2}'
end
