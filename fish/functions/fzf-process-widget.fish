function fzf-process-widget --description 'Manage processes'
  set reload_command 'date; ps -eo user,pid,ppid,start_time,time,command'
  set choice \
      ( \
        FZF_DEFAULT_COMMAND="$reload_command" \
        fzf-tmux -p 100% \
            --ansi \
            --tac \
            --bind "change:first,ctrl-r:reload($reload_command),ctrl-k:execute(printf \"\033[2J\";echo 'Are you sure?' > /dev/tty 2>&1; read --prompt='echo -n \"> \" > /dev/tty 2>&1' --nchars 1 response; test \$response = y; and kill --signal SIGKILL {2})+reload($reload_command)" \
            --header '(ctrl+r to refresh, ctrl+k to send SIGKILL)' \
            --header-lines=2 \
            --prompt 'processes: ' \
            # The 'string join' is to get around the fact that fzf substitutions are single quoted and the quotes
            # would mess up the grep regex
            --preview 'echo -s (set_color magenta) {} (set_color normal); pstree --long --show-pids --unicode --show-parents --arguments {2} | GREP_COLORS="ms=00;34" grep --color=always -E (string join "" "(.*," {2} ".*|^)")' \
      )
  or return

  echo $choice | awk '{print $2}'
end
