function reload-tmux-server --description 'Reload tmux server'
    # Not sure how to restart the tmux server and reconnect to it
    # from within a tmux session
    if test -n "$TMUX"
        echo -s \
            (set_color red) \
            'ERROR: Unable to reload the tmux server from within a tmux session, please dettach from the session and try again.' \
            (set_color normal)
        return 1
    end

    if tmux list-sessions &>/dev/null # tmux is running
        # detach all clients from all sessions. We suppress stderr because tmux prints out
        # error text if we try to detach all clients on a session that has no clients
        tmux list-sessions -F '#{session_name}' | xargs -I SESSION tmux detach-client -s SESSION 2>/dev/null
        # save server state
        ~/.tmux/plugins/tmux-resurrect/scripts/save.sh

        tmux kill-server
    end

    tmux
end
