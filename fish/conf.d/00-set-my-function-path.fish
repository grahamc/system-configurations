if not status is-interactive
    exit
end

# I only want my functions loaded into an interactive shell so I add them to the function path here.
# This needs to be set early in the config in case my functions are referenced here which is why the filename
# is prepended with '00'.
set --global --prepend fish_function_path "$__fish_config_dir/my-functions"
