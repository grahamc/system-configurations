if [ -f ~/.profile ]; then
  emulate sh -c '. ~/.profile'
  emulate zsh
fi

if [ -f ~/.zshrc ]; then
  # Load zshrc if this shell is interactive
  if [[ -o interactive ]]; then
    . ~/.zshrc
  fi
fi
