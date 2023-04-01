# TODO: Workaround for fish bug
# issue: https://github.com/fish-shell/fish-shell/issues/6942
function bind-no-focus
    bind $argv[1 .. -2] 'type --query __fish_disable_focus && __fish_disable_focus' $argv[-1]
end
