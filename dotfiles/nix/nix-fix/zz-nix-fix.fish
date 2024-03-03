# I have to do this in a /usr/share config because unlike most shells, they get sourced last. Looks
# like they want to change this behavior though:
# https://github.com/fish-shell/fish-shell/issues/8553
#
# If DS's Nix installer only ran in interactive mode, I could put this in config.fish since that
# gets run last, but config.fish is only run in interactive mode. What mode files are run in may
# change though:
# https://github.com/fish-shell/fish-shell/issues/5394#issuecomment-593139513

# I don't want to use this variable. Only thing I know that sets this is the Determinate Systems Nix
# installer
set fish_user_paths

# use a function to scope variables
function __fish_path_fix
    # TODO: The Determinate Systems Nix installer adds nix to the $PATH even if the shell wasn't
    # launched in login mode. Specifically:
    #   - Its fish config is not guarded by a login-mode check
    #   - Its zsh config is in /etc/zshrc which gets run whenever zsh is interactive, regardless
    #   of whether or not it is in login mode
    #
    # This may result in duplicates so to get around that, I'm going to try to remove the extra
    # prepended entries by deduplicating the whole path, favoring later entries. I'm doing it this way
    # to to avoid hardcoding the paths they add.
    #
    # Maybe I should ask them if this behavior should be changed by adding a login-mode guard or only
    # adding the $PATH entries if they aren't already present.
    if not status is-login
        set new_path
        for path in (printf '%s\n' $PATH[-1..1])
            if not contains $path $new_path
                set --prepend new_path $path
            end
        end
        set PATH $new_path
    end

    # TODO: For fish, the Determinate Systems Nix installer moves entries to the front of the $PATH
    # if they already existed unlike bash where it adds them again to the front, resulting in
    # duplicate entries. The latter case is handled by the code above, but for the former case the
    # following code will detect $PATH entries that were moved closer to the front of $PATH and put
    # them back. I should report this since the behavior of the installer isn't consistent across
    # shells. I'd prefer they did neither though and instead did one of the things I suggested in
    # the above TODO.
    #
    # HACK: Not sure if the output `set --show` is part of the public API.
    set show_output (set --show PATH)
    set inherited_path (printf $show_output[-1] | string match --groups-only --regex -- '^.*\|(.*)\|$' | string split ':')
    if test (count $inherited_path) -eq 0
        echo 'Error: unable to fix path, couldn\'t get the inherited path' >&2
        return
    end
    for index in (seq (count $inherited_path))
        set entry $inherited_path[$index]
        set index_in_current_path (contains --index $entry $PATH)
        if test -n "$index_in_current_path"
            and test $index_in_current_path -lt $index
            set --erase PATH[$index_in_current_path]
            if test $index -eq 1
                set PATH $PATH[1] $entry $PATH[2..]
                # after removing the term the index may be greater
            else if test $index -ge (count $PATH)
                set --append PATH $entry
            else
                set PATH $PATH[1..(math $index)] $entry $PATH[(math $index + 1)..(count $PATH)]
            end
        end
    end
end
__fish_path_fix
