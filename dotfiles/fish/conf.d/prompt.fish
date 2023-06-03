# NOTE: Unlike most of my other fish configs, this one does not check if the shell is being run
# interactively. This is because some of the functions defined here will be called in a non-interactive shell by
# fish-async-prompt.

set _color_text (set_color cyan)
set _color_standout_text (set_color yellow)
set _color_error_text (set_color red)
set _color_normal (set_color normal)
set _color_border (set_color brwhite)

# Names of of functions for fish-async-prompt to wrap
set async_prompt_functions

function fish_prompt --description 'Print the prompt'
    # I want the value of $status and $pipestatus for the last command executed on the command line so I will store
    # their values now before executing any commands.
    set last_status $status
    set last_pipestatus $pipestatus

    # TODO: This clears the text in the terminal after the cursor. If we don't do this, multiline
    # prompts might not display properly.
    # issue: https://github.com/fish-shell/fish-shell/issues/8418
    printf \e\[0J

    # This is what I want to display on the line that separates my prompt from the output of the last command.
    set separator ''

    # transient prompt
    if set --query TRANSIENT
        set --erase TRANSIENT
        echo -n -e $separator\n(_get_arrow)
        return
    else if set --query TRANSIENT_EMPTY
        set --erase TRANSIENT_EMPTY
        # Return without printing anything. This results in the prompt being refreshed in-place since it erases the
        # old prompt, prints nothing, and then draws the prompt again.
        return
    end

    set contexts \
        (_get_direnv_context) \
        (_get_nix_context) \
        (_get_python_context) \
        (_get_git_context) \
        (_get_job_context) \
        (_get_host_context) \
        (_get_path_context) \
        (_get_status_context $last_status $last_pipestatus) \
        (_get_privilege_context)
    set prompt_lines
    for context in $contexts
        if test -z $context
            continue
        end

        # Truncate any contexts that wouldn't fit on one line.
        # The 4 accounts for the 4 characters that make up the border, see `_make_line`.
        set max_width (math $COLUMNS - 4)
        if test (string length --visible $context) -gt $max_width
            set context (string shorten --max $max_width $context)
        end

        if not set --query prompt_lines[1]
            set --append prompt_lines (_make_line first $context)
        else
            set --append prompt_lines (_make_line middle $context)
        end
    end
    set --append prompt_lines (_make_line last)
    set --prepend prompt_lines $separator
    echo -e -n (string join '\n' $prompt_lines)
end
function _make_line --argument-names position context
    set left_border $_color_border'╼['$_color_normal
    set right_border $_color_border']'$_color_normal

    if test $position = first
        set line_connector $_color_border'┌'$_color_normal
        echo $line_connector$left_border$context$right_border
    else if test $position = middle
        set line_connector $_color_border'├'$_color_normal
        echo $line_connector$left_border$context$right_border
    else if test $position = last
        set line_connector $_color_border'└'$_color_normal
        echo $line_connector(_get_arrow)
    end
end
function _get_arrow
    echo $_color_text(string repeat -n $SHLVL '>')$_color_normal' '
end

function _get_python_context
    if not set --query VIRTUAL_ENV
        return
    end

    echo "venv: $(_get_python_venv_name)"
end

function _get_python_venv_name
    set -l path_segments (string split -- / $VIRTUAL_ENV)
    set -l last_path_segment $path_segments[-1]

    # If the folder containing the virtualenv is named .venv, use the parent folder instead
    # since that should be more descriptive
    if test $last_path_segment = '.venv'
        echo $path_segments[-2]
        return
    end

    echo $last_path_segment
end

function _get_job_context
    if not jobs --query
        return
    end

    set job_commands (jobs --command)
    set formatted_job_commands (string join , $job_commands)
    echo "jobs: $formatted_job_commands"
end

function _get_privilege_context
    set privilege_context
    if test (id --user) -eq 0
        set privilege_context 'user has admin privileges'
    end

    if test -z "$privilege_context"
        return
    end

    echo $_color_standout_text$privilege_context$_color_normal
end

function _get_host_context
    set container_name (_get_container_name)
    if test -n "$container_name"
        set host "$container_name (container)"
    else if set --query SSH_TTY
        set host "$(hostname) (ssh)"
    else if test "$USER" != 'biggs'
        set host (hostname)
    end

    if test -n "$host"
        echo "host: $USER on $host"
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
    # Passing 0 means prompt won't be shortened
    set path (prompt_pwd --dir-length 0)

    set dir_length 5
    # 4 border chars (see `_make_line`) + 'path: ' = 10
    set max_width (math $COLUMNS - 10)
    while test (string length --visible $path) -gt $max_width -a $dir_length -ge 1
        # Each segment of the path will be truncated to a length of `$dir_length`.
        set path (prompt_pwd --dir-length $dir_length)
        set dir_length (math $dir_length - 1)
    end

    echo "path: $path"
end

function _get_direnv_context
    if not set --query DIRENV_DIR
        return
    end

    # remove the '-' in the beginning
    set directory (basename (string sub --start 2 -- $DIRENV_DIR))

    set blocked ''
    if direnv status | grep --ignore-case --quiet 'Found RC allowed false'
        set blocked (set_color red)' (blocked)'$_color_normal
    end

    echo "direnv: $directory$blocked"
end

function _get_git_context
    set git_context (_get_git_context_async)
    if test -z "$git_context"
        return
    end
    if test $git_context = (_get_git_context_async_loading_indicator)
        echo "git: $git_context"
        return
    end

    # remove parentheses and leading space e.g. ' (branch,dirty,untracked)' -> 'branch,dirty,untracked'
    set --local formatted_context (string sub --start=3 --end=-1 $git_context)
    # replace first comma with ' (' e.g. ',branch,dirty,untracked' -> ' (branch dirty,untracked'
    set --local formatted_context (string replace ',' ' (' $formatted_context)
    # only add the closing parenthese if we added the opening one
    and set formatted_context (string join '' $formatted_context ')')

    # 4 border chars (see `_make_line`) + 'git: ' = 9
    if test (string length --visible $formatted_context) -gt (math $COLUMNS - 9)
        set formatted_context (_abbreviate_git_states $formatted_context)
    end

    echo "git: $formatted_context"
end
set --append async_prompt_functions _get_git_context_async
function _get_git_context_async_loading_indicator
    echo (set_color --dim --italics)'loading…'$_color_normal
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
    # I'd pass these in as two separate arguments, but fish doesn't support list arguments, all the arguments
    # get flattened: https://github.com/fish-shell/fish-shell/issues/3375
    set last_status $argv[1]
    set last_pipestatus $argv[2..]

    # If there aren't any non-zero exit codes in the last $pipestatus and the last $status is 0, then that means
    # everything succeeded and I won't print anything
    if not string match --quiet --invert 0 $last_pipestatus
    and test $last_status -eq 0
        return
    end

    set status_color (get_color_for_exit_code $last_status)
    set status_formatted $status_color$last_status$_color_normal

    set context "status: $status_formatted"

    if test (count $last_pipestatus) -gt 1
        set pipestatus_formatted
        for code in $last_pipestatus
            set color (get_color_for_exit_code $code)
            set signal (fish_status_to_signal $code)
            if test $code != $signal
                set --append pipestatus_formatted $color"$code($signal)"$_color_normal
            else
                set --append pipestatus_formatted $color$code$_color_normal
            end
        end
        set pipestatus_formatted (string join ', ' $pipestatus_formatted)

        set context "$context (pipe: $pipestatus_formatted)"
    end

    echo $context
end
function get_color_for_exit_code --argument-names exit_code
    set warning_codes 130
    set color (set_color green)
    if contains $exit_code $warning_codes
        set color (set_color yellow)
    else if test $exit_code != '0'
        set color (set_color red)
    end

    echo $color
end

function _get_nix_context
    if not set --query IN_NIX_SHELL
        return
    end

    set packages ( \
        # Each package is separated by a space.
        string split --no-empty ' ' "$ANY_NIX_SHELL_PKGS" \
        # Packages may be have dots, e.g. 'vimPlugins.vim-abolish', in which case I take the segment after the last
        # dot, 'vim-abolish'.
        | xargs -I PACKAGE fish -c "string split --fields (count (string split '.' 'PACKAGE')) '.' 'PACKAGE'" \
    )
    if test -n "$packages"
        set packages " ($packages)"
    end

    set color (set_color green)
    if test $IN_NIX_SHELL = 'impure'
        set color (set_color yellow)
    end
    set purity $color$IN_NIX_SHELL$_color_normal

    echo "nix: $purity$packages"
end

