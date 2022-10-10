if not status is-interactive
    exit
end

function ls --wraps lsd
    if type --query lsd
        lsd $argv
    else
        command ls $argv
    end
end

