if not status is-interactive
    exit
end

function python --wraps python
    if type --query ipython
        if test (count $argv) -eq 0
        or contains -- '-i' $argv
            ipython $argv
            return
        end
    end
    command python $argv
end

