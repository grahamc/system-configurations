# Load fish_user_key_bindings now instead of after config.fish
#
# By default, fish calls the function 'fish_user_key_bindings', if it exists, after config.fish
# gets loaded. This means any key bindings set in 'fish_user_key_bindings' will override keybinds
# set in config.fish or a script in conf.d/. I would prefer it if keybinds in config.fish, or conf.d/,
# would override keybinds in 'fish_user_key_bindings'. This way I can change the
# default keybinds for tools like fzf.
#
# The '00' in the beginning of the file name is to ensure that this script is run before any others
# in conf.d, for reasons stated above.

if not status is-interactive
    exit
end

# Call fish_user_key_bindings right now, if it exists, and then erase the function
# so that fish doesn't call it later.
set fish_keybind_function_name fish_user_key_bindings
if functions --query $fish_keybind_function_name
    eval $fish_keybind_function_name
    functions --erase $fish_keybind_function_name
end
