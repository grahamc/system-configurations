if not status is-interactive
    exit
end

function ping --wraps gping
    if type --query gping
        gping $argv
    else
        command ping $argv
    end
end

