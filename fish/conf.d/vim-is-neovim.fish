if not status is-interactive
    exit
end

function vim --wraps nvim
    if type --query nvim
        nvim $argv
    else
        vim $argv
    end
end

