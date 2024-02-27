# Default shells

I'm hesitant to change the default shell on any OS because I'm not sure if the OS relies on a certain shell being set. Instead, I put all my login shell configuration in a single POSIX shell script ([login-config.sh](./login-config.sh)) and source that from the default shell. I also `exec` into `fish` if the shell is interactive.

I also set up the configuration files for the default shells to match the fish configuration model since I think it's easier to understand and work with:

- There is a single config file and if you want to do something for a specific "mode" (e.g. login, interactive) you can use a conditional.

- The config file is sourced after any vendor configs which gives you two advantages:

  - The user has the chance to override a vendor configuration

  - Any entries added to a $PATH-like variable in the config file will precede, and therefore have precedence over, any entries added by a vendor configuration.
