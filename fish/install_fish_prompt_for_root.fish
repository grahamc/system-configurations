# I'm using a function so that my variables will have a function-local scope
function _install_fish_prompt_for_root
    echo 'Are you sure want to install the fish prompt for the root user? (y/n): '
    read --prompt 'echo "> "' --nchars 1 response
    if test $response != y
        return
    end
    sudo install --compare --backup --suffix=.bak --owner=root --group=root --mode='u=rw,g=r,o=r' -D --verbose --no-target-directory fish/functions/fish_prompt.fish /root/.config/fish/functions/fish_prompt.fish
end

_install_fish_prompt_for_root $argv
