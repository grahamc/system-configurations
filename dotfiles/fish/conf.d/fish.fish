if not status is-interactive
    exit
end

set --global --export fish_color_normal
set --global --export fish_color_command
set --global --export fish_color_quote green
set --global --export fish_color_redirection
set --global --export fish_color_end
set --global --export fish_color_error red
set --global --export fish_color_param
set --global --export fish_color_comment brwhite
set --global --export fish_color_match
set --global --export fish_color_search_match --background=brblack
# TODO: I want to remove the default bolding, but currently only the background is configurable.
# Issue: https://github.com/fish-shell/fish-shell/issues/2442
set --global --export fish_pager_color_selected_background --background=brblack
set --global --export fish_color_operator
set --global --export fish_color_escape
set --global --export fish_color_cwd
set --global --export fish_color_autosuggestion brwhite
set --global --export fish_color_user
set --global --export fish_color_host
set --global --export fish_pager_color_prefix cyan
set --global --export fish_pager_color_completion
set --global --export fish_pager_color_description
set --global --export fish_pager_color_progress --background=brblack normal
set --global --export fish_pager_color_secondary
set --global --export fish_color_cancel black
set --global --export fish_color_valid_path

abbr --add --global r 'reload-fish'

# Don't print a greeting when a new interactive fish shell is started
set --global --export fish_greeting ''

# use ctrl+z to resume the most recently suspended job
function _resume_job
    if not jobs --query
        return
    end

    set job_count (jobs | wc -l)

    if test "$job_count" -eq 1
        fg 1>/dev/null 2>&1

        # this should be done whenever a binding produces output (see: man bind)
        commandline -f repaint

        return
    end

    set entries
    for job_pid in (jobs --pid)
        set job_command (ps -o command= --pid "$job_pid")
        set --append entries "$job_pid:$job_command"
    end

    set choice \
        ( \
            printf '%s\n' $entries | \
            fzf  \
            --delimiter ':' \
            --with-nth '2..' \
            --no-preview \
            --height 30% \
        )
    and begin
        set tokens (string split ':' "$choice")
        set pid $tokens[1]
        fg "$pid" 1>/dev/null 2>&1
    end

    # this should be done whenever a binding produces output (see: man bind)
    commandline -f repaint
end
bind-no-focus \cz '_resume_job'

# use ctrl+right-arrow to accept the next suggested word
bind \e\[1\;3C forward-word

# use ctrl+b to jump to beginning of line
bind \cb beginning-of-line

# ctrl+r to refresh terminal, shell, and screen
bind \cr 'reset && exec fish && clear'

# search variables
abbr --add --global fv 'FZF_DEFAULT_COMMAND="set --names" fzf --preview "set --show {}"'

# set terminal title
echo -ne "\033]0;fish\007"

# Use shift+tab to select an autocomplete entry with fzf
function _fzf_complete
    set choice \
        ( \
            complete --escape --do-complete (commandline --cut-at-cursor) \
            # remove duplicates
            | sort --unique \
            # Use a different color for the completion item description
            | string replace --regex -- '(?<item>[^\t]*)((?<whitespace>\t)(?<description>.*))?' (set_color normal)'$item'(set_color brwhite)'$whitespace$description' \
            | fzf \
                --delimiter \t \
                --no-preview \
                --height 45% \
                --no-header \
                --bind 'backward-eof:abort' \
                --select-1 \
                --prompt "$(commandline --current-token)" \
                --exit-0 \
                --no-hscroll \
                --color 'gutter:-1,prompt:6' \
                --tiebreak=begin,chunk \
        )
    and begin
        set entry "$(string split -f1 -- \t $choice)"

        set space ' '
        # Only add a space after the entry if it isn't an abbreviation.
        #
        # TODO: This assumes that an abbreviation can only be expanded if it's the first token in the commandline.
        # However, with the flag '--position anywhere', abbreviations can be expanded anywhere in the commandline so
        # I should check for that flag.
        #
        # TODO: Need to account for when the directory starts with tilde, gotta expand it
        #
        # We determine if the entry will be the first token by checking for an empty commandline.
        # We trim spaces because spaces don't count as tokens.
        set trimmed_commandline (string trim "$(commandline)")
        if abbr --query -- "$entry"
        and test -z "$trimmed_commandline"
            set space ''
        else if test -d "$entry"
        and printf "$entry" | grep -q -E '\/$'
            set space ''
        else if test -d "$PWD/$entry"
        and printf "$entry" | grep -q -E '\/$'
            set space ''
        end

        commandline --replace --current-token -- "$entry$space"
    end

    commandline -f repaint
end
function _fzf_complete_helper
    if commandline --paging-mode
        commandline -f forward-char
        return
    end

    if not type --query fzf
        commandline -f complete
    else
        _fzf_complete
    end
end
# Set the binding on fish_prompt since something else was overriding it.
function __set_fzf_tab_complete --on-event fish_prompt
    # I only want this to run once so delete the function.
    functions -e (status current-function)
    bind-no-focus \t _fzf_complete_helper
end
# Keep normal tab complete on shift+tab to expand wildcards.
bind -k btab complete

# Save command to history before executing it. This way long running commands, like ssh or watch, will show up in
# the history immediately.
function __save_history --on-event fish_preexec
    history --save
end

# Don't update the window title
function fish_title
  true
end

function _ls-after-directory-change --on-variable PWD
  # These directories have too many files to always call ls on
  set blacklist /nix/store /tmp
  if contains "$PWD" $blacklist
    return
  end

  ls --hyperlink=auto
end

# Reload all fish instances
function _reload_fish --on-variable _fish_reload_indicator
    if jobs --query
        echo -n -e "\n$(set_color --reverse --bold yellow) WARNING $(set_color normal) The shell will not reload since there are jobs running in the background.$(set_color normal)"
        commandline -f repaint
        return
    end

    # Taken from fish's ctrl+l keybinding
    echo -n (clear | string replace \e\[3J "")

    echo "$(set_color --reverse --bold brwhite) INFO $(set_color normal) Reloading the shell...$(set_color normal)"
    exec fish
end
function reload-fish
    set --universal _fish_reload_indicator (random)
end
