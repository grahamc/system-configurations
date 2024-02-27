# zsh will source both the rc and profile if the shell is login-interactive so we should only source
# the rc if the shell isn't interactive, to avoid sourcing it twice:
# https://zsh.sourceforge.io/Intro/intro_3.html
if [ ! -o interactive ] && [ -f ~/.zshrc ]; then
  . ~/.zshrc
fi
