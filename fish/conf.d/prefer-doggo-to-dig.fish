if not status is-interactive
    exit
end

function dig --wraps doggo
    if type --query doggo
        doggo --color=false $argv
    else
        command dig $argv
    end
end

