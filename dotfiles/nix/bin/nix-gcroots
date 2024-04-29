#!/usr/bin/env fish

function get_symlink_chain --argument-names symlink
    set chase_output (chase --verbose $symlink 2>/dev/null)
    set chase_status $status
    # Remove the first line since it's the same as $symlink
    set chase_output $chase_output[2..]
    # Remove the last line since it's essentially a duplicate of the line before it, the terminal file
    set chase_output $chase_output[..-2]

    # The lines have the form '-> <path>' so I'm removing the first 3 characters to get the <path>.
    set chase_output_only_filenames (printf '%s\n' $chase_output | string sub --start 4)

    set chase_output_only_filenames[1] (set_color blue)$chase_output_only_filenames[1](set_color normal)

    set joined_chain (string join -- ' -> ' $chase_output_only_filenames)

    if test -n "$NIX_GCROOTS_INCLUDE_SIZE"
        # The out put of `du` looks like '<size> <filename>' so the `string match` removes everything after the size.
        set size (string match --regex -- '^[^\s]+' (du -shL $symlink 2>/dev/null))
        set joined_chain "$size $joined_chain"
    end

    echo $joined_chain
end

function print_roots_for_directory --argument-names directory
    set potential_roots $directory/*
    # Filter out broken links
    set roots
    for root in $potential_roots
        if test -e $root
            set --append roots $root
        end
    end
    if test (count $roots) -eq 0
        echo "No roots found."
    else
        set chains
        for root in $roots
            # Don't print broken symlinks
            if test -e $root
                set --append chains (get_symlink_chain $root)
            end
        end
        if test -n "$NIX_GCROOTS_INCLUDE_SIZE"
            # sort by size, descending
            set chains (printf '%s\n' $chains | sort --human-numeric-sort --reverse)
        else
            # sort alphabetically, ascending
            set chains (printf '%s\n' $chains | sort)
        end
        printf '%s\n' $chains
    end
    echo
end

function print_gcroots
    set gcroots_directory /nix/var/nix/gcroots

    # automatic roots
    set automatic_roots_directory "$gcroots_directory/auto"
    echo (set_color --bold --underline)"Automatic roots ($automatic_roots_directory):"(set_color normal)
    print_roots_for_directory $automatic_roots_directory

    # per-user roots
    set per_user_roots_directory "$gcroots_directory/per-user"
    for user_roots_directory in $per_user_roots_directory/*
        set user (path basename $user_roots_directory)
        echo (set_color --bold --underline)"Roots for user '$user' ($user_roots_directory):"(set_color normal)
        print_roots_for_directory $user_roots_directory
    end

    # User profile roots
    set per_user_profile_roots_directory "$gcroots_directory/profiles/per-user"
    for user_profile_roots_directory in $per_user_profile_roots_directory/*
        set user (path basename $user_profile_roots_directory)
        echo (set_color --bold --underline)"Roots for user profile '$user' ($user_profile_roots_directory):"(set_color normal)
        print_roots_for_directory $user_profile_roots_directory
    end
end

print_gcroots
