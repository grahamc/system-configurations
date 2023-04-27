# NOTE: Unlike most of my other fish configs, this one does not check if the shell is being run
# interactively. This is because some of the functions defined here will be called in a non-interactive shell by my
# async prompt plugin.

# The reason for all the 'set_color normal' commands is to undo any attributes set like '--bold'
set _color_text (set_color normal; set_color cyan)
set _color_standout_text (set_color normal; set_color yellow)
set _color_error_text (set_color normal; set_color red)
set _color_normal (set_color normal)
set _color_border (set_color normal; set_color brwhite)

set async_prompt_functions test

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

        echo -n -s -e (_get_separator) "\n" $_color_text (_get_arrow) $_color_normal
        return
    else if set --query TRANSIENT_EMPTY
        set --erase TRANSIENT_EMPTY

        # Return without printing anything. This results in the prompt being refreshed in-place since it erases the
        # old prompt, prints nothing, and then draws the prompt again.
        return
    end

    set -l lines
    set -l contexts \
        (_get_direnv_context) \
        (_get_nix_context) \
        (_get_python_context) \
        (_get_git_context) \
        (_get_job_context) \
        (_get_host_context) \
        (_get_path_context) \
        (_get_status_context $last_pipestatus) \
        (_get_privilege_context)
    for context in $contexts
        if test -z $context
            continue
        end

        set max_width (math $COLUMNS - 4)
        if test "$(string length --visible "$context")" -gt "$max_width"
            set context (string shorten --max "$max_width" "$context")
        end

        if not set --query lines[1]
            set --local first_line (string join '' (_make_line first) (_format_context $context))
            set --append lines $first_line
            continue
        end

        set --local formatted_context (_format_context $context)
        set --local middle_line (string join '' (_make_line) $formatted_context)
        set --append lines $middle_line
    end
    set --append lines (_make_line last)
    # Add another line to separate commands
    set --prepend lines (_get_separator)
    echo -e -n (string join '\n' $lines)
end

function fish_right_prompt
  # # transient prompt
  # if set --query TRANSIENT_RIGHT
  #     set --erase TRANSIENT_RIGHT
  #     echo -n ' '
  #     return
  # else if set --query TRANSIENT_EMPTY_RIGHT
  #     set --erase TRANSIENT_EMPTY_RIGHT
  #     echo -n ' '
  #     return
  # end

  # # echo -s (set_color brwhite) '(ctrl+/: help)' (set_color normal)
  # echo -s (set_color brwhite) '' (set_color normal)
end

function _get_separator
    echo -n -s ' '
    # echo -n -s (set_color brblack) (string repeat -n $COLUMNS "―")
end

function _format_context --argument-names context
    echo -n -s $_color_border '╼[' $context $_color_border ']'
end

function _make_line --argument-names type
    if test "$type" = first
        echo -n -s $_color_border '┌'
    else if test "$type" = last
        echo -n -s $_color_border '└' (set_color normal; set_color brwhite) (_get_arrow) $_color_normal
    else
        echo -n -s $_color_border '├'
    end
end


function _get_arrow
    echo -n -s (string repeat -n $SHLVL '>') ' '
end

function _get_python_context
    if not set --query VIRTUAL_ENV
        return
    end

    echo -n -s $_color_text 'venv: ' (_get_python_venv_name)
end

function _get_python_venv_name
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

function _get_job_context
    if not jobs --query
        return
    end

    set --local job_commands (jobs --command)
    set --local formatted_job_commands (string split ' ' $job_commands | string join ,)
    echo -n -s $_color_text 'jobs: ' $formatted_job_commands
end

function _get_privilege_context
    set privilege_context
    if test (id --user) -eq 0
        set privilege_context 'user has admin privileges'
    end

    if test -z "$privilege_context"
        return
    end

    echo -n -s $_color_standout_text $privilege_context
end

function _get_host_context
    if set --query SSH_TTY
        echo -n -s $_color_text "host: $USER on $(hostname) (ssh)"
        return
    end

    set container_name (_get_container_name)
    if test -n "$container_name"
        echo -n -s $_color_text "host: $USER on $container_name (container)"
        return
    end


    if test "$USER" != 'biggs'
        echo -n -s $_color_text "host: $USER on $(hostname)"
        return
    end
end

# Taken from Starship Prompt: https://github.com/starship/starship/blob/master/src/modules/container.rs
function _get_container_name
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

function _get_path_context
    set -g _pwd_dir_length 0
    set path (prompt_pwd)

    set dir_length 5
    # 4 border chars + 'path: ' = 10
    set max_width (math $COLUMNS - 10)
    while test (string length --visible $path) -gt $max_width -a $dir_length -ge 1
        set -g _pwd_dir_length $dir_length
        set path (prompt_pwd)
        set dir_length (math $dir_length - 1)
    end

    echo -n -s $_color_text 'path: ' $path
end

function _get_direnv_context
    if not set --query DIRENV_DIR
        return
    end

    # remove the '-' in the beginning
    set directory (basename (string sub --start 2 -- $DIRENV_DIR))

    set blocked ''
    if direnv status | grep --ignore-case --quiet 'Found RC allowed false'
        set blocked (echo -n -s (set_color red) ' (blocked)')
    end

    echo -n -s $_color_text 'direnv: ' "$directory" "$blocked"
end

function _get_git_context
    set git_context (_get_git_context_async)
    if test -z $git_context
        return
    end
    if test "$git_context" = (_get_git_context_async_loading_indicator)
        echo -n -s $_color_text 'git: ' $git_context
        return
    end

    # remove parentheses and leading space e.g. ' (branch,dirty,untracked)' -> 'branch,dirty,untracked'
    set --local formatted_context (string sub --start=3 --end=-1 $git_context)
    # replace first comma with ' (' e.g. ',branch,dirty,untracked' -> ' (branch dirty,untracked'
    set --local formatted_context (string replace ',' ' (' $formatted_context)
    # only add the closing parenthese if we added the opening one
    and set formatted_context (string join '' $formatted_context ')')

    if test (string length --visible $formatted_context) -gt (math $COLUMNS - 10)
        set formatted_context (_abbreviate_git_states $formatted_context)
    end

    echo -n -s $_color_text 'git: ' $formatted_context
end

set --append async_prompt_functions _get_git_context_async
function _get_git_context_async_loading_indicator
    echo -n -s (set_color --dim --italics) 'loading…'
end
function _get_git_context_async
    set --global __fish_git_prompt_showupstream 'informative'
    set --global __fish_git_prompt_showdirtystate 1
    set --global __fish_git_prompt_showuntrackedfiles 1
    set --global __fish_git_prompt_char_upstream_ahead ',ahead:'
    set --global __fish_git_prompt_char_upstream_behind ',behind:'
    set --global __fish_git_prompt_char_untrackedfiles ',untracked'
    set --global __fish_git_prompt_char_dirtystate ',dirty'
    set --global __fish_git_prompt_char_stagedstate ',staged'
    set --global __fish_git_prompt_char_invalidstate ',invalid'
    set --global __fish_git_prompt_char_stateseparator ''
    fish_git_prompt
end

function _abbreviate_git_states --argument-names git_context
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

function _get_status_context
    # If there aren't any non-zero exit codes, i.e. failures, then we won't print anything
    if not string match --quiet --invert 0 $argv
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

    echo -n -s $_color_text 'status: '(string join "$normal, " $pipestatus_formatted)
end

function _get_nix_context
    if not set --query IN_NIX_SHELL
        return
    end

    set color (set_color green)
    if test "$IN_NIX_SHELL" = 'impure'
        set color (set_color yellow)
    end

    set packages (string split --no-empty ' ' "$ANY_NIX_SHELL_PKGS" | xargs -I PACKAGE fish -c 'string split --fields (count (string split \'.\' \'PACKAGE\')) \'.\' \'PACKAGE\'')
    if test -n "$packages"
        set packages " ($packages)"
    end

    echo -n -s $_color_text "nix: $color$IN_NIX_SHELL$_color_text$packages"
end

