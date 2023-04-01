# Reload all fish instances

if not status is-interactive
    exit
end

function _reload_fish --on-variable _fish_reload_indicator
    if jobs --query
        echo -n -e "\n$(set_color --reverse --bold yellow) WARNING $(set_color normal) The shell will not reload since there are jobs running in the background.$(set_color normal)"
        commandline -f execute
        return
    end

    _clear_screen
    echo "$(set_color --reverse --bold brwhite) INFO $(set_color normal) Reloading the shell...$(set_color normal)"
    exec fish
end

function reload-fish
    set --universal _fish_reload_indicator (random)
end
