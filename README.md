# dotfiles

configs and whatnot

## Setup

1. Run the installation script. You can do so by entering the following command at the root of the repository.

    ``` sh
    ./install/install
    ```

2. Fonts:

    a. Download the following fonts and put them in `~/.local/share/fonts`: [Source Code Pro](https://github.com/adobe-fonts/source-code-pro), [Source Serif](https://github.com/adobe-fonts/source-serif), [Source Sans](https://github.com/adobe-fonts/source-sans), [Source Han Mono](https://github.com/adobe-fonts/source-han-mono), [Source Han Serif](https://github.com/adobe-fonts/source-han-serif), [Source Han Sans](https://github.com/adobe-fonts/source-han-sans), and [Symbols Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases) (Get both the 1000em-monospaced and 1000em-non-monospaced variants. Should be in `NerdFontsSymbolsOnly.zip`)

    b. Go to Gnome Tweaks and set the fonts to fontconfig aliases. This way Gnome will use the same fonts that are set in fontconfig. Settings: interface->sans, document->serif, monospace->monospace, and legacy->sans.

3. cloudflared:

    1. Put the following files in `~/.cloudflared/`:

        - `cert.pem` - This file authenticates your instance of cloudflared, which allows you to perform  privileged actions like creating and deleting tunnels. Not needed to run a tunnel.

        - tunnel credentials file -  A json file that allows you to use a particular tunnel.

## Try it out

If you want to try out my dotfiles without modifying anything in your home directory you can do the following:

1. Create the directory where you want to store my dotfiles:

    ``` sh
    mkdir /tmp/dotfiles
    ```

2. Start a new interactive shell with a modified `$HOME` environment variable that points the directory we created in the last step. If you do not use fish as your interactive shell, substitute fish in the following command with the shell you do use (bash, zsh, etc.):

    ``` sh
    HOME=/tmp/dotfiles fish
    ```

    This way, all the commands you launch in this shell (vim, fzf, etc.) will think `/tmp/dotfiles` is the `$HOME` directory and look there for their configuration files.

3. Run the installation script. For example, if you are at the root of the repository run:

    ``` sh
    ./install/install --only link
    ```

    The script will symlink all my dotfiles into the directory created in step 1, thinking that's the home directory. With everything linked you can now try it out.

4. To exit the new shell, try control+d, or the `exit` command. To remove my dotfiles, just remove the directory.
