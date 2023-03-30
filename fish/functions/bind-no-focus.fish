# TODO: Workaround for fish bug
# issue: https://github.com/fish-shell/fish-shell/issues/6942
function bind-no-focus
    bind $argv[1 .. -2] '__fish_disable_focus' $argv[-1]
end
