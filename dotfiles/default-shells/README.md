# Default shells

I'm hesitant to change the default shell on any OS because it seems like they rely on a certain shell being set. For example:

- This [GitHub gist that describes how the `$PATH` gets set on macOS][mac-path] mentions a utility called `path_helper` that is used to initialize the `$PATH`. A search for "path_helper" inside `/etc` and `/usr` on my machine (Sonoma 14.2.1) shows that `path_helper` is only run inside of shell configuration scripts for `csh` (`/etc/csh.login`), `zsh` (`/etc/zprofile`), and `bash`/`sh` (`/etc/profile`). Granted, `fish` includes [a configuration file that emulates `path_helper`][fish-path-helper], but there is always the possibility that it falls out of sync with the original `path_helper`.

- There's a [warning on the `fish` site against using it as the default shell][fish-default-warning] since it may cause issues with Linux distributions that depend on the default shell being Bourne-compatible.

Instead of changing the default shell, I do the following:

- I put all my login shell configuration in a single POSIX shell script ([login-config.sh][login-config]) and source that from the default shell. This works since both default shells that I have encountered (`bash` on Linux and `zsh` on macOS) have a POSIX shell compliance mode.

- I `exec` into `fish` if the shell is interactive, but since checking for interactive mode is shell-specific, I have to that write that logic that once per default shell.

I also set up the configuration files for the default shells to match the fish configuration model since I think it's easier to understand and work with:

- There is a single config file and if you want to do something for a specific "mode" (e.g. login, interactive) you can use a conditional.

- The config file is sourced after any vendor configs which gives you two advantages:

  - The user has the chance to override a vendor configuration.

  - Any entries prepended to a `$PATH`-like variable in the config file will precede, and therefore have precedence over, any entries added by a vendor configuration.

[mac-path]: https://gist.github.com/Linerre/f11ad4a6a934dcf01ee8415c9457e7b2
[login-config]: ./login-config.sh
[fish-path-helper]: https://github.com/fish-shell/fish-shell/blob/b77d1d0e2bebf4b2f6b28acf701d4c74c112e98e/share/config.fish#L164
[fish-default-warning]: https://fishshell.com/docs/current/index.html#default-shell
