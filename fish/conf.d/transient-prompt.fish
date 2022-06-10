# Transient prompt
#
# TODO: Ideally I'd do this with a preexec hook, but that won't work for reasons outlined
# in this issue: https://github.com/fish-shell/fish-shell/issues/7602#issuecomment-831601418

if not status is-interactive
    exit
end

function _transient_repaint
    set --global TRANSIENT
    set --global TRANSIENT_RIGHT
    commandline -f repaint
end

function _transient_empty_repaint
    set --global TRANSIENT_EMPTY
    set --global TRANSIENT_EMPTY_RIGHT
    commandline -f repaint
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
            _transient_repaint
        # Make a distinction for an empty commandline. With this, I could insert a blank
        # line when the commandline is empty, giving me a way to separate commands visually
        else if test -z "$commandline_contents"
            _transient_empty_repaint
        end
    end

    # TODO: fish-abbreviation-tips also has a \r binding so I'm calling it here if
    # it's defined. Since the last line in the abbr-tips function executes the commandline,
    # I make sure to not also do it here if I'm calling that function.
    type --query __abbr_tips_bind_newline
    and __abbr_tips_bind_newline
    or commandline -f execute
end
bind \r _load_transient_prompt_and_execute

# rebind ctrl+c so that before cancelling the commandline it redraws the prompt as a transient prompt
function _load_transient_prompt_and_cancel
    _transient_repaint
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

    _transient_repaint

    # I do this instead of 'commandline -f exit' so that this way the word exit will be left on the previous prompt
    # instead of it just being blank. This way it's clear that the previous command was to exit from a shell.
    commandline --replace 'exit'
    commandline -f execute

    commandline -f repaint
end
bind \cd _delete_or_load_transient_prompt_and_exit
