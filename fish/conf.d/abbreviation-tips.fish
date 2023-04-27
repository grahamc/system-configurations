# fish-abbreviation-tips

if not status is-interactive
    exit
end

set --global --export ABBR_TIPS_PROMPT "\n$(set_color --reverse --bold blue) TIP $(set_color normal) If you type $(set_color blue)'{{ .abbr }}'$(set_color normal) it will expand to $(set_color blue)'{{ .cmd }}'$(set_color normal)"

# history-search-backward wrapper for the fish-abbreviation-tips plugin.
# This way, I won't get reminded about an abbreviation when executing a command
# from the history
function _abbr_tips_history_backward
    set -g __abbr_tips_used 1
    commandline -f history-search-backward
end
bind \e\[A _abbr_tips_history_backward

# If the commandline contains the most recent item in the history, we assume that moving forward in the history
# will exit the history. In this case, reenable abbreviation tips.
function _abbr_tips_history_forward
    set last_history_item (history --reverse | tail -1)
    if test "$last_history_item" = "$(commandline)"
        set -g __abbr_tips_used 0
    end

    commandline -f history-search-forward
end
bind \e\[B _abbr_tips_history_forward

# This way, I won't get reminded about an abbreviation when executing the autosuggested command
function _abbr_tips_forward_char
    set -g __abbr_tips_used 1
    commandline -f forward-char
end
bind \e\[C _abbr_tips_forward_char

# Initialize fish-abbreviation-tips. The plugin only runs init once when the plugin is installed so if I add new
# abbreviations after that, the plugin won't give tips for them. This should be towards the end of this file so that
# any abbreviations created in this file get loaded into fish-abbreviation-tips. I run it in the background so it
# doesn't impact load time.
#
# UPDATE: Because I install plugins through Nix Home Manager, the init is never run so I need this even more.
# See the declaration of this plugin in HM for more info.
#
# TODO: Fish doesn't support running functions in the background so I run it in a child shell instead. Since my
# abbreviations only get defined in an interactive shell, I load them into the child shell using --init-command.
# issue: https://github.com/fish-shell/fish-shell/issues/238
# fish --init-command "source $(abbr | psub)" --command '__abbr_tips_install' & disown
