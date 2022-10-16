if not status is-interactive
    exit
end

function df --wraps duf
    if type --query duf
        env NO_COLOR=1 duf $argv

    else
        command df $argv
    end
end

