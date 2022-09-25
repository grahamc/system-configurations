if not status is-interactive
    exit
end

function sshfs --wraps sshfs
    set default_options 'reconnect,compression=yes,transform_symlinks'
    if type --query autossh
        set default_options "$default_options,ssh_command='autossh -M 0 -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes"
    end

    command sshfs -o $default_options $argv
end
