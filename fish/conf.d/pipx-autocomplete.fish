if not status is-interactive
    exit
end

set pipx_completion_filepath "$HOME/.config/fish/completions/pipx.fish"
if type --query pipx && not test -e $pipx_completion_filepath
    read --prompt-str 'Autocomplete for pipx has not been setup, would you like to do that now? (y/n): ' --nchars 1 response
    if test $response = 'y'
        register-python-argcomplete --shell fish pipx > $pipx_completion_filepath
    end
end
