# The reason for all the 'set_color normal' commands is to undo any attributes set like '--bold'
set fish_prompt_color_text (set_color normal; set_color cyan)
set fish_prompt_color_standout_text (set_color normal; set_color yellow)
set fish_prompt_color_error_text (set_color normal; set_color red)
set fish_prompt_color_normal (set_color normal)
set fish_prompt_color_border (set_color normal; set_color brwhite)

function fish_prompt --description 'Print the prompt'
    # pipestatus contains the exit code(s) of the last command that was executed
    # (there are multiple codes in the case of a pipeline). I want the value of the last command
    # executed on the command line so I will store the value of pipestatus
    # now, before executing any commands.
    set last_pipestatus $pipestatus

    # TODO: This clears the text in the terminal after the cursor. If we don't do this, multiline
    # prompts might not display properly.
    # issue: https://github.com/fish-shell/fish-shell/issues/8418
    printf \e\[0J

    # transient prompt
    if set --query TRANSIENT
        set --erase TRANSIENT

        echo -n -s -e (fish_prompt_get_separator) "\n" $fish_prompt_color_text (fish_prompt_get_arrow) $fish_prompt_color_normal
        return
    else if set --query TRANSIENT_EMPTY
        set --erase TRANSIENT_EMPTY

        # Return without printing anything. This results in the prompt being refreshed in-place since it erases the
        # old prompt, prints nothing, and then draws the prompt again.
        return
    end

    set -l lines
    set -l contexts \
        (fish_prompt_get_direnv_context) \
        (fish_prompt_get_nix_context) \
        (fish_prompt_get_python_context) \
        (fish_prompt_get_git_context) \
        (fish_prompt_get_job_context) \
        (fish_prompt_get_host_context) \
        (fish_prompt_get_path_context) \
        (fish_prompt_get_status_context $last_pipestatus) \
        (fish_prompt_get_privilege_context)
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
    # Add another line to separate commands
    set --prepend lines (fish_prompt_get_separator)
    echo -e -n (string join '\n' $lines)
end

function fish_prompt_get_separator
    echo -n -s ' '
    # echo -n -s (set_color brblack) (string repeat -n $COLUMNS "―")
end

function fish_prompt_format_context --argument-names context
    echo -n -s $fish_prompt_color_border '╼[' $context $fish_prompt_color_border ']'
end

function fish_prompt_make_line --argument-names type
    if test "$type" = first
        echo -n -s $fish_prompt_color_border '┌'
    else if test "$type" = last
        echo -n -s $fish_prompt_color_border '└' (set_color normal; set_color brwhite) (fish_prompt_get_arrow) $fish_prompt_color_normal
    else
        echo -n -s $fish_prompt_color_border '├'
    end
end


function fish_prompt_get_arrow
    echo -n -s (string repeat -n $SHLVL '>') ' '
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
    end

    if test -z "$privilege_context"
        return
    end

    echo -n -s $fish_prompt_color_standout_text $privilege_context
end

function fish_prompt_get_host_context
    if set --query SSH_TTY
        echo -n -s $fish_prompt_color_text "host: $USER on $(hostname) (ssh)"
        return
    end

    set container_name (fish_prompt_get_container_name)
    if test -n "$container_name"
        echo -n -s $fish_prompt_color_text "host: $USER on $container_name (container)"
        return
    end


    if test "$USER" != 'biggs'
        echo -n -s $fish_prompt_color_text "host: $USER on $(hostname)"
        return
    end
end

# Taken from Starship Prompt: https://github.com/starship/starship/blob/master/src/modules/container.rs
function fish_prompt_get_container_name
    if test -e /proc/vz
    and not test -e /proc/bc
        echo 'OpenVZ'
        return
    end

    if test -e /run/host/container-manager
        echo 'OCI'
        return
    end

    if test -e /run/.containerenv
        # TODO: The image name is in this file, I should extract it and return that instead.
        echo 'podman'
        return
    end

    set systemd_container_path '/run/systemd/container'
    if test -e "$systemd_container_path"
        echo (cat "$systemd_container_path")
    end

    if test -e /.dockerenv
        echo 'Docker'
        return
    end
end

function fish_prompt_get_path_context
    set -g fish_prompt_pwd_dir_length 0
    set path (prompt_pwd)

    set dir_length 5
    while test (string length --visible $path) -gt (math $COLUMNS - 10) -a $dir_length -ge 1
        set -g fish_prompt_pwd_dir_length $dir_length
        set path (prompt_pwd)
        set dir_length (math $dir_length - 1)
    end

    echo -n -s $fish_prompt_color_text 'path: ' $path
end

function fish_prompt_get_direnv_context
    if not set --query DIRENV_DIR
        return
    end

    # remove the '-' in the beginning
    set directory (basename (string sub --start 2 -- $DIRENV_DIR))

    set blocked ''
    if direnv status | grep --ignore-case --quiet 'Found RC allowed false'
        set blocked (echo -n -s (set_color red) ' (blocked)')
    end

    echo -n -s $fish_prompt_color_text 'direnv: ' "$directory" "$blocked"
end

function fish_prompt_get_git_context
    set git_context (__fish_prompt_get_git_context)
    if test -z $git_context
        return
    end
    if test "$git_context" = $git_loading_indicator
        echo -n -s $fish_prompt_color_text 'git: ' $git_context
        return
    end

    # remove parentheses and leading space e.g. ' (branch,dirty,untracked)' -> 'branch,dirty,untracked'
    set --local formatted_context (string sub --start=3 --end=-1 $git_context)
    # replace first comma with ' (' e.g. ',branch,dirty,untracked' -> ' (branch dirty,untracked'
    set --local formatted_context (string replace ',' ' (' $formatted_context)
    # only add the closing parenthese if we added the opening one
    and set formatted_context (string join '' $formatted_context ')')

    if test (string length --visible $formatted_context) -gt (math $COLUMNS - 10)
        set formatted_context (fish_prompt_abbreviate_git_states $formatted_context)
    end

    echo -n -s $fish_prompt_color_text 'git: ' $formatted_context
end

function fish_prompt_abbreviate_git_states --argument-names git_context
    set long_states 'ahead:' 'behind:' 'untracked' 'dirty' 'staged' 'invalid'
    set abbreviated_states '↑' '↓' '?' '!' '+' '#'
    for index in (seq (count $long_states))
        set long_state $long_states[$index]
        set abbreviated_state $abbreviated_states[$index]
        set git_context (string replace --regex "(\(.*)$long_state(.*\))" "\${1}$abbreviated_state\${2}" $git_context)
    end

    echo -n $git_context \
        # remove the commas in between states
        | string replace --all --regex '(\(.*),(.*\))' '${1}${2}' \
        # remove the parentheses around the states
        | string replace --all --regex '[\(,\)]'  ''
end

function fish_prompt_get_status_context
    # If there aren't any non-zero exit codes, i.e. failures, then we won't print anything
    if not string match --quiet --invert 0 $argv
        return
    end

    # For git log, git exits with 141 (SIGPIPE) if the pager doesn't consume all the text that git writes
    # to the pipe (i.e. scrolling to the bottom of the pager). I don't consider this an error so I'm ignoring it.
    if string match --quiet --regex -- '^git l(og)?(\s|$)' "$__last_commandline"
        and test "$argv" -eq '141'
        return
    end

    if test (count $argv) -gt 1
        set plural 's'
    else
        set plural ''
    end
    set warning_codes 130

    set red (set_color red)
    set yellow (set_color yellow)
    set normal (set_color normal)

    set pipestatus_formatted
    for code in $argv
        set color (set_color green)
        if contains "$code" $warning_codes
            set color "$yellow"
        else if test "$code" != '0'
            set color "$red"
        end

        set signal (fish_status_to_signal $code)
        if test "$code" != "$signal"
            set --append pipestatus_formatted "$color$code($signal)"
        else
            set --append pipestatus_formatted "$color$code"
        end
    end

    echo -n -s $fish_prompt_color_text 'status: '(string join "$normal, " $pipestatus_formatted)
end

function fish_prompt_get_nix_context
    if not set --query IN_NIX_SHELL
        return
    end

    set color (set_color green)
    if test "$IN_NIX_SHELL" = 'impure'
        set color (set_color yellow)
    end

    echo -n -s $fish_prompt_color_text "nix: $color$IN_NIX_SHELL"
end
