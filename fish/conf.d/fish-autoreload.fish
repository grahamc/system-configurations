# Automatically reload fish whenever one of the files in its config directory changes.

if not status is-interactive
    exit
end

if set --query XDG_CONFIG_HOME
    set xdg_config_home $XDG_CONFIG_HOME
else
    set xdg_config_home "$HOME/.config"
end

function _autoreload_fish --on-variable _autoreload_indicator
    exec fish
end
set fish_config_path "$xdg_config_home/fish"

flock --nonblock /tmp/fish-autoreload-lock --command "watchman-make --root '$fish_config_path/my-fish' --pattern 'conf.d/**' 'config.fish' --run 'fish -c \"set --universal _autoreload_indicator (random)\"' 2>/dev/null" &
# If flock can't acquire the lock then the background job exits immediately and there will be nothing to disown
# so disown will print an error which is why we suppress error output.
disown 2> /dev/null

flock --nonblock /tmp/fish-autoreload-2-lock --command "watchman-make --root '$fish_config_path' --pattern 'conf.d/**' --run 'fish -c \"set --universal _autoreload_indicator (random)\"' 2>/dev/null" &
# If flock can't acquire the lock then the background job exits immediately and there will be nothing to disown
# so disown will print an error which is why we suppress error output.
disown 2> /dev/null
