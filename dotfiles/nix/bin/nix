#!/usr/bin/env fish

# If the user is in a git repository with untracked files, warn them since those
# files will be ignored by any Nix Flake operation.
#
# TODO: They're considering making this behaviour configurable though. In which case I can remove this.
# issue: https://github.com/NixOS/nix/pull/6858
# issue: https://github.com/NixOS/nix/issues/7107

function maybe_warn
    # Search the current directory and its ancestors for a flake.nix file
    set found_flake 0
    set current_directory (pwd)
    while true
        if test -f "$current_directory/flake.nix"
            set found_flake 1
            break
        end

        set parent_directory (path normalize "$current_directory/..")
        # This will happen when hit the root directory '/'
        if test "$current_directory" = "$parent_directory"
            break
        end
        set current_directory "$parent_directory"
    end

    if test "$found_flake" -eq 0
        return
    end

    set untracked_or_deleted_files "$(git ls-files --deleted --others --exclude-standard)"
    set untracked_or_deleted_file_list (printf $untracked_or_deleted_files | string split '\n')

    # If there are untracked or removed files, offer to add them to the index since they would
    # otherwise be ignored by any Nix flake.
    if test -n "$untracked_or_deleted_files"
        begin
            echo -e "\n$(set_color --reverse --bold yellow) WARNING $(set_color normal) THE UNTRACKED/REMOVED FILES IN THIS REPOSITORY WILL BE IGNORED BY ANY NIX FLAKE OPERATION!"
            echo 'You can add them to the index with the following command:'
            printf "git add --intent-to-add $untracked_or_deleted_file_list\n\n"
        end >/dev/tty 2>&1
    end
end

function abort
    if isatty stderr
        echo (set_color red)'Error: Unable to find the real nix' >&2
    end
    exit 127
end

# To find the real nix just take the next nix binary on the $PATH after this one. This way if there
# are other wrappers they can do the same and eventually we'll reach the real nix.
set nix_commands (which -a nix)
if not set index (contains --index -- (status filename) $nix_commands)
    abort
end
set real_nix $nix_commands[(math $index + 1)]
if test -z "$real_nix"
    abort
end

maybe_warn
exec $real_nix $argv
