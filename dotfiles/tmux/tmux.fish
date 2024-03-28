if not status is-interactive
    exit
end

abbr --add --global ta tmux-attach-or-reload

function tmux-server-reload --description 'Reload tmux server'
    function is_tmux_running
        tmux list-sessions &>/dev/null
    end

    # Not sure how to restart the tmux server and reconnect to it
    # from a tmux-managed shell.
    if test -n "$TMUX"
        echo -s \
            (set_color red) \
            'ERROR: Unable to reload the tmux server from a tmux-managed shell, please detach from the server and try again.' \
            (set_color normal)
        return 1
    end

    if is_tmux_running
        # detach all clients from all sessions. We suppress stderr because tmux prints out
        # error text if we try to detach all clients on a session that has no clients
        tmux list-sessions -F '#{session_name}' | xargs -I SESSION tmux detach-client -s SESSION 2>/dev/null
        # save server state
        if set --export --query BIGOLU_PORTABLE_HOME_NIX_PROFILE
            set profile "$BIGOLU_PORTABLE_HOME_NIX_PROFILE"
        else
            set profile "$HOME/.nix-profile"
        end
        # I'm suppressing stderr because resurrect will print a bunch of errors regarding pane
        # contents that it can't find
        $profile/share/tmux-plugins/resurrect/scripts/save.sh quiet 2>/dev/null

        # The tmux server is not actually shut down by the time 'kill-server' returns. This causes a problem:
        #
        # When I try to start the server again, tmux sees that the server is already running and connects me to the
        # server that is in the process of being shut down. Then I get disconnected and see an error message saying
        # 'server exited unexpectedly'.
        #
        # To confirm the server is actually down after 'kill-server' returns, I poll the server until I don't get
        # a response.
        tmux kill-server
        set max_poll_attempts 5
        while is_tmux_running
            and test $max_poll_attempts -gt 0
            sleep 1
            set max_poll_attempts (math $max_poll_attempts - 1)
        end
    end

    tmux attach-session
end

function tmux-attach-or-reload
    # Since the portable home deletes its prefix when it exits the $PATH and $SHELL environment
    # variables in TMUX will become invalid so we have to reload the server.
    if set --export --query BIGOLU_IN_PORTABLE_HOME
        echo (set_color yellow)'WARNING:'(set_color normal)' Reattaching to TMUX through a portable shell will not work properly. Reloading the server instead...' >&2
        tmux-server-reload
        return
    end

    tmux attach-session
end

function __fish_prompt_post --on-event fish_prompt
    # I only want this to run once so delete the function.
    functions -e (status current-function)
    functions --copy fish_prompt __tmux_integration_old_fish_prompt
    function fish_prompt
        set prompt "$(__tmux_integration_old_fish_prompt)"

        # If the original prompt function didn't print anything we shouldn't either since not
        # printing anything will cause the shell to redraw the prompt in place, but if we add the
        # spaces the prompt won't redraw in place.
        if test "$(string length --visible -- "$prompt")" = 0
            return
        end

        # TODO: See if I could use an empty hyperlink as the marker since that won't take up visible
        # space.
        echo \u00A0"$prompt"\u00A0
    end
end
mybind --no-focus \co 'tmux-last-command-output; commandline -f repaint'
