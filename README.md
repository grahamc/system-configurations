# dotfiles

configs and whatnot

## Requirements

- Debian-based Linux distribution (for example Ubuntu) -- for installing system dependencies with `apt-get`
- POSIX shell (`sh`)
- Bash -- for Dotbot
- Python 3.8+ -- for Dotbot

## Install

1. Run this command in your terminal:

    ``` sh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/bigolu/dotfiles/master/meta/install-from-remote.sh)"
    ```

2. Fonts:

    1. Download the following fonts and put them in `~/.local/share/fonts`: [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono), [Source Serif](https://github.com/adobe-fonts/source-serif), [Source Sans](https://github.com/adobe-fonts/source-sans), [Source Han Mono](https://github.com/adobe-fonts/source-han-mono), [Source Han Serif](https://github.com/adobe-fonts/source-han-serif), [Source Han Sans](https://github.com/adobe-fonts/source-han-sans), and [Symbols Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases) (Get both the 1000em-monospaced and 1000em-non-monospaced variants. Should be in `NerdFontsSymbolsOnly.zip`)

    2. Go to Gnome Tweaks and set the fonts to fontconfig aliases. This way Gnome will use the same fonts that are set in fontconfig. Settings: interface->sans, document->serif, monospace->monospace, and legacy->sans.

3. cloudflared:

    1. Put the following files in `~/.cloudflared/`:

        - `cert.pem` -- This file authenticates your instance of cloudflared, which allows you to perform privileged actions like creating and deleting tunnels. Not needed to run a tunnel.

        - tunnel credentials file -- A json file that allows you to use a particular tunnel.
