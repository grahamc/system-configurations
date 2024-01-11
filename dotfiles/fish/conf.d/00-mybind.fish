# I made my own bind function to centralize all my calls to bind. This way if I want to change the mode for all my
# binds I only have to do it in one place.
#
# The '00' in the beginning of the file name is to ensure that this script is run before any others
# in conf.d, since some of them use this function.

if not status is-interactive
    exit
end

function mybind
    # TODO: Workaround for fish bug
    # issue: https://github.com/fish-shell/fish-shell/issues/6942
    if test $argv[1] = --no-focus
        set argv $argv[2..]
        set argv $argv[1 .. -2] 'type --query __fish_disable_focus && __fish_disable_focus' $argv[-1]
    end

    bind $argv
end
