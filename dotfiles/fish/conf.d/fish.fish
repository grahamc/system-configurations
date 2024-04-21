# I'm defining this before the interactivity check so I can call this from
# non-interactive shells. This way I can reload my shells from a script.
function fish-reload
    set --universal _fish_reload_indicator (random)
end

if not status is-interactive
    exit
end

set --global fish_color_normal
set --global fish_color_command $fish_color_normal
set --global fish_color_keyword blue
set --global fish_color_quote green
set --global fish_color_redirection magenta
set --global fish_color_end $fish_color_keyword
set --global fish_color_error red
set --global fish_color_param $fish_color_normal
set --global fish_color_option $fish_color_normal
set --global fish_color_comment brblack
set --global fish_color_match
set --global fish_color_search_match --background=brblack
# TODO: I want to remove the default bolding, but currently only the background
# is configurable.
# Issue: https://github.com/fish-shell/fish-shell/issues/2442
set --global fish_pager_color_selected_background --background=brblack
set --global fish_color_operator $fish_color_keyword
set --global fish_color_escape $fish_color_redirection
set --global fish_color_cwd
set --global fish_color_autosuggestion brblack --bold
set --global fish_color_user
set --global fish_color_host
set --global fish_pager_color_prefix cyan
set --global fish_pager_color_completion
set --global fish_pager_color_description
set --global fish_pager_color_progress --background=brblack normal
set --global fish_pager_color_secondary
set --global fish_color_cancel $fish_color_autosuggestion
set --global fish_color_valid_path

abbr --add --global r fish-reload

# Don't print a greeting when a new interactive fish shell is started
set --global --export fish_greeting ''

# use ctrl+z to resume the most recently suspended job
function _resume_job
    if not jobs --query
        return
    end

    set job_count (jobs | wc -l)

    if test "$job_count" -eq 1
        fg 1>/dev/null 2>&1

        # this should be done whenever a binding produces output (see: man bind)
        commandline -f repaint

        return
    end

    set delimiter ':delim:'
    set entries
    for job_pid in (jobs --pid)
        set job_command (ps -o command= -p "$job_pid")
        set --append entries "$job_pid$delimiter$job_command"
    end

    set choice \
        ( \
            # I'm using the NUL character to delimit entries since they may span
            # multiple lines.
            printf %s'\0' $entries \
                | fzf  \
                    --read0 \
                    --delimiter $delimiter \
                    --with-nth '2..' \
                    --no-preview \
                    --height ~30% \
                    --margin 0,2,0,2 \
                    --border rounded \
                    --no-multi \
                | string replace \n '␊' \
        )
    if test -n "$choice"
        set tokens (string split $delimiter "$choice")
        set pid $tokens[1]
        fg "$pid" 1>/dev/null 2>&1
    end

    # this should be done whenever a binding produces output (see: man bind)
    commandline -f repaint
end
mybind --no-focus \cz _resume_job

# use shift+right-arrow to accept the next suggested word
mybind \e\[1\;2C forward-word

# use ctrl+b to jump to beginning of line
mybind \cb beginning-of-line

# ctrl+r to refresh terminal, shell, and screen
#
# Set the binding on fish_prompt since something else was overriding it.
function __set_reload_keybind --on-event fish_prompt
    # I only want this to run once so delete the function.
    functions -e (status current-function)
    mybind --no-focus \cr 'reset && exec fish && clear'
end

# search variables
function variable-widget --description 'Search shell/environment variables'
    for name in (set --names)
        set value (set --show $name)
        set entry "$name"\t"$(string join \n $value)"
        set --append entries $entry
    end

    # I'm using the NUL character to delimit entries since they may span
    # multiple lines.
    if not set choices ( \
        printf %s'\0' $entries \
            | fzf \
                --read0 \
                --print0 \
                --delimiter \t \
                --with-nth 1 \
                --preview 'echo {2..}' \
                --prompt '$' \
            | string split0 \
    )
        return
    end

    for choice in $choices
        set name (string split --fields 1 -- \t $choice)
        set --append chosen_names $name
    end

    if not set choice ( \
        printf %s'\n' name value \
        | fzf \
            --prompt 'output type: ' \
            --no-preview
    )
        return
    end

    set to_insert
    for chosen_name in $chosen_names
        if test $choice = value
            set --append to_insert $$chosen_name
        else
            set --append to_insert $chosen_name
        end
    end

    echo $to_insert
end
abbr --add --global vw variable-widget

# Use tab to select an autocomplete entry with fzf
function _insert_entries_into_commandline
    # Remove the tab and description, leaving only the completion items.
    set entries $(string split -f1 -- \t $argv)
    set entry (string join -- ' ' $entries)

    set space ' '

    # None of this applies if there are mutiple entries
    if test (count $entries) -eq 1
        # Don't add a space if the entry is an abbreviation.
        #
        # TODO: This assumes that an abbreviation can only be expanded if
        # it's the first token in the commandline.  However, with the flag
        # '--position anywhere', abbreviations can be expanded anywhere in the
        # commandline so I should check for that flag.
        #
        # We determine if the entry will be the first token by checking for
        # an empty commandline.  We trim spaces because spaces don't count as
        # tokens.
        set trimmed_commandline (string trim "$(commandline)")
        if abbr --query -- "$entry"
            and test -z "$trimmed_commandline"
            set space ''
        end

        # Don't add a space if the item is a directory and ends in a slash.
        #
        # Use eval so expansions are done e.g. environment variables,
        # tildes. For scenarios like (bar is cursor) `echo "$HOME/|"` where the
        # autocomplete entry will include the left quote, but not the right
        # quote. I remove the left quote so `test -d` works.
        if test (string sub --length 1 --start 1 -- "$entry") = '"' -a (string sub --start -1 -- "$entry") != '"'
            set balanced_quote_entry (string sub --start 2 -- "$entry")
        else
            set balanced_quote_entry "$entry"
        end
        if eval test -d "$balanced_quote_entry" && test (string sub --start -1 -- "$entry") = /
            set space ''
        end
    end

    # retain the part of the token after the cursor. use case: autocompleting
    # inside quotes (bar is cursor) `echo "$HOME/|"`
    set token_after_cursor "$(string sub --start (math (string length -- "$(commandline --current-token --cut-at-cursor)") + 1) -- "$(commandline --current-token)")"
    set replacement "$entry$space$token_after_cursor"

    # if it ends in `""` or `" "` (when we add a space), remove one quote. use
    # case: autocompleting a file inside quotes (bar is cursor) `echo "/|"`
    set replacement (string replace --regex -- '"'$space'"$' $space'"' "$replacement")
    or set replacement (string replace --regex -- "'$space'\$" $space"'" "$replacement")

    commandline --replace --current-token -- "$replacement"
end
function _fzf_complete
    set candidates (complete --escape --do-complete -- "$(commandline --cut-at-cursor)")
    set candidate_count (count $candidates)
    # I only want to repaint if fzf is shown, but if I use `fzf --select-1` fzf
    # won't be shown when there's one candidate and there is no way to tell
    # if that's how fzf exited so instead I'll check the amount of candidates
    # beforehand an only use fzf is there's more than 1. Same situation with
    # --exit-0.
    if test $candidate_count -eq 1
        _insert_entries_into_commandline $candidates
    else if test $candidate_count -gt 1
        set current_token (commandline --current-token --cut-at-cursor)
        if set entries ( \
            printf %s\n $candidates \
            # Use a different color for the completion item description
            | string replace --ignore-case --regex -- \
                '(?<prefix>^'(string escape --style regex -- "$current_token")')(?<item>[^\t]*)((?<whitespace>\t)(?<description>.*))?' \
                (set_color cyan)'$prefix'(set_color normal)'$item'(set_color brblack)'$whitespace$description' \
            | fzf \
                --height (math "max(6,min(10,$(math "floor($(math .35 \* $LINES))")))") \
                --preview-window '2,border-left,right,60%' \
                --no-header \
                --bind 'backward-eof:abort,start:toggle-preview' \
                --no-hscroll \
                --tiebreak=begin,chunk \
                # I set the current token as the delimiter so I can exclude
                # from what gets searched.  Since the current token is in the
                # beginning of the string, it will be the first field index so
                # I'll start searching from 2.
                --delimiter '^'(string escape --style regex -- $current_token) \
                --nth '2..' \
                --border rounded \
                --margin 0,2,0,2 \
                --prompt $current_token \
                --no-separator \
        )
            _insert_entries_into_commandline $entries
        end
        commandline -f repaint
    end
end
# Set the binding on fish_prompt since something else was overriding it during
# shell startup.
function __set_fzf_tab_complete --on-event fish_prompt
    # I only want this to run once so delete the function.
    functions -e (status current-function)
    mybind --no-focus \t _fzf_complete
end
# Keep normal tab complete on shift+tab to expand wildcards.
mybind -k btab complete

# File explorer
function _ls_after_directory_change --on-variable PWD
    # Nix store freezes broot
    if test "$PWD" = /nix/store
        return
    end
    # TODO: broot only exits with a non-zero code if the server socket doesn't exist, but I would
    # like it to also exit with a non-zero code if the socket exists and nothing is listening on the
    # other end. It does however, print an error message in both cases so instead I'm checking if
    # anything was written to stderr.
    if test -n "$(br --send "$TMUX_PANE" 2>&1 1>/dev/null)"
        # These directories have too many files to always call ls on
        #
        # normalize to remove trailing slash
        set blacklist /nix/store /tmp (path normalize "$TMPDIR")
        if contains "$PWD" $blacklist
            return
        end

        ls
    end
end
function _bigolu_on_broot_dir_change --on-variable _broot_dir
    # When we change the directory in broot, broot will be the active pane so we
    # need to explictly set the target pane to that of this fish process. We set
    # `-q` so tmux doesn't consider it an error if the option can't be found.
    set value (tmux show-option -gvq -t "$TMUX_PANE" '@-sidebar-registered-pane-#{pane_id}')
    if test -n "$value"
        set pane (string match --regex --groups-only -- '^(%[0-9]+)' "$value")
        if tmux display-message -p -t "$pane" >/dev/null
            set parts (string split ':' "$_broot_dir")
            if test "$pane" = "$parts[1]"
                cd "$parts[2]"
                # TODO: fish isn't emitting fish_prompt before I run `repaint`
                # so direnv isn't triggering. I should open an issue to see if
                # this is intended.
                emit fish_prompt
                commandline -f repaint
            end
        end
    end
end
# TODO: I can remove this when this issue is resolved:
# https://github.com/Canop/broot/issues/730
function _bigolu_refresh_broot --on-event fish_postexec
    br --send "$TMUX_PANE" -c ':refresh;' 2>/dev/null
end

# Reload all fish instances
function _reload_fish --on-variable _fish_reload_indicator
    if jobs --query
        echo -n -e "\n$(set_color --reverse --bold yellow) WARNING $(set_color normal) The shell will not reload since there are jobs running in the background.$(set_color normal)"
        commandline -f repaint
        return
    end
    exec fish
end

# BASH-style history expansion
function _bash_style_history_expansion
    set token "$argv[1]"
    set last_command "$history[1]"
    printf '%s' "$last_command" | read --tokenize --list last_command_tokens

    if test "$token" = '!!'
        echo "$last_command"
    else if test "$token" = '!^'
        echo "$last_command_tokens[1]"
    else if test "$token" = '!$'
        echo "$last_command_tokens[-1]"
    else if string match --quiet --regex -- '\!\-?\d+' "$token"
        set last_command_token_index (string match --regex -- '\-?\d+' "$token")
        set absolute_value (math abs "$last_command_token_index")
        if test "$absolute_value" -gt (count $last_command_tokens)
            return 1
        end
        echo "$last_command_tokens[$last_command_token_index]"
    else
        return 1
    end
end
abbr --add bash_style_history_expansion \
    --position anywhere \
    --regex '\!(\!|\^|\$|\-?\d+)' \
    --function _bash_style_history_expansion

# Most of this was taken from fish's __fish_man_page, I just added flag
# searching.
function _man_page
    # Get all commandline tokens not starting with "-", up to and including the
    # cursor's
    set -l args (string match -rv '^-|^$' -- (commandline --cut-at-cursor --tokenize --current-process && commandline --current-token))

    # If commandline is empty, exit.
    if not set -q args[1]
        printf \a
        return
    end

    # Skip leading commands and display the manpage of following command
    while set -q args[2]
        and string match -qr -- '^(and|begin|builtin|caffeinate|command|doas|entr|env|exec|if|mosh|nice|not|or|pipenv|prime-run|setsid|sudo|systemd-nspawn|time|watch|while|xargs|.*=.*)$' $args[1]
        set -e args[1]
    end

    # If there are at least two tokens not starting with "-", the second one
    # might be a subcommand.  Try "man first-second" and fall back to "man
    # first" if that doesn't work out.
    set -l maincmd (basename $args[1])
    # HACK: If stderr is not attached to a terminal `less` (the default pager)
    # wouldn't use the alternate screen.  But since we don't know what pager it
    # is, and because `man` is totally underspecified, the best we can do is to
    # *try* the man page, and assume that `man` will return false if it fails.
    # See #7863.
    if set -q args[2]
        and not string match -q -- '*/*' $args[2]
        and man "$maincmd-$args[2]" &>/dev/null
        set manpage_name "$maincmd-$args[2]"
    else if man "$maincmd" &>/dev/null
        set manpage_name "$maincmd"
    else
        printf \a
        return
    end

    set wrapped (string match --groups-only --regex -- '.*\-\-wraps (.*)' (complete -c $manpage_name))
    if test -n "$wrapped"
        set manpage_name $wrapped
    end

    # If the token underneath or right before the cursor starts with a '-' try
    # to search for that flag
    set current_token (commandline --current-token)
    if test -z "$current_token"
        set current_token (commandline --cut-at-cursor --tokenize --current-process)[-1]
    end
    if string match --regex '^-' -- $current_token
        man "$manpage_name" | less --pattern "^\s+(\-\-?[^\s]+[,/\s]+)*\K$(string escape --style regex -- $current_token)"
    else
        man "$manpage_name"
    end

    commandline -f repaint
end
mybind --no-focus \ck _man_page

# navigate history
mybind --key f7 up-or-search
mybind --key f8 down-or-search

# It's like the builtin edit_command_buffer, but it retains the cursor position
function __edit_commandline
    set buffer "$(commandline)"
    set index (commandline --cursor)
    set line 1
    set col 1
    set cursor 0

    for char in (string split '' "$buffer")
        if test $cursor -ge $index
            break
        end

        if test "$char" = \n
            set col 1
            set line (math $line + 1)
        else
            set col (math $col + 1)
        end

        set cursor (math $cursor + 1)
    end

    set cursor_file (mktemp)
    set write_index 'lua vim.api.nvim_create_autocmd([[VimLeavePre]], {callback = function() vim.cmd([[redi! > '$cursor_file']]); print(#table.concat(vim.fn.getline(1, [[.]]), " ") - (#vim.fn.getline([[.]]) - vim.fn.col([[.]])) - 1); vim.cmd([[redi END]]); end})'

    set temp (mktemp --suffix '.fish')
    echo -n "$buffer" >$temp
    BIGOLU_EDITING_FISH_BUFFER=1 nvim -c "call cursor($line,$col)" -c "$write_index" $temp
    commandline "$(cat $temp)"
    commandline --cursor "$(cat $cursor_file)"
end
mybind \eE __edit_commandline

# fish loads builtin configs after user configs so I have to wait
# for the builtin binds to be defined. This may change though:
# https://github.com/fish-shell/fish-shell/issues/8553
function __remove_paginate_keybind --on-event fish_prompt
    # I only want this to run once so delete the function.
    functions -e (status current-function)
    bind --erase --preset \ep
end

function fish_title
    set -q argv[1]; or set argv fish
    # Looks like '~/d/fish: git log' or '/e/apt: fish'
    echo (fish_prompt_pwd_dir_length=1 prompt_pwd): $argv
end
