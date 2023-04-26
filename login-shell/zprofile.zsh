if [ -f ~/.profile ]; then
  . ~/.profile
fi

if [ -f ~/.zshrc ]; then
  # Load zshrc if this shell is interactive
  if [[ -o interactive ]]; then
    . ~/.zshrc
  fi
fi
