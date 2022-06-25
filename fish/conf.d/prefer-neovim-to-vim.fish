if not status is-interactive
    exit
end

function vim --wraps nvim
    if type --query nvim
        nvim $argv
    else
        command vim $argv
    end
end

