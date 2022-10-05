# NOTE: Unlike most of my other fish configs, this one does not check if the shell is being run
# interactively. This is because the functions defined here will be called in a non-interactive shell by my
# async prompt plugin.

set --universal async_prompt_functions fish_prompt_get_git_context

# git
function fish_prompt_get_git_context_loading_indicator
    echo -n -s 'git: ' (set_color --dim --italics) 'loading…'
end
function fish_prompt_get_git_context
    set --global __fish_git_prompt_char_upstream_ahead ',ahead:'
    set --global __fish_git_prompt_char_upstream_behind ',behind:'
    set --global __fish_git_prompt_char_untrackedfiles ',untracked'
    set --global __fish_git_prompt_char_dirtystate ',dirty'
    set --global __fish_git_prompt_char_stagedstate ',staged'
    set --global __fish_git_prompt_char_invalidstate ',invalid'
    set --global __fish_git_prompt_char_stateseparator ''

    set git_context (fish_git_prompt)
    if test -z $git_context
        return
    end

    if test (string length --visible $git_context) -gt (math (stty size </dev/tty | cut -d" " -f2) - 10)
        set --global --export __fish_git_prompt_char_upstream_ahead '↑'
        set --global --export __fish_git_prompt_char_upstream_behind '↓'
        set --global --export __fish_git_prompt_char_untrackedfiles '?'
        set --global --export __fish_git_prompt_char_dirtystate '!'
        set --global --erase __fish_git_prompt_char_stagedstate
        set --global --erase __fish_git_prompt_char_invalidstate
        set --global --export __fish_git_prompt_char_stateseparator ' '
        set git_context (fish_git_prompt)
    end

    # remove parentheses and leading space e.g. ' (branch,dirty,untracked)' -> 'branch,dirty,untracked'
    set --local formatted_context (string sub --start=3 --end=-1 $git_context)
    # replace first comma with ' (' e.g. ',branch,dirty,untracked' -> ' (branch dirty,untracked'
    set --local formatted_context (string replace ',' ' (' $formatted_context)
    # only add the closing parenthese if we added the opening one
    and set formatted_context (string join '' $formatted_context ')')

    echo -n -s 'git: ' $formatted_context
end
