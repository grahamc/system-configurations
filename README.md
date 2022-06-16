# dotfiles
configs and whatnot

## Try it out
If you want to try out my dotfiles without modifying anything in your home directory you can do the following:
1. Create the directory where you want to store my dotfiles:
```
mkdir /tmp/dotfiles
```

2. Start a new interactive shell with a modified `$HOME` environment variable that points the directory we created in the last step. If you do not use fish as your interactive shell, substitute fish in the following command with the shell you do use (bash, zsh, etc.):
```
HOME=/tmp/dotfiles fish
```
This way, all the commands you launch in this shell (vim, fzf, etc.) will think `/tmp/dotfiles` is the `$HOME` directory and look there for their configuration files.

3. Run the install script. For example, if you are at the root of the repository run:
```
./install/install
```
The script will symlink all my dotfiles into the directory created in step 1, thinking that's the home directory. With everything linked you can now try it out. NOTE: During the install, you may be prompted to add configs outside of the home directory. Be sure to say no to those prompts if you don't want my dotfiles to be added anywhere besides the directory created in step 1.

4. To exit the new shell, try control+d or the `exit` command. To remove my dotfiles, just remove the directory.
