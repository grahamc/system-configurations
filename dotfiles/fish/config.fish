# Actions that should be run at the end of startup

if not status is-interactive
    exit
end

if test -z "$TMUX"
    # HACK: vscode doesn't set VSCODE_INJECTION when launching a terminal when debugging so instead
    # I'm looking for any variable that starts with VSCODE. Should probably report this.
    if env | grep -q -E '^VSCODE'
        tmux-attach-to-project
    else
        if test -n "$TMUX_CONNECT_WAS_RUN"
            return
        end
        set --global --export TMUX_CONNECT_WAS_RUN 1
        tmux-attach-to-project main
    end
end
