# Default shells

Configuration files for the default shells on my machines.

## Why?

I use fish as my interactive shell, but I'm hesitant to change the default shell on any operating system because it seems like they rely on a certain shell being set. For example:

- This [GitHub gist that describes how the `$PATH` gets set on macOS][mac-path] mentions a utility called `path_helper` that is used to initialize the `$PATH`. A search for "path_helper" inside `/etc` and `/usr` on my machine (Sonoma 14.2.1) shows that `path_helper` is only run inside of shell configuration scripts for `csh` (`/etc/csh.login`), `zsh` (`/etc/zprofile`), and `bash`/`sh` (`/etc/profile`). Granted, `fish` includes [a configuration file that emulates `path_helper`][fish-path-helper], but there is always the possibility that it falls out of sync with the original `path_helper`.

- There's a [warning on the `fish` site against using it as the default shell][fish-default-warning] since it may cause issues with Linux distributions that depend on the default shell being Bourne-compatible.

Instead of changing the default shell, I made a configuration file for each of the default shells on the operating systems that I use. The config files `exec` into `fish` if the shell is interactive. You can find them in this directory.

[mac-path]: https://gist.github.com/Linerre/f11ad4a6a934dcf01ee8415c9457e7b2
[fish-path-helper]: https://github.com/fish-shell/fish-shell/blob/b77d1d0e2bebf4b2f6b28acf701d4c74c112e98e/share/config.fish#L164
[fish-default-warning]: https://fishshell.com/docs/current/index.html#default-shell
