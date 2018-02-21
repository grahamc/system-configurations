# prompt (ezprompt.net)
function parse_git_branch() {
	BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
    echo "${BRANCH}"
}
PS1="\[\e[32m\]╭─\[\e[m\]\`parse_git_branch\`\[\e[35m\]|\[\e[m\]\u@\h\[\e[34m\]|\[\e[m\]\w\n\[\e[32m\]╰\[\e[m\]"

# PATH
export GOPATH="/usr/local/go/bin"
export COREUTILS_PATH="/usr/local/opt/coreutils/libexec/gnubin"
export MYSQL_PATH="/usr/local/mysql/bin"
export PORT_PATH="/opt/local/bin"
export SUMO_HOME="/opt/local/share/sumo"
export RUST_PATH="$HOME/.cargo/bin"
export FZF_PATH="/usr/local/opt/fzf/bin"
export BASE_PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/TeX/texbin:/opt/X11/bin"
export PATH="$COREUTILS_PATH:$BASE_PATH:$RUST_PATH:$SUMO_HOME:$GOPATH:$MYSQL_PATH:$PORT_PATH:$FZF_PATH"

# MANPATH
export COREUTILS_MANPATH="/usr/local/opt/coreutils/libexec/gnuman"
export MACPORTS_PATH="/opt/local/share/man"
export BASE_MANPATH="/usr/share/man:/usr/local/share/man:/usr/X11/share/man"
export MANPATH="$BASE_MANPATH:$MACPORTS_PATH:$COREUTILS_MANPATH"

# other env vars
export NIGHT_START=17
export DAY_START=7
export LESS="-Ri"
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --glob "!.git/*"\
    --glob "!venv/*" --glob "!node_modules/*"'
export FZF_CTRL_T_OPTS='--preview "head -100 {}" --prompt="rg>" --height 90% --margin=5%,2%,5%,2%'
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export VIRTUAL_ENV_DISABLE_PROMPT=1

# dircolors
eval `dircolors -b ~/.nord-dir-colors`

# autocomplete
for f in /usr/local/etc/bash_completion.d/*; do source $f; done
[[ $- == *i* ]] && source "/usr/local/opt/fzf/shell/completion.bash" 2> /dev/null

# keybindings
source "/usr/local/opt/fzf/shell/key-bindings.bash"
bind '"\C-f":" \C-u \C-a\C-k`__fzf_select__`\e\C-e\C-y\C-a\C-y\ey\C-h\C-e\ef \C-h"'

# pyenv init. use env var to prevent infinite loop
# see: https://github.com/pyenv/pyenv/issues/264#issuecomment-358490657
if [ -n "$PYENV_LOADING" ]; then
    true
else
    if which pyenv > /dev/null 2>&1; then
        export PYENV_LOADING="true"
        eval "$(pyenv init -)"
        eval "$(pyenv virtualenv-init -)"
        unset PYENV_LOADING
    fi
fi

# aliases
shopt -s expand_aliases
alias la='ls -A'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'
alias r='. ~/.bashrc'
alias ls='ls --color=auto -h -p'
alias rg='rg --smart-case'
alias c='clear'

# move file(s) to a trash directory
trash() {
    mv -f "$@" ~/.mytrash
}
alias trash='trash'

# empty trash
emptyTrash() {
    "rm" -rf ~/.mytrash/
    mkdir ~/.mytrash/
}
alias trash-empty='emptyTrash'

# perform 'ls' after 'cd' if successful
cdls() {
  builtin cd "$*"
  RESULT=$?
  if [ "$RESULT" -eq 0 ]; then
    ls
  fi
}
alias cd='cdls'

# export env var signifying if it is currently daytime
daytimeUpdate() {
    hour=`date +%H`
    
    if [ $hour -lt $NIGHT_START ] && [ $hour -gt $DAY_START ]; then
        export IS_DAYTIME=0
    else
        export IS_DAYTIME=0
    fi
}
daytimeUpdate

# change colorscheme based on time of day
lightTheme=''
darkTheme=''
if [ -n "$TMUX" ]; then
    lightTheme='\033Ptmux;\033\033]50;SetColors=preset=Solarized Light\a\033\\'
    darkTheme='\033Ptmux;\033\033]50;SetColors=preset=Nord\a\033\\'
else
    lightTheme='\033]50;SetColors=preset=Solarized Light\a'
    darkTheme='\033]50;SetColors=preset=Nord\a'
fi
if [ "$IS_DAYTIME" -eq "1" ]; then
   echo -e "$lightTheme"
else
   echo -e "$darkTheme"
fi 

# start in tmux
if [[ -z "$TMUX" ]]; then
    tmux attach -t random
fi

