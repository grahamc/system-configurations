# Prints a reminder to run mandb if a manpage can't be found.

if not status is-interactive
    exit
end

function mandb-reminder --on-event fish_postexec
    set last_interactive_status $status
    set last_interactive_pipestatus $pipestatus
    set command (string split ' ' -- "$argv")[1]

    if test "$command" = 'man'
            and test $last_interactive_status -eq 16
            and test (count $last_interactive_pipestatus) -eq 1
        echo -e "\n$(set_color --reverse --bold yellow) TIP $(set_color normal) Try running $(set_color yellow)'mandb'$(set_color normal) to update the manual page index cache" >/dev/stderr
    end
end
