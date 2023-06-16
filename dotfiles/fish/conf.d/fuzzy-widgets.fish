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
            --disabled \
            # we refresh-preview after executing vim in the event that the file gets modified by vim
            --bind "ctrl-e:execute(nvim '+call cursor({2},{3})' {1} < /dev/tty > /dev/tty 2>&1)+refresh-preview,change:first+reload:sleep 0.1; $rg_command {q} || true" \
            --delimiter ':' \
            --prompt 'lines: ' \
            --preview-window '+{2}/3,75%,~2' \
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
mybind --no-focus \cg 'fzf-grep-widget'

function fzf-man-widget --description 'Search manpages'
  # This command turns 'manpage_name(section) - description' into 'section manpage_name'.
  # The `\s?` is there because macOS separates the name and section with a space.
  set parse_entry_command "string replace --regex -- '(?<name>^.*)\s?\((?<section>.*)\)\s+.*\$' '\$section \$name'"

  set choice \
      ( \
        FZF_DEFAULT_COMMAND='man -k . --long' \
         fzf-tmux-zoom  \
            --tiebreak=chunk,begin,end \
            --prompt 'manpages: ' \
            --preview "eval 'MANWIDTH=\$FZF_PREVIEW_COLUMNS man '($parse_entry_command {})" \
            --preview-window '75%' \
      )
  or return

  eval 'man '(eval "$parse_entry_command '$choice'")
end
abbr --add --global fm fzf-man-widget

function fzf-process-widget --description 'Manage processes'
  # I 'echo' the fzf placeholder in the grep regex to get around the fact that fzf substitutions are single quoted and the quotes
  # would mess up the grep regex.
  if uname | grep -q Linux
    set reload_command 'ps -e --format user,pid,ppid,nice=NICE,start_time,etime,command --sort=-start_time'
    set preview_command 'ps --pid {2} >/dev/null; or begin; echo "There is no running process with this ID."; exit; end; echo -s (set_color brwhite) {} (set_color normal); pstree --hide-threads --long --show-pids --unicode --show-parents --arguments {2} | GREP_COLORS="ms=00;36" grep --color=always --extended-regexp --regexp "[^└|─]+,$(echo {2})( .*|\$)" --regexp "^"'
    set catp_command 'sudo catp {2}'
  else
    set reload_command 'ps -e -o user,pid,ppid,nice=NICE,start,etime,command'
    set preview_command 'ps -p {2} >/dev/null; or begin; echo "There is no running process with this ID."; exit; end; echo -s (set_color brwhite) {} (set_color normal); pstree -w -g 3 -p {2} | GREP_COLORS="ms=00;36" grep --color=always --extended-regexp --regexp " 0*$(echo {2}) $(echo {1}) .*" --regexp "^"'
    set catp_command 'echo "Viewing process output is not supported on macOS. Press enter to continue" >/dev/tty; read </dev/tty'
  end

  set choice \
      ( \
        FZF_DEFAULT_COMMAND="$reload_command" \
        FZF_HINTS='ctrl+alt+r: refresh process list\nctrl+alt+o: view process output' \
        fzf \
            # only search on PID, PPID, and the command
            --nth '2,3,7..' \
            --bind "ctrl-alt-o:execute@$catp_command@,ctrl-alt-r:reload@$reload_command@+first" \
            --header-lines=1 \
            --prompt 'processes: ' \
            --preview "$preview_command" \
            --tiebreak=chunk,begin,end \
            --no-hscroll \
            --preview-window 'nowrap,75%' \
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
  if test "$(string sub --length 1 -- "$dir")" = '~'
    set dir (string replace '~' "$HOME" "$dir")
  end
  if not test -d "$dir"
    set dir '.'
  end

  set prompt (string replace "$HOME" '~' "$dir")
  if test "$(string sub --start -1 "$dir")" != '/'
    set prompt "$prompt/"
  end

  # Regarding the bat command:
  # - the minus 2 prevents a weird line wrap issue
  # - The head and tail commands are there to remove the first and last line of output of bat i.e. the top and bottom
  # border of bat since I don't like how they look
  set preview_command '
  if file --brief --mime-type {} | grep -q -i image
    if set --query TMUX
      timg --center -g "$FZF_PREVIEW_COLUMNS"x"$FZF_PREVIEW_LINES" -p quarter {}
    else if test "$TERM_PROGRAM" = WezTerm
      # This should have "-p kitty", but that won\'t work until fzf has support for Kitty\'s image format:
      # issue: https://github.com/junegunn/fzf/issues/3228
      timg --center -g "$FZF_PREVIEW_COLUMNS"x"$FZF_PREVIEW_LINES" {}
    else
      timg --center -g "$FZF_PREVIEW_COLUMNS"x"$FZF_PREVIEW_LINES" {}
    end
  else
    bat --paging=never --terminal-width (math $FZF_PREVIEW_COLUMNS - 2) {} | tail -n +2 | head -n -1
  end
  '

  set choices \
      ( \
        FZF_DEFAULT_COMMAND="test '$dir' = '.' && set _args '--strip-cwd-prefix' || set _args '.' '$dir'; fd \$_args --follow --hidden --type file --type symlink" \
        fzf-tmux-zoom \
            --prompt "$prompt" \
            --preview "$preview_command" \
            --preview-window '75%,~2' \
      )
  or return

  set escaped_choices
  for choice in $choices
    set --append escaped_choices (string escape --style script --no-quoted "$choice")
  end

  commandline --current-token --replace "$escaped_choices"

  # this should be done whenever a binding produces output (see: man bind)
  commandline -f repaint
end
mybind --no-focus \cf 'my-fzf-file-widget'

# use ctrl+d for directory search instead of default alt+c
function fzf-directory-widget --description 'Seach directories'
  set dir "$(commandline -t)"
  if test "$(string sub --length 1 -- "$dir")" = '~'
    set dir (string replace '~' "$HOME" "$dir")
  end
  if not test -d "$dir"
    set dir '.'
  end

  set prompt (string replace "$HOME" '~' "$dir")
  if test "$(string sub --start -1 "$dir")" != '/'
    set prompt "$prompt/"
  end

  set choices \
      ( \
        FZF_DEFAULT_COMMAND="test '$dir' = '.' && set _args '--strip-cwd-prefix' || set _args '.' '$dir'; fd \$_args --follow --hidden --type directory --type symlink" \
        fzf-tmux-zoom \
            --prompt "$prompt" \
            --preview 'echo -s {} \n (set_color brwhite)(string repeat --count $FZF_PREVIEW_COLUMNS ─); lsd {}' \
            --preview-window '75%,~2' \
            --keep-right \
      )
  or return

  set escaped_choices
  for choice in $choices
    set --append escaped_choices (string escape --style script --no-quoted "$choice")
  end

  commandline --current-token --replace "$escaped_choices"

  commandline -f repaint
end
mybind --no-focus \ed 'fzf-directory-widget'
