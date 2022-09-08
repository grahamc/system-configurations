if not status is-interactive
    exit
end

function ssh --wraps ssh
    if type --query autossh
        # For why ExitOnForwardFailure is necessary see here:
        # https://www.everythingcli.org/ssh-tunnelling-for-fun-and-profit-autossh/#comment-494
        #
        # The arguments before it are so that autossh restarts the ssh connection after about 90 seconds of
        # not receiving a response from the server.
        autossh -M 0 -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -o 'ExitOnForwardFailure=yes' $argv
    else
        command ssh $argv
    end
end
