# NOTE: Unlike most of my other fish configs, this one does not check if the shell is being run
# interactively. This is because the functions defined here will be called in a non-interactive shell by my
# async prompt plugin.

set --global async_prompt_functions \
    __fish_prompt_get_git_context

# git
# Leaving this a global variable since it will be accessed from my main prompt function
set git_loading_indicator (echo -n -s (set_color --dim --italics) 'loading…')
function __fish_prompt_get_git_context_loading_indicator
    echo -n $git_loading_indicator
end
function __fish_prompt_get_git_context
    set --global __fish_git_prompt_showupstream 'informative'
    set --global __fish_git_prompt_showdirtystate 1
    set --global __fish_git_prompt_showuntrackedfiles 1
    set --global __fish_git_prompt_char_upstream_ahead ',ahead:'
    set --global __fish_git_prompt_char_upstream_behind ',behind:'
    set --global __fish_git_prompt_char_untrackedfiles ',untracked'
    set --global __fish_git_prompt_char_dirtystate ',dirty'
    set --global __fish_git_prompt_char_stagedstate ',staged'
    set --global __fish_git_prompt_char_invalidstate ',invalid'
    set --global __fish_git_prompt_char_stateseparator ''
    fish_git_prompt
end
