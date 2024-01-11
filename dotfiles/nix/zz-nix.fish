if not status is-interactive
    exit
end

# I prepend zz to the filename so it runs after other configs. This way this wrapper won't get
# overwritten.

if functions --query nix
    functions --copy nix __any_nix_shell_wrapper
    function nix
        # If I'm starting the repl, start it with my startup file.
        if test (count $argv) -eq 1 -a "$argv[1]" = repl
            set xdg_config (test -n "$XDG_CONFIG_HOME" && echo $XDG_CONFIG_HOME || echo "$HOME/.config")
            set --append argv --file "$xdg_config/nix/repl-startup.nix"
            command nix $argv
        else
            __any_nix_shell_wrapper $argv
        end
    end
else
    function nix
        # If I'm starting the repl, start it with my startup file.
        if test (count $argv) -eq 1 -a "$argv[1]" = repl
            set xdg_config (test -n "$XDG_CONFIG_HOME" && echo $XDG_CONFIG_HOME || echo "$HOME/.config")
            set --append argv --file "$xdg_config/nix/repl-startup.nix"
        end
        command nix $argv
    end
end

# If the user run a nix or hostctl command while in a git repository with untracked files, warn them since those
# files will be ignored by any Nix Flake operation.
#
# TODO: They're considering making this behaviour configurable though. In which case I can remove this.
# issue: https://github.com/NixOS/nix/pull/6858
# issue: https://github.com/NixOS/nix/issues/7107
function _nix-unstaged-files-warning --on-event fish_preexec --argument-names commandline
    set command (string split ' ' -- "$commandline")[1]
    if not string match --regex --quiet -- nix "$command"
        and not string match --regex --quiet -- hostctl "$command"
        and not string match --regex --quiet -- home-manager "$command"
        and not string match --regex --quiet -- darwin-rebuild "$command"
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

    # If there are untracked or removed files, offer to add them to the index since they would
    # otherwise be ignored by any Nix flake.
    if test -n "$untracked_or_deleted_files"
        echo -e -n "\n$(set_color --reverse --bold yellow) WARNING $(set_color normal) THE FOLLOWING UNTRACKED/REMOVED FILES IN THIS REPOSITORY WILL BE IGNORED BY ANY NIX FLAKE OPERATION:\n$untracked_or_deleted_files\n" >/dev/stderr
        set choices 'Add them, using --intent-to-add, to the index' 'Continue without adding them'
        set choice (printf %s\n $choices | fzf --no-preview --height ~100% --margin 1,2,0,2 --prompt 'What would you like to do?')
        or return
        if test "$choice" = "$choices[1]"
            git add --intent-to-add (printf $untracked_or_deleted_files | string split '\n')
        end
    end
end
