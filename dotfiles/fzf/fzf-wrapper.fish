#!/usr/bin/env fish

# When I use fzf through vscode it won't be launched from my shell which is a problem since I set
# FZF_DEFAULT_OPTS in my shell config. To make sure FZF_DEFAULT_OPTS still gets set, I wrap fzf in
# a hashbang script that uses my shell as the interpreter. This way when the interpreter starts, my
# shell config files will load and FZF_DEFAULT_OPTS will get set. I would set FZF_DEFAULT_OPTS here,
# but other programs, like zoxide, need FZF_DEFAULT_OPTS as well so I have to set it shell-wide.
#
# WARNING: On macOS, vscode doesn't seem to be calling fzf with the environment it gets through
# "shell resolution" so the $PATH won't be set properly. To avoid this I could open vscode from the
# terminal. Also I should report this.
#
# TODO: Find it Faster is probably aware of the above warning becuase they launch fzf from parent
# login shell. However, that login shell for me will be fish and current the Determinate Systems Nix
# installer fish config doesn't work on macOS so I'm still out of luck. I think it will be fixed by
# this issue:
# https://github.com/DeterminateSystems/nix-installer/issues/576
# Though ideally, find it faster wouldn't have to use a login shell, so it can start up more
# quickly. For that to happen vscode needs to propogate the shell resolution as noted in the above
# warning.

# Give users a way to override FZF_DEFAULT_OPTS. Setting FZF_DEFAULT_OPTS won't work since it will
# get overwritten by my fish configuration.
if set --export --query BIGOLU_FZF_DEFAULT_OPTS
    set --export FZF_DEFAULT_OPTS "$BIGOLU_FZF_DEFAULT_OPTS"
end

set real_fzf
set fzf_commands (which -a fzf)
for command in $fzf_commands
    # I assume the real fzf command is the one that isn't a shebang script. I do this to
    # avoid an infinite loop that happens if I use fzf from my portable-home on my machine,
    # since there will be 2 fzf wrappers on the $PATH in that case. I canonicalize the path
    # to avoid symlinks.
    if test '#!' != "$(head -c 2 (readlink --canonicalize $command))"
        set real_fzf $command
        break
    end
end
if test -z "$real_fzf"
    if isatty stderr
        echo (set_color red)'Error: Unable to find the real fzf' >&2
    end
    exit 127
end

exec $real_fzf $argv
