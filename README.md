# dotfiles
configs and whatnot

## Try it out
If you want to try out my dotfiles without modifying anything in your home directory you can do the following:
1. Create the directory where you want to store my dotfiles. e.g.
```
mkdir /tmp/dotfiles
```

2. Run the install script with a modified `$HOME` environment variable that points the directory we created in the last step. For example, if you are at the root of the repository run:
```
HOME=/tmp/dotfiles ./install/install
```
This way, the script will symlink all my dotfiles into that directory, thinking it's the home directory.

3. To try out the newly symlinked dotfiles, start a new interactive shell with same `$HOME` environment variable we used in the last step. If you do not use fish as your interactive shell, substitute fish in the following command with the shell you do use (bash, zsh, etc.):
```
HOME=/tmp/dotfiles fish
```
This way, all the commands you launch in this shell (vim, fzf, etc.) will think `/tmp/dotfiles` is the `$HOME` directory and look there for their configuration files. To exit this new shell, use control+d or the `exit` command.

4. To remove my dotfiles, just remove the directory!
