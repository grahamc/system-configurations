if not status is-interactive
    exit
end

function _is_tmux_running
    command tmux list-sessions &>/dev/null
end

function __fish_prompt_post --on-event fish_prompt
    # I only want this to run once so delete the function.
    functions -e (status current-function)
    functions --copy fish_prompt __tmux_integration_old_fish_prompt
    function fish_prompt
        set prompt "$(__tmux_integration_old_fish_prompt)"

        # If the original prompt function didn't print anything we shouldn't
        # either since not printing anything will cause the shell to redraw the
        # prompt in place, but if we add the spaces the prompt won't redraw in
        # place.
        if test "$(string length --visible -- "$prompt")" = 0
            return
        end

        # TODO: tmux supports OSC 133 so I should open an issue for adding
        # something to the tmux CLI for getting the last command output, maybe
        # by adding a flag to `capture-pane`.
        echo \u00A0"$prompt"\u00A0
    end
end

function _bigolu_tmux_command_output_widget
    tmux-last-command-output
    commandline -f repaint
end
mybind --no-focus \co _bigolu_tmux_command_output_widget

# TODO: This is a workaround for an issue caused by launching tmux from inside a
# direnv environment [1].  If I try to launch tmux from a direnv environment, I
# instead print a warning telling me to leave the environment and try again.
#
# [1] https://github.com/direnv/direnv/issues/106
function tmux
    function _is_launching_tmux
        not _is_tmux_running && begin
            test (count $argv) -eq 0 || contains -- new-session $argv
        end
    end

    function _in_direnv_environment
        set --query DIRENV_DIR
    end

    if _is_launching_tmux && _in_direnv_environment
        # If this is true I assume I'm trying to launch tmux
        echo -s (set_color yellow) 'WARNING:' (set_color normal) ' Launching tmux from a direnv environment can cause issues. Try again from outside a direnv environment.' \n 'Issue: https://github.com/direnv/direnv/issues/106' >&2
        return
    end

    command tmux $argv
end

function tmux-attach-to-project --argument-names session_name
    if test -z "$session_name"
        # Some characters can't be used in a session name so I'll substitute
        # them the same way tmux would if I were to pass the original name to
        # `tmux new-session -s <original_name>`.
        #
        # Setting `--dir-length` to 0 disables path segment shortening.
        set session_name (prompt_pwd --dir-length 0 | string replace --all '.' '_')
    end

    if not tmux attach-session -t "$session_name"
        tmux new-session -s "$session_name"
    end
end
