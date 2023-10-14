if not status is-login
    exit
end

if test -f ~/.profile
    # My ~/.profile is written in POSIX sh so I'm sourcing it in a child POSIX shell and having that shell print out
    # its environment, one variable per line, in the form `export NAME='value'`. This way I can just `eval` those
    # export statements in this shell.
    #
    # - I omit the SHLVL of the bash shell since I don't want the SHLVL in this shell to change.
    #
    # - I omit the 'PWD' and '_' variables since they are readonly in fish and I'll get an error message if I try
    # to set them.
    #
    # - The `-0` flag in env terminates each environment variable with a null byte, instead of a newline.
    # The `-z` in sed tells sed that its input is separated by null bytes and not newlines. With both of these, I
    # can distinguish between the end of an environment variable and a newline inside a variable. The `tr` command
    # removes the null bytes from sed's output.
    #
    # - Since I use single quotes to enclose the variable I have to do something about single quotes inside the
    # variable. The second sed command will replace those single quotes with `'"'"'`. An explanation of what that does
    # is here: https://stackoverflow.com/a/1250279. The groups of 3 backslashes are there to escape the double quotes
    # right after them.
    set sh_environment "$(sh -c ". ~/.profile; env -0 -u SHLVL -u PWD -u _ | sed -z \"s/^/export /;s/'/'\\\"'\\\"'/g;s/=/='/;s/\$/'\;\n/\" | tr -d '\000'")"
    eval "$sh_environment"
end
