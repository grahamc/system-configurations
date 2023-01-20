if not status is-interactive
    exit
end

set pipx_completion_filepath "$HOME/.config/fish/completions/pipx.fish"
if type --query pipx && not test -e $pipx_completion_filepath
    mkdir -p (dirname "$pipx_completion_filepath")
    register-python-argcomplete --shell fish pipx > $pipx_completion_filepath
end
