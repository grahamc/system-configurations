if not status is-interactive
    exit
end

function python --wraps python
    if type --query ipython
    # Make sure ipython actually belongs to the current python installation
    and command python -c 'from importlib import util; import sys; sys.exit(0 if util.find_spec("ipython") else 1)'
        if test (count $argv) -eq 0
        or contains -- '-i' $argv
            ipython $argv
            return
        end
    end
    command python $argv
end

