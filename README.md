# dotfiles
my shell setup

![alt text][vim-nerdtree]
![alt text][bash-prompt]


## requirements
\* = nice to have, but not necessary

- vimrc
  - folder for vim undo history (set to `~/.vim/undodir/`)
  - vim 8 or greater compiled with python 2 or 3 support - for YouCompleteMe and Ale
  - setup [YouCompleteMe][YouCompleteMe]
  - \* terminal with [truecolor support][truecolor-support] - allows for a light gray comment color in vim. defaults to yellow.
  - [nord colorscheme][nord-colorscheme] for terminal

- bashrc
  - should confirm everything is correctly configured

- tmux.conf
  - setup [tpm][tpm]




[vim-nerdtree]: https://github.com/bigolu/dotfiles/raw/master/img/vim-nerdtree.png "vim-nerdtree"
[bash-prompt]: https://github.com/bigolu/dotfiles/raw/master/img/bash-prompt.png "bash-prompt"

[truecolor-support]: https://gist.github.com/XVilka/8346728
[nord-colorscheme]: https://github.com/arcticicestudio/nord
[tpm]: https://github.com/tmux-plugins/tpm
[YouCompleteMe]: https://github.com/Valloric/YouCompleteMe
