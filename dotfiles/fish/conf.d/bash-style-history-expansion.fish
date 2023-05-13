# bash-style history expansion (!! and !$)

if not status is-interactive
    exit
end

function _bind_bang
    switch (commandline -t)
        case "!"
            commandline -t -- $history[1]
            commandline -f repaint
        case "*"
            commandline -i !
    end
end
function _bind_dollar
    switch (commandline -t)
        # Variation on the original, vanilla "!" case
        # ===========================================
        #
        # If the `!$` is preceded by text, search backward for tokens that
        # contain that text as a substring. E.g., if we'd previously run
        #
        #   git checkout -b a_feature_branch
        #   git checkout main
        #
        # then the `fea!$` in the following would be replaced with
        # `a_feature_branch`
        #
        #   git branch -d fea!$
        #
        # and our command line would look like
        #
        #   git branch -d a_feature_branch
        #
        case "*!"
            commandline -f backward-delete-char history-token-search-backward
        case "*"
            commandline -i '$'
    end
end
bind ! _bind_bang
bind '$' _bind_dollar
