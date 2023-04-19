function is_tmux_running
    tmux list-sessions &>/dev/null
end

function reload-tmux-server --description 'Reload tmux server'
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
        ~/.nix-profile/share/tmux-plugins/resurrect/scripts/save.sh quiet

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
