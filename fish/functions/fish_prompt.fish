set left_splitbar \u257C
set right_splitbar \u257E
set connectbar_up \u2514
set connectbar_down \u250C
set connectbar_middle \u251C
set color_border (set_color --bold brblack)
set color_text (set_color normal; set_color cyan)
set color_standout_text (set_color normal; set_color yellow)
set color_normal (set_color normal)
set color_text_error (set_color normal; set_color red)
set color_arrow (set_color normal; set_color brblack)

set --global --export __fish_git_prompt_showdirtystate
set --global --export __fish_git_prompt_showupstream informative
set --global --export __fish_git_prompt_showuntrackedfiles

function fish_prompt --description 'Print the prompt'
    # pipestatus contains the exit code(s) of the last command that was executed
    # (there are multiple codes in the case of a pipeline). I want the value of the last command
    # executed on the command line so I will store the value of pipestatus
    # now, before executing any commands.
    set last_pipestatus $pipestatus

    # TODO: This clears the text in the terminal after the cursor. If we don't do this, multiline
    # transient prompts won't display properly.
    # issue: https://github.com/fish-shell/fish-shell/issues/8418
    printf \e\[0J

    # transient prompt
    if set --query TRANSIENT
        set --erase TRANSIENT
        echo -n -s $color_arrow (fish_prompt_get_arrow) ' ' $color_normal
        return
    else if set --query TRANSIENT_EMPTY
        set --erase TRANSIENT_EMPTY
        echo -n ' '
        return
    end

    # Setting this value now since it gets used in some of the context functions
    if set --query IN_TMUX
        # Get the id of the pane that belongs to this shell instance. This is different from the active pane
        # in tmux. This way when I am resizing one of the panes, the other panes will get _their_ new size
        # as opposed to the new size of the pane that I am currently dragging, which tmux would deem the active pane.
        set grep_pattern (string join '' '^' $fish_pid)
        set pane_id (tmux list-panes -a -F "#{pane_pid} #{pane_id}" | grep $grep_pattern | string sub --start (math (string length $fish_pid) + 2))

        set columns (echo -n (tmux display -t $pane_id -p '#{pane_width}'))
    else
        set columns $COLUMNS
    end

    set -l lines
    set -l contexts \
        (fish_prompt_get_direnv_context) \
        (fish_prompt_get_python_context) \
        (fish_prompt_get_git_context) \
        (fish_prompt_get_job_context) \
        (fish_prompt_get_user_context) \
        (fish_prompt_get_host_context) \
        (fish_prompt_get_path_context) \
        (fish_prompt_get_status_context)
    for context in $contexts
        if test -z $context
            continue
        end

        if not set --query lines[1]
            set --local first_line (string join '' (fish_prompt_make_line first) (fish_prompt_format_context $context first))
            set --append lines $first_line
            continue
        end

        # set -l formatted_context (fish_prompt_format_context $context)
        # # I take the minimum of the number of columns and 120 to prevent the prompt from going past 120 chars
        # if test (string length --visible (string join '' $lines[-1] $formatted_context)) -le (math "min(120, $columns)")
        #     set lines[-1] (string join '' $lines[-1] $formatted_context)
        #     continue
        # end

        set --local formatted_context (fish_prompt_format_context $context first)
        set --local middle_line (string join '' (fish_prompt_make_line) $formatted_context)
        set --append lines $middle_line
    end
    set --append lines (fish_prompt_make_line last)
    echo -e -n (string join '\n' $lines)
end

function fish_prompt_format_context --argument-names context type
    echo -n -s $color_border (test "$type" != 'first' && echo -n $right_splitbar) $left_splitbar [ $context $color_border ]
end

function fish_prompt_make_line --argument-names type
    if test "$type" = first
        echo -n -s $color_border $connectbar_down
    else if test "$type" = last
        echo -n -s -e $color_border $connectbar_up $color_arrow (fish_prompt_get_arrow) $color_normal ' '
    else
        echo -n -s $color_border $connectbar_middle
    end
end

function fish_prompt_get_arrow
    string repeat -n $SHLVL '❯'
end

function fish_prompt_get_python_context
    if not set --query VIRTUAL_ENV
        return
    end

    echo -n -s $color_text 'venv: ' (fish_prompt_get_python_venv_name)
end

function fish_prompt_get_python_venv_name
    set -l path_segments (string split -- / $VIRTUAL_ENV)
    set -l last_path_segment $path_segments[-1]

    # If the folder containing the virtualenv is named .venv, use the parent folder instead
    # since that should be more descriptive
    if test $last_path_segment = '.venv'
        echo -n $path_segments[-2]
        return
    end

    # pipenv adds a hash to the end of the directory containing the virtual environment
    # so we'll remove it e.g. 'myvenvdir-a45n39' -> 'myvenvdir'
    if set --query PIPENV_ACTIVE
        echo -n (string replace --regex '(.*)(-.*)$' '${1}' $last_path_segment)
        return
    end

    echo -n $last_path_segment
end

function fish_prompt_get_git_context --no-scope-shadowing
    set --global --export __fish_git_prompt_char_upstream_ahead ',ahead:'
    set --global --export __fish_git_prompt_char_upstream_behind ',behind:'
    set --global --export __fish_git_prompt_char_untrackedfiles ',untracked'
    set --global --export __fish_git_prompt_char_dirtystate ',dirty'
    set --global --export __fish_git_prompt_char_stagedstate ',staged'
    set --global --export __fish_git_prompt_char_invalidstate ',invalid'
    set --global --export __fish_git_prompt_char_stateseparator ''

    set git_context (fish_git_prompt)
    if test -z $git_context
        return
    end

    # subtract 4 for the unicode characters
    if test (string length --visible $git_context) -gt (math $columns - 4)
        set --global --export __fish_git_prompt_char_upstream_ahead '↑'
        set --global --export __fish_git_prompt_char_upstream_behind '↓'
        set --global --export __fish_git_prompt_char_untrackedfiles '?'
        set --global --export __fish_git_prompt_char_dirtystate '!'
        set --global --erase __fish_git_prompt_char_stagedstate
        set --global --erase __fish_git_prompt_char_invalidstate
        set --global --export __fish_git_prompt_char_stateseparator ' '
        set git_context (fish_git_prompt)
    end

    # remove parentheses and leading space e.g. ' (branch,dirty,untracked)' -> 'branch,dirty,untracked'
    set --local formatted_context (string sub --start=3 --end=-1 $git_context)

    # replace first comma with ' (' e.g. ',branch,dirty,untracked' -> ' (branch dirty,untracked'
    set --local formatted_context (string replace ',' ' (' $formatted_context)
    # only add the closing parenthese if we added the opening one
    and set formatted_context (string join '' $formatted_context ')')

    echo -n -s $color_text 'git: ' $formatted_context
end

function fish_prompt_get_job_context
    if not jobs --query
        return
    end

    set --local job_commands = (jobs --command)
    set --local formatted_job_commands (string split $job_commands | string join ,)
    echo -n -s $color_text 'jobs: ' $formatted_job_commands
end

function fish_prompt_get_user_context
    set privilege_context
    if test (id --user) -eq 0
        set privilege_context 'user has admin privileges'
        # TODO: I use this command to see if sudo currently has any credentials cached, but technically
        # this line attempts to extend the lifetime of the cache for another 15 minutes, failing if
        # there currently aren't any credentials cached. Since I only want to know if credentials
        # are cached, I should probably find something that just gives me that information without
        # extending anything.
    else if sudo --non-interactive --validate 2>/dev/null
        set privilege_context 'sudo credentials cached'
    end

    if not set --query SSH_TTY && test -z "$privilege_context"
        return
    end

    echo -n -s $color_text 'user: ' $USER $color_standout_text (test -n "$privilege_context" && string join '' ' (' $privilege_context ')')
end

function fish_prompt_get_host_context
    if not set --query SSH_TTY
        return
    end

    echo -n -s $color_text 'host: ' (hostname)
end

function fish_prompt_get_path_context --no-scope-shadowing
    set -g fish_prompt_pwd_dir_length 0
    set path (prompt_pwd)

    set dir_length 5
    while test (string length --visible $path) -gt (math $columns - 4) -a $dir_length -ge 1
        set -g fish_prompt_pwd_dir_length $dir_length
        set path (prompt_pwd)
        set dir_length (math $dir_length - 1)
    end

    echo -n -s $color_text 'path: ' $path
end

function fish_prompt_get_status_context --no-scope-shadowing
    # If there aren't any non-zero exit codes, i.e. failures, then we won't print anything
    if not string match --quiet --invert 0 $last_pipestatus
        return
    end
    set --local pipestatus_formatted (fish_status_to_signal $last_pipestatus | string join '|')
    echo -n -s $color_text_error 'status: ' $pipestatus_formatted
end

function fish_prompt_get_direnv_context
    if not set --query DIRENV_DIR
        return
    end
    # remove the '-' in the beginning
    echo -n -s $color_text 'direnv: ' (basename (string sub --start 2 -- $DIRENV_DIR))
end
