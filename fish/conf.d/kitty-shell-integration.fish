# Load the kitty terminal shell integration

if not status is-interactive
    exit
end

# Check if fish is running inside a kitty terminal
if not string match --quiet '*-kitty' "$TERM"
    exit
end

if set -q KITTY_INSTALLATION_DIR
    source "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_conf.d/kitty-shell-integration.fish"
    set --prepend fish_complete_path "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_completions.d"
end
