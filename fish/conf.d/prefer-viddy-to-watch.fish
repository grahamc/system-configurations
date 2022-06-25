if not status is-interactive
    exit
end

# Wrapping watch since viddy doesn't have autocomplete
function watch --wraps watch
    if type --query viddy
        viddy $argv
    else
        command watch $argv
    end
end

