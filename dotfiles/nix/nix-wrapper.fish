#!/usr/bin/env fish

# If the user is in a git repository with untracked files, warn them since those
# files will be ignored by any Nix Flake operation.
#
# TODO: They're considering making this behaviour configurable though. In which case I can remove this.
# issue: https://github.com/NixOS/nix/pull/6858
# issue: https://github.com/NixOS/nix/issues/7107

function maybe_warn
    # This bash command checks if this process is connected to a terminal.
    # source: https://stackoverflow.com/a/69088164
    #
    #We need aterminal so we can prompt the user.
    if not bash -c ": 1>/dev/tty" 1>/dev/null 2>&1
        return
    end

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
        echo -e -n "\n$(set_color --reverse --bold yellow) WARNING $(set_color normal) THE FOLLOWING UNTRACKED/REMOVED FILES IN THIS REPOSITORY WILL BE IGNORED BY ANY NIX FLAKE OPERATION:\n$untracked_or_deleted_files\n" >/dev/stderr
        set choices 'Add them, using --intent-to-add, to the index' 'Continue without adding them'
        set choice (printf %s\n $choices | fzf --no-preview --height ~100% --margin 1,2,0,2 --prompt 'What would you like to do?')
        or return
        if test "$choice" = "$choices[1]"
            chronic git add --intent-to-add $untracked_or_deleted_file_list
        end
        set printed_line_count (math (count $untracked_or_deleted_file_list) + 2)
        printf (string repeat --count $printed_line_count "\33[2K\r\033[A") >/dev/tty
    end
end

maybe_warn

set nix_commands (which -a nix)
for command in $nix_commands
    # I assume the real nix command is the one that isn't a shebang script. I do this to
    # avoid an infinite loop that happens if I use nix from my portable-home on my machine,
    # since there will be 2 nix wrappers on the $PATH in that case. I canonicalize the path
    # to avoid symlinks.
    if test '#!' != "$(head -c 2 (readlink --canonicalize $command))"
        $command $argv
        exit
    end
end
