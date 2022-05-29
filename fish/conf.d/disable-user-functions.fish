# Do not load user functions in non-interactive shells. This is because I often have
# functions with the same name as common commands and I don't want scripts to
# accidentally use them.

if status is-interactive
    exit
end

# WARNING: To be safe, all code should be put inside this 'begin' block.
# Reason being, the code in this conditional gets run when fish is running a script so the output
# could break a script that expects certain content, or no content, in stdout or stderr.
# By using a block, I can supress any of its output to stdout or stderr.
#
# For an example of how output could break ssh/scp/rsync, see the following link:
# https://fishshell.com/docs/current/faq.html#why-won-t-ssh-scp-rsync-connect-properly-when-fish-is-my-login-shell
begin
    if set --query XDG_CONFIG_HOME
        set xdg_config_home $XDG_CONFIG_HOME
    else
        set xdg_config_home "$HOME/.config"
    end

    # Remove the path to user functions from the $fish_function_path
    set -l user_fish_functions_directory "$xdg_config_home/fish/functions"
    set -l index (contains --index $user_fish_functions_directory $fish_function_path)
    if test -n "$index"
        set --erase fish_function_path[$index]
    end
end >/dev/null 2>/dev/null
