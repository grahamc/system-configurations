# The '00' in the beginning of the file name is to ensure that this script is run before the fish-async-prompt config.
# This way I can set its config variables before it starts up.


# Have `$async_function_name` get run asynchronously and show the text returned by `$loading_indicator_function_name`
# while the async function is running.
#
# TODO: This won't be needed when fish adds support for rendering the prompt asynchronously.
# issue: https://github.com/fish-shell/fish-shell/issues/1942
function _add_async_prompt_function --argument-names async_function_name loading_indicator_function_name
    # fish-async-prompt will wrap the functions added here and make them run asynchronously.
    set --global --append async_prompt_functions $async_function_name

    # fish-async-prompt expects the loading indicator function for `$async_function_name` to be named
    # `$async_function_name`_loading_indicator
    set correct_loading_indicator_function_name $async_function_name'_loading_indicator'
    # If the function already has the right name don't do anything. This is because functions can't be wrapped by a
    # function with the same name.
    # see: https://stackoverflow.com/questions/46698467/is-it-possible-to-wrap-an-existing-function-with-another-function-using-the-same
    if test $loading_indicator_function_name != $correct_loading_indicator_function_name
        function $correct_loading_indicator_function_name
            eval $loading_indicator_function_name
        end
    end
end

# Since I erased `fish_mode_prompt`, my `fish_prompt` will be reloaded whenever $fish_bind_mode changes instead.
# By default, fish-async-prompt runs when $fish_bind_mode changes so this removes that.
set --global async_prompt_on_variable
