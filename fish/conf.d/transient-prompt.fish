# Transient prompt
#
# TODO: Ideally I'd do this with a preexec hook, but that won't work for reasons outlined
# in this issue: https://github.com/fish-shell/fish-shell/issues/7602#issuecomment-831601418

if not status is-interactive
    exit
end

# rebind enter so that before executing the commandline it redraws the prompt as a transient prompt
function _load_transient_prompt_and_execute
    # If the pager is open, that means I am selecting an item, like an autocomplete suggestion.
    # In which case, I do not want to load a transient prompt.
    if not commandline --paging-mode
        set commandline_contents (commandline)
        # I use --valid so that the prompt doesn't become transient while I'm entering a multiline
        # command
        if commandline --is-valid
            set --global TRANSIENT
            commandline -f repaint
        # Make a distinction for an empty commandline. With this, I could insert a blank
        # line when the commandline is empty, giving me a way to separate commands visually
        else if test -z "$commandline_contents"
            set --global TRANSIENT_EMPTY
            commandline -f repaint
        end
    end
    commandline -f execute
end
bind \r _load_transient_prompt_and_execute

# rebind ctrl+c so that before cancelling the commandline it redraws the prompt as a transient prompt
function _load_transient_prompt_and_cancel
    set --global TRANSIENT
    commandline -f repaint
    commandline -f cancel-commandline
    commandline -f repaint
end
bind \cc _load_transient_prompt_and_cancel

# rebind ctrl+d so that before exiting the shell it redraws the prompt as a transient prompt
function _delete_or_load_transient_prompt_and_exit
    if test -n "$(commandline)"
        commandline -f delete-char
        return
    end

    set --global TRANSIENT
    commandline -f repaint

    # I do this instead of 'commandline -f exit' so that this way the word exit will be left on the previous prompt
    # instead of it just being blank. This way it's clear that the previous command was to exit from a shell.
    commandline --replace 'exit'
    commandline -f execute

    commandline -f repaint
end
bind \cd _delete_or_load_transient_prompt_and_exit
