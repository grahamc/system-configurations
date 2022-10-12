if not status is-interactive
    exit
end

function du --wraps duf
    if type --query duf
        duf --theme ansi $argv
    else
        command du $argv
    end
end

