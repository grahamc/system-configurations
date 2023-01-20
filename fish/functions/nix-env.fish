function nix-env
    command nix-env $argv
    set exit_code $status

    if string match --quiet -- '-*i*' $argv
        nix-env --query > ~/.config/nix/nix-packages.txt
    end

    return $exit_code
end
