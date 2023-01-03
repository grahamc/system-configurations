if not status is-interactive
    exit
end

function python --wraps python
    if type --query ipython
    # Make sure ipython belongs to the current python installation.
    #
    # If I pipe the output of python to grep, python will raise a BrokenPipeError. To avoid this, I use echo to pipe
    # the output.
    and echo (command python -m pip list) | grep -q ipython
        if test (count $argv) -eq 0
        or contains -- '-i' $argv
            ipython $argv
            return
        end
    end
    command python $argv
end

