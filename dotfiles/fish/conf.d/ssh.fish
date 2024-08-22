if not status is-interactive
    exit
end

function ssh
    # TODO: check if a command was provided or set in ssh config and if so, bail because
    # otherwise sshd will just concatenate both commands. or maybe I can put a semicolon at the
    # end of mine so they both get used. Since my command will end up using exec, it should be
    # last.
    if not set index (contains --index -- '--bootstrap' $argv)
        command ssh $argv
    else
        set size $argv[(math $index + 1)]
        set --erase argv[$index]
        set --erase argv[$index]

        set xdg_config "$HOME/.config"
        # Don't check if it's exported, it won't be in portable home
        if set --query XDG_CONFIG_HOME
            set xdg_config "$XDG_CONFIG_HOME"
        end
        set script "$xdg_config/ssh/bootstrap.sh"

        # source:
        # https://github.com/kovidgoyal/kitty/blob/d33afd4e96cb6b9f84512568ce97816257a256c4/kittens/ssh/main.go#L486
        set encoded_script (tr \n\'! \r\v\b <$script | tr \\ \f 2>/dev/null)
        set decode_script 'eval "$(echo "$0" | tr "\r\v\b\f" "\n\047\041\134")"'
        set remote_command "BIGOLU_BOOTSTRAP_SIZE='$size' sh -c '$decode_script' '$encoded_script'"

        # If I'm already SSH'd this will be set so I can just pass it along
        if not set --query BIGOLU_TERMINFO
            # For more information about terminfo, including where most machines store their
            # terminfo DB:
            # https://unix.stackexchange.com/questions/644890/how-to-list-and-delete-terminfo
            # https://sw.kovidgoyal.net/kitty/kittens/ssh/#copying-terminfo-files-manually
            #
            # and more on the related environment variables (e.g. TERMINFO, TERMCAP):
            # https://invisible-island.net/ncurses/man/ncurses.3x.html#h3-TERM
            #
            # This command outputs the current terminfo encoded with base64. Source:
            # https://invisible-island.net/ncurses/man/ncurses.3x.html#h3-TERMINFO
            #
            # infocmp uses -_ as the 62nd and 63rd characters, but base64 uses +/ so we'll change it
            set BIGOLU_TERMINFO "$(infocmp -0 -Q2 -q | tr _- /+)"
            # For machines that don't support terminfo.
            #
            # WARNING: The -T flag removes the restriction on the output length. This may break some
            # programs:
            # https://unix.stackexchange.com/questions/291412/how-can-i-use-terminfo-entries-on-freebsd#comment510233_291455
            #
            # This will be stored in a single quoted string below so I'm base64 encoding it so I
            # don't have to escape any characters in it.
            #
            # Using quotes to preserve newlines
            set BIGOLU_TERMCAP "$(infocmp -Cr0Tq | base64)"
        end
        set remote_command "BIGOLU_TERMCAP='$BIGOLU_TERMCAP' BIGOLU_TERMINFO='$BIGOLU_TERMINFO' BIGOLU_COLORTERM='$COLORTERM' $remote_command"

        ssh -o RequestTTY=yes $argv "$remote_command"
    end
end

complete --command ssh --long-option bootstrap --description 'set up terminfo and/or shell on remote' --no-files --require-parameter --arguments '(printf %s\n "small"\t"only terminfo" "big"\t"terminfo and shell")'
