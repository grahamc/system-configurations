if not status is-interactive
    exit
end

function fzf-grep-widget --description 'Search by line, recursively, from current directory'
  set rg_command 'rg --hidden --column --line-number --no-heading --color=always --smart-case --follow --'
  set choice \
      ( \
        FZF_DEFAULT_COMMAND="echo -n ''" \
        FZF_HINTS='ctrl+e: edit in neovim' \
        fzf-tmux-zoom \
            --ansi \
            --disabled \
            # we refresh-preview after executing vim in the event that the file gets modified by vim
            --bind "ctrl-e:execute(nvim '+call cursor({2},{3})' {1} < /dev/tty > /dev/tty 2>&1)+refresh-preview,change:first+reload:sleep 0.1; $rg_command {q} || true" \
            --delimiter ':' \
            --prompt 'lines: ' \
            --preview-window '+{2}/3' \
            # the minus 2 prevents a weird line wrap issue
            # The head and tail commands are there to remove the first and last line of output of bat
            # i.e. the top and bottom border of bat since I don't like how they look
            --preview 'bat --paging=never --terminal-width (math $FZF_PREVIEW_COLUMNS - 2) {1} --highlight-line {2} | tail -n +2 | head -n -1' \
      )
  or return

  set tokens (string split ':' $choice)
  set filename $tokens[1]
  commandline --insert $filename

  # this should be done whenever a binding produces output (see: man bind)
  commandline -f repaint
end
bind-no-focus \cg 'fzf-grep-widget'

function fzf-man-widget --description 'Search manpages'
  set choice \
      ( \
        FZF_DEFAULT_COMMAND='man -k . --long' \
         fzf-tmux-zoom  \
            --ansi \
            --tiebreak=chunk,begin,end \
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
    return
  end

  set manpage_name (echo $choice | awk '{print $1}')
  set manpage_section (echo $choice | awk '{print $2}' | string sub --start=2 --end=-1)
  man $manpage_section $manpage_name
end
abbr --add --global fm fzf-man-widget

function fzf-process-widget --description 'Manage processes'
  set reload_command 'ps -e --format user,pid,ppid,nice=NICE,start_time,etime,command --sort=-start_time'
  set choice \
      ( \
        FZF_DEFAULT_COMMAND="$reload_command" \
        FZF_HINTS='ctrl+alt+r: refresh process list' \
        fzf \
            --ansi \
            # only search on PID, PPID, and the command
            --nth '2,3,7..' \
            --bind "change:first,ctrl-alt-r:reload@$reload_command@+first" \
            --header-lines=1 \
            --prompt 'processes: ' \
            # I 'echo' the fzf placeholder in the grep regex to get around the fact that fzf substitutions are single quoted and the quotes
            # would mess up the grep regex.
            --preview 'ps --pid {2} >/dev/null; or begin; echo "There is no running process with this ID."; exit; end; echo -s (set_color brwhite) {} (set_color normal); pstree --hide-threads --long --show-pids --unicode --show-parents --arguments {2} | GREP_COLORS="ms=00;36" grep --color=always --extended-regexp --regexp "[^└|─]+,$(echo {2})( .*|\$)" --regexp "^"' \
            --tiebreak=chunk,begin,end \
            --no-hscroll \
            --preview-window 'nowrap' \
      )
  or return

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
  set sudo ''
  for process_id in $process_ids
    if test "$(ps -o user= -p $process_id)" = 'root'
      set sudo 'sudo'
      break
    end
  end
  fish -c "$sudo kill --signal $signal $process_ids"
end
abbr --add --global fp fzf-process-widget

function my-fzf-file-widget --description 'Search files'
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

  set choices \
      ( \
        FZF_DEFAULT_COMMAND="test '$dir' = '.' && set _args '--strip-cwd-prefix' || set _args '.' '$dir'; fd \$_args --follow --hidden --type file --type symlink" \
        fzf-tmux-zoom \
            --ansi \
            --bind "change:first" \
            --prompt "$prompt" \
            --preview "$preview_command" \
      )
  or return

  commandline --current-token --replace "$choices"

  # this should be done whenever a binding produces output (see: man bind)
  commandline -f repaint
end
bind-no-focus \cf 'my-fzf-file-widget'
