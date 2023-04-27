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

function dig --wraps doggo
    if type --query doggo
        doggo --color=false $argv
    else
        command dig $argv
    end
end

function df --wraps duf
    if type --query duf
        env NO_COLOR=1 duf $argv

    else
        command df $argv
    end
end

function ping --wraps gping
    if type --query gping
        gping $argv
    else
        command ping $argv
    end
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
    if type --query lsd
        lsd $argv
    else
        command ls $argv
    end
end

function vim --wraps nvim
    if type --query nvim
        nvim $argv
    else
        command vim $argv
    end
end

# Wrapping watch since viddy doesn't have autocomplete
function watch --wraps watch
    if type --query viddy
        viddy --pty $argv
    else
        command watch $argv
    end
end

function sh --wraps yash
    if type --query yash
        yash $argv
    else
        command sh $argv
    end
end

