# Automatically reload kitty whenever one of the files in its config directory changes.

if not status is-interactive
    exit
end

# Check if fish is running inside a kitty terminal
if not string match --quiet '*-kitty' "$TERM"
    exit
end

set xdg_config_home
if set --query XDG_CONFIG_HOME
    set xdg_config_home $XDG_CONFIG_HOME
else
    set xdg_config_home "$HOME/.config"
end
set kitty_config_path "$xdg_config_home/kitty"

flock --nonblock /tmp/kitty-autoreload-lock --command "watchman-make --root '$kitty_config_path' --pattern '**/*' --run 'reload-kitty >/dev/tty' >/dev/null 2>/dev/null" >/dev/null &
disown
