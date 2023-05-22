# TODO: Workaround for fish bug
# issue: https://github.com/fish-shell/fish-shell/issues/6942
#
# The '00' in the beginning of the file name is to ensure that this script is run before any others
# in conf.d, since some of them use this function.

if not status is-interactive
    exit
end

function bind-no-focus
    bind $argv[1 .. -2] 'type --query __fish_disable_focus && __fish_disable_focus' $argv[-1]
end

