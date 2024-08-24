# Source:
# https://code.visualstudio.com/docs/terminal/shell-integration#_manual-installation

if status --is-interactive
    if test -n "$VSCODE_INJECTION"
        # TODO: The script expects TERM_PROGRAM to be set, but it isn't for some
        # reason so I'll do it.
        set --global --export TERM_PROGRAM vscode
        . (code --locate-shell-integration-path fish)
    end
end
