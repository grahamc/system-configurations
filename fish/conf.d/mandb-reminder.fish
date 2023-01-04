# Prints a reminder to run mandb if a manpage can't be found.

if not status is-interactive
    exit
end

function mandb-reminder --on-event fish_postexec --argument-names commandline
    set last_interactive_status $status
    set last_interactive_pipestatus $pipestatus
    set command (string split ' ' -- "$commandline")[1]

    if test "$command" = 'man'
            and test $last_interactive_status -eq 16
            and test (count $last_interactive_pipestatus) -eq 1
        echo -e "\n$(set_color --reverse --bold blue) TIP $(set_color normal) Try running $(set_color blue)'mandb'$(set_color normal) to update the manual page index cache" >/dev/stderr
    end
end
