function nix-env
    command nix-env $argv
    set exit_code $status

    # matches:
    # a set of short flags containing 'i' or 'e' (e.g. -iA)
    # '--install' or '--uninstall'
    if string match --quiet --regex -- '^-([^-]*[ie].*|-((un)?install))$' $argv
        nix-env --query > ~/.config/nix/nix-packages.txt
    end

    return $exit_code
end
