if not status is-interactive
    exit
end

if test (uname) != Linux
    exit
end

abbr --add --global ai 'sudo apt install'
abbr --add --global ar 'sudo apt remove'
abbr --add --global aar 'sudo apt autoremove'
abbr --add --global aud 'sudo apt update'
abbr --add --global aug 'sudo apt upgrade'
abbr --add --global as apt-show
abbr --add --global ap 'apt policy'
abbr --add --global alu 'apt list --upgradeable'
abbr --add --global ap 'sudo apt purge'
abbr --add --global aiw apt-install-widget
abbr --add --global arw apt-remove-widget

function apt-show --description "'apt show' with each section name highlighted, paged with less" --wraps 'apt show'
    # I supress stderr to remove the warning that apt prints out when you use apt
    # in a non-interactive shell
    apt show $argv 2>/dev/null | grep --color=always -E "(^[a-z|A-Z|-]*:|^)" | less
end

function apt-install-widget --description 'Install packages with apt'
    if not set choices ( \
        FZF_DEFAULT_COMMAND='apt-cache pkgnames' \
        fzf-tmux-zoom \
            --prompt 'apt install: ' \
            --preview "apt show {} 2>/dev/null | GREP_COLORS='$GREP_COLORS' grep --color=always -E '(^[a-z|A-Z|-]*:|^)' | less" \
            --preview-window '75%' \
            --tiebreak=chunk,begin,end \
    )
        return
    end

    set sudo ''
    if not fish_is_root_user
        set sudo 'sudo '
    end

    echo "Running command '""$sudo""apt-get install $choices'..."

    sudo apt-get install --assume-yes $choices
end

function apt-remove-widget --description 'Remove packages with apt'
    if not set choices ( \
        FZF_DEFAULT_COMMAND='apt list --installed 2>/dev/null | string split --no-empty --fields 1 -- \'/\' | tail -n +2' \
        fzf-tmux-zoom \
            --prompt 'apt remove: ' \
            --preview "echo -e \"\$(apt show {} 2>/dev/null)\n\$(apt-cache rdepends --installed --no-recommends --no-suggests {} | tail -n +2)\" | GREP_COLORS='$GREP_COLORS' grep --color=always -E '(^[a-z|A-Z|-]*:|^.*:\$|^)' | less" \
            --preview-window '75%' \
            --tiebreak=chunk,begin,end \
    )
        return
    end

    set sudo ''
    if not fish_is_root_user
        set sudo 'sudo '
    end

    echo "Running command '""$sudo""apt-get remove $choices'..."
    sudo apt-get remove --assume-yes $choices
end
