set left_splitbar \u257C
set right_splitbar \u257E
set connectbar_up \u2514
set connectbar_down \u250C
set connectbar_middle \u251C
# The reason for all the 'set_color normal' commands is to undo the bold set by the border color
set fish_prompt_color_text (set_color normal; set_color brcyan)
set fish_prompt_color_standout_text (set_color normal; set_color yellow)
set fish_prompt_color_error_text (set_color normal; set_color red)
set fish_prompt_color_normal (set_color normal)
set fish_prompt_color_arrow (set_color normal; set_color black)
set fish_prompt_color_border (set_color normal; set_color --bold black)

set --global --export __fish_git_prompt_showdirtystate
set --global --export __fish_git_prompt_showupstream informative
set --global --export __fish_git_prompt_showuntrackedfiles

# async prompt
set --universal async_prompt_functions testing
# function fish_prompt_get_git_context_loading_indicator
#     echo -n -s $fish_prompt_color_text (set_color --dim) 'git: loading…'
# end

function fish_prompt --description 'Print the prompt'
    # pipestatus contains the exit code(s) of the last command that was executed
    # (there are multiple codes in the case of a pipeline). I want the value of the last command
    # executed on the command line so I will store the value of pipestatus
    # now, before executing any commands.
    set last_pipestatus $pipestatus

    # transient prompt
    if set --query TRANSIENT
        set --erase TRANSIENT

        # TODO: This clears the text in the terminal after the cursor. If we don't do this, multiline
        # transient prompts won't display properly.
        # issue: https://github.com/fish-shell/fish-shell/issues/8418
        printf \e\[0J

        echo -n -s -e (fish_prompt_get_separator) "\n" (set_color brcyan) (fish_prompt_get_arrow) ' ' $fish_prompt_color_normal
        return
    else if set --query TRANSIENT_EMPTY
        set --erase TRANSIENT_EMPTY

        # TODO: This clears the text in the terminal after the cursor. If we don't do this, multiline
        # transient prompts won't display properly.
        # issue: https://github.com/fish-shell/fish-shell/issues/8418
        printf \e\[0J

        # Print nothing. This results in the prompt being refreshed in-place since it erases the old prompt, prints nothing,
        # and then draws the prompt again.
        echo -n ''
        return
    end

    # Get the number of columns for the terminal window or tmux pane. Setting this value now since it gets used in some
    # of the context functions.
    set --global --export columns (stty size | cut -d" " -f2)

    set -l lines
    set -l contexts \
        (fish_prompt_get_direnv_context) \
        (fish_prompt_get_python_context) \
        (fish_prompt_get_git_context) \
        (fish_prompt_get_job_context) \
        (fish_prompt_get_user_context) \
        (fish_prompt_get_path_context) \
        (fish_prompt_get_privilege_context) \
        (fish_prompt_get_status_context $last_pipestatus)
    for context in $contexts
        if test -z $context
            continue
        end

        if not set --query lines[1]
            set --local first_line (string join '' (fish_prompt_make_line first) (fish_prompt_format_context $context))
            set --append lines $first_line
            continue
        end

        set --local formatted_context (fish_prompt_format_context $context)
        set --local middle_line (string join '' (fish_prompt_make_line) $formatted_context)
        set --append lines $middle_line
    end
    set --append lines (fish_prompt_make_line last)
    # Use underline to visually separate commands
    set --prepend lines (fish_prompt_get_separator)
    echo -e -n (string join '\n' $lines)
end

function fish_prompt_get_separator
    echo -n -s ' '
end

function fish_prompt_format_context --argument-names context
    echo -n -s $fish_prompt_color_border $left_splitbar [ $context $fish_prompt_color_border ]
end

function fish_prompt_make_line --argument-names type
    if test "$type" = first
        echo -n -s $fish_prompt_color_border $connectbar_down
    else if test "$type" = last
        echo -n -s $fish_prompt_color_border $connectbar_up $fish_prompt_color_arrow (fish_prompt_get_arrow) $fish_prompt_color_normal ' '
    else
        echo -n -s $fish_prompt_color_border $connectbar_middle
    end
end

function fish_prompt_get_arrow
    string repeat -n $SHLVL '❯'
end

function fish_prompt_get_python_context
    if not set --query VIRTUAL_ENV
        return
    end

    echo -n -s $fish_prompt_color_text 'venv: ' (fish_prompt_get_python_venv_name)
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

    echo -n $last_path_segment
end

function fish_prompt_get_job_context
    if not jobs --query
        return
    end

    set --local job_commands (jobs --command)
    set --local formatted_job_commands (string split ' ' $job_commands | string join ,)
    echo -n -s $fish_prompt_color_text 'jobs: ' $formatted_job_commands
end

function fish_prompt_get_privilege_context
    set privilege_context
    if test (id --user) -eq 0
        set privilege_context 'user has admin privileges'
    else if sudo --non-interactive true 2>/dev/null
        set privilege_context 'sudo credentials cached'
    end

    if test -z "$privilege_context"
        return
    end

    echo -n -s $fish_prompt_color_standout_text $privilege_context
end

function fish_prompt_get_user_context
    if not set --query SSH_TTY
        return
    end

    echo -n -s $fish_prompt_color_text "user: $USER in $(hostname)"
end

function fish_prompt_get_path_context
    set -g fish_prompt_pwd_dir_length 0
    set path (prompt_pwd)

    set dir_length 5
    while test (string length --visible $path) -gt (math $columns - 10) -a $dir_length -ge 1
        set -g fish_prompt_pwd_dir_length $dir_length
        set path (prompt_pwd)
        set dir_length (math $dir_length - 1)
    end

    echo -n -s $fish_prompt_color_text 'path: ' $path
end

function fish_prompt_get_status_context
    # If there aren't any non-zero exit codes, i.e. failures, then we won't print anything
    if not string match --quiet --invert 0 $argv
        return
    end
    set --local pipestatus_formatted (fish_status_to_signal $argv | string join '|')
    echo -n -s $fish_prompt_color_error_text 'status: ' $pipestatus_formatted
end

function fish_prompt_get_direnv_context
    if not set --query DIRENV_DIR
        return
    end
    # remove the '-' in the beginning
    echo -n -s $fish_prompt_color_text 'direnv: ' (basename (string sub --start 2 -- $DIRENV_DIR))
end

function fish_prompt_get_git_context
    set --global __fish_git_prompt_char_upstream_ahead ',ahead:'
    set --global __fish_git_prompt_char_upstream_behind ',behind:'
    set --global __fish_git_prompt_char_untrackedfiles ',untracked'
    set --global __fish_git_prompt_char_dirtystate ',dirty'
    set --global __fish_git_prompt_char_stagedstate ',staged'
    set --global __fish_git_prompt_char_invalidstate ',invalid'
    set --global __fish_git_prompt_char_stateseparator ''

    set git_context (fish_git_prompt)
    if test -z $git_context
        return
    end

    # DEBUG: Simulate increased latency when accessing the git remote. This way I can test
    # the async prompt
    # sleep 2

    if test (string length --visible $git_context) -gt (math $columns - 10)
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

    echo -n -s $fish_prompt_color_text 'git: ' $formatted_context
end
