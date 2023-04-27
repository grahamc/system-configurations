if not status is-interactive
    exit
end

function ssh --wraps ssh
    # For why ExitOnForwardFailure is necessary see here:
    # https://www.everythingcli.org/ssh-tunnelling-for-fun-and-profit-autossh/#comment-494
    #
    # The arguments before it are so that autossh restarts the ssh connection after about 90 seconds of
    # not receiving a response from the server.
    autossh -M 0 -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -o 'ExitOnForwardFailure=yes' $argv
end

function dig --wraps doggo
    doggo --color=false $argv
end

function df --wraps duf
    env NO_COLOR=1 duf $argv
end

function ping --wraps gping
    gping $argv
end

function python --wraps python
    if type --query ipython
    # Make sure ipython belongs to the current python installation.
    #
    # If I pipe the output of python to grep, python will raise a BrokenPipeError. To avoid this, I use echo to pipe
    # the output.
    and echo (command python -m pip list) | grep -q ipython
        if test (count $argv) -eq 0
        or contains -- '-i' $argv
            ipython $argv
            return
        end
    end
    command python $argv
end

function ls --wraps lsd
    lsd $argv
end

function vim --wraps nvim
    nvim $argv
end

# Wrapping watch since viddy doesn't have autocomplete
function watch --wraps watch
    viddy --pty $argv
end

function sh --wraps yash
    yash $argv
end

alias wezterm 'flatpak run org.wezfurlong.wezterm'
