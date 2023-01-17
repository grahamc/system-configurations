function nix-env
    command nix-env $argv
    set exit_code $status

    if string match -- '-*i*' $argv
        # Cut off everything from the last dash to the end of the string, that should be the version
        nix-env -q | string split --right --max 1 --fields 1 -- - > ~/.config/nix/nix-packages.txt
    end

    return $exit_code
end
