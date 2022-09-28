if not status is-interactive
    exit
end

function sh --wraps yash
    if type --query yash
        yash $argv
    else
        command sh $argv
    end
end

