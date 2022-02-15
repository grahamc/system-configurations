function tmux-attach-or-create --description 'Reattach to TMUX'
    begin
        # try connecting to the session named main
        if tmux has-session -t main
            tmux attach-session -t main
            return
        end
        # try connecting to any session
        if tmux attach-session
            return
        end
        # start a new session
        tmux
    end &>/dev/null
end
