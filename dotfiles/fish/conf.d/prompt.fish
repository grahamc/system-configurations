# NOTE: Unlike most of my other fish configs, this one does not check if the shell is being run
# interactively. This is because some of the functions defined here will be called in a non-interactive shell by
# fish-async-prompt.

set _color_warning_text (set_color yellow)
set _color_error_text (set_color red)
set _color_success_text (set_color green)
set _color_normal (set_color normal)
set _color_border (set_color brwhite)

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
        echo -n -e $separator\n$_color_border(_arrows)$_color_normal
        return
    else if set --query TRANSIENT_EMPTY
        set --erase TRANSIENT_EMPTY
        # Return without printing anything. This results in the prompt being refreshed in-place since it erases the
        # old prompt, prints nothing, and then draws the prompt again.
        return
    end

    # The max number of screen columns a context can use and still fit on one line. The 4 accounts for the 4
    # characters that make up the border, see `_make_line`.
    set max_length (math $COLUMNS - 4)
    set contexts \
        (_broot_context) \
        (_direnv_context) \
        (_nix_context) \
        (_python_context) \
        (_job_context) \
        (_git_context $max_length) \
        (_path_context $max_length) \
        (_login_context) \
        (_status_context $last_status $last_pipestatus) \
        ;
    set prompt_lines
    for context in $contexts
        if test -z $context
            continue
        end

        # Truncate any contexts that wouldn't fit on one line.
        if test (string length --visible $context) -gt $max_length
        # TODO: `string length --visible` doesn't report the correct size for OSC8 hyperlinks so I'm skipping
        # truncation for any context that contains it.
        and not string match --quiet '*\e]8;;*' $context
            set context (string shorten --max $max_length $context)
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
        set arrows (set_color cyan)(_arrows)$_color_normal
        echo $line_connector$arrows
    end
end

function _arrows
    echo (string repeat -n $SHLVL '>')' '
end

function _python_context
    if not set --query VIRTUAL_ENV
        return
    end

    echo "venv: $(_python_venv_name)"
end
function _python_venv_name
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

function _job_context
    if not jobs --query
        return
    end

    set job_commands (jobs --command)
    set formatted_job_commands (string join , $job_commands)
    echo "jobs: $formatted_job_commands"
end

function _login_context
    set container_name (_container_name)
    if test -n "$container_name"
        set host $container_name
        set special_host 'container'
    else if set --query SSH_TTY
        set host (hostname)
        set special_host 'ssh'
    else
        set host (hostname)
    end

    if fish_is_root_user
        set privilege $_color_warning_text'superuser'$_color_normal
    end

    if set --query special_host
    or set --query privilege
    or test "$USER" != 'biggs'
        set user $USER
        if set --query privilege
            set user "$user ($privilege)"
        end

        if set --query special_host
            set host "$host ($special_host)"
        end

        echo "login: $user on $host"
    end
end
# Taken from Starship Prompt: https://github.com/starship/starship/blob/master/src/modules/container.rs
function _container_name
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

function _path_context --argument-names max_length
    set context_prefix 'path: '

    # Passing 0 means prompt won't be shortened
    set path (prompt_pwd --dir-length 0)
    set max_path_length (math $max_length - (string length $context_prefix))
    set dir_length 5
    while test (string length --visible $path) -gt $max_path_length -a $dir_length -ge 1
        # Each segment of the path will be truncated to a length of `$dir_length`.
        set path (prompt_pwd --dir-length $dir_length)
        set dir_length (math $dir_length - 1)
    end

    # TODO: `string length --visible` doesn't report the correct size for OSC8 hyperlinks so I'm doing the truncation
    # before making the hyperlink.
    if test (string length --visible $path) -gt $max_path_length
        set path (string shorten --max $max_path_length $path)
    end

    set hyperlink '\e]8;;file://'(pwd)'\e\\'$path'\e]8;;\e\\'

    echo $context_prefix$hyperlink
end

function _direnv_context
    if not set --query DIRENV_DIR
        return
    end

    # remove the '-' in the beginning
    set directory (basename (string sub --start 2 -- $DIRENV_DIR))

    set blocked ''
    if direnv status | grep --ignore-case --quiet 'Found RC allowed false'
        set blocked ' ('$_color_error_text'blocked'$_color_normal')'
    end

    echo "direnv: $directory$blocked"
end

function _git_context --argument-names max_length
    set context_prefix 'git: '

    set git_status (_git_status)
    if test -z "$git_status"
        return
    end
    if test $git_status = (_git_status_loading_indicator)
        echo $context_prefix$git_status
        return
    end

    # remove parentheses and leading space e.g. ' (<branch>,dirty,untracked)' -> '<branch>,dirty,untracked'
    set --local formatted_status (string sub --start=3 --end=-1 $git_status)
    # replace first comma with ' (' e.g. ',<branch>,dirty,untracked' -> ' (<branch> dirty,untracked'
    set --local formatted_status (string replace ',' ' (' $formatted_status)
    # only add the closing parenthese if we added the opening one
    and set formatted_status (string join '' $formatted_status ')')

    set max_status_length (math $max_length - (string length $context_prefix))
    if test (string length --visible $formatted_status) -gt $max_status_length
        set formatted_status (_abbreviate_git_states $formatted_status)
    end

    set branch_name (git branch --show-current)
    # NOTE: I should also check that this branch exists on the remote, but that check takes ~500ms whereas the
    # rest of my prompt take ~100ms to load so I don't think it's worth the wait.
    if test -n "$branch_name"
        set git_branch_hyperlink (_make_hyperlink_to_git_branch "$branch_name")

        set branch_name_length (math (string length "$branch_name") + 1)
        set formatted_status_without_git_branch (string sub --start "$branch_name_length" "$formatted_status")

        set formatted_status "$git_branch_hyperlink$formatted_status_without_git_branch"
    end

    echo "git: $formatted_status"
end
function _make_hyperlink_to_git_branch --argument-names branch_name
    set hyperlink
    set remote_url (git remote get-url origin)
    set hosts 'github.com'
    set patterns '^(https://|git@)github\.com[:/](?<owner>.*)/(?<repo>.*)\.git$'
    set replacements 'https://github.com/$owner/$repo/tree/%s'
    for index in (seq (count $hosts))
        set host $hosts[$index]
        set pattern $patterns[$index]
        set replacement $replacements[$index]
        if string match --entire --quiet "$host" "$remote_url"
            set hyperlink (printf (string replace --regex -- "$pattern" "$replacement" "$remote_url") "$branch_name")
            break
        end
    end

    if test -n "$hyperlink"
        echo '\e]8;;'$hyperlink'\e\\'$branch_name'\e]8;;\e\\'
    else
        echo $branch_name
    end
end
function _git_status
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
function _git_status_loading_indicator
    echo (set_color --dim --italics)'loading…'$_color_normal
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
_add_async_prompt_function _git_status _git_status_loading_indicator

function _status_context
    # I'd pass these in as two separate arguments, but fish doesn't support list arguments.
    # issue: https://github.com/fish-shell/fish-shell/issues/3375
    set last_status $argv[1]
    set last_pipestatus $argv[2..]

    # If there aren't any non-zero exit codes in the last $pipestatus and the last $status is 0, then that means
    # everything succeeded and I won't print anything
    if not string match --quiet --invert 0 $last_pipestatus
    and test $last_status -eq 0
        return
    end

    set formatted_exit_code (format_exit_code $last_status)

    set context "status: $formatted_exit_code"

    if test (count $last_pipestatus) -gt 1
        set pipestatus_formatted
        for code in $last_pipestatus
            set --append pipestatus_formatted (format_exit_code $code)
        end
        set pipestatus_formatted (string join ', ' $pipestatus_formatted)

        set context "$context (pipe: $pipestatus_formatted)"
    end

    echo $context
end
function format_exit_code --argument-names exit_code
    set color (color_for_exit_code $exit_code)
    set formatted_exit_code $color$exit_code$_color_normal

    set signal (fish_status_to_signal $exit_code)
    if test $exit_code != $signal
        set formatted_signal $color/$signal$_color_normal
        set formatted_exit_code $formatted_exit_code$formatted_signal
    end

    echo $formatted_exit_code
end
function color_for_exit_code --argument-names exit_code
    set warning_codes 130
    set color $_color_success_text
    if contains $exit_code $warning_codes
        set color $_color_warning_text
    else if test $exit_code != '0'
        set color $_color_error_text
    end

    echo $color
end

function _nix_context
    if not set --query IN_NIX_SHELL
    and not set --query IN_NIX_RUN
        return
    end

    set packages ( \
        # Each package is separated by a space.
        string split --no-empty ' ' "$ANY_NIX_SHELL_PKGS" \
        # Packages may have dots, e.g. 'vimPlugins.vim-abolish', in which case I take the segment after the last
        # dot, 'vim-abolish'.
        | xargs -I PACKAGE fish -c "string split --fields (count (string split '.' 'PACKAGE')) '.' 'PACKAGE'" \
    )
    if test -n "$packages"
        set packages " ($packages)"
    end

    if set --query IN_NIX_SHELL
        set color $_color_success_text
        if test $IN_NIX_SHELL = 'impure'
            set color $_color_warning_text
        end
        set type $color$IN_NIX_SHELL$_color_normal
    else
        set type $_color_warning_text'unknown'$_color_normal
    end

    echo "nix: $type$packages"
end

function _broot_context
    if not set --query IN_BROOT
        return
    end

    echo "broot: active"
end
