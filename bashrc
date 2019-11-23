# prompt (ezprompt.net)
function parse_git_branch() {
	BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
    echo "[${BRANCH}]"
}
PS1="\[\e[33m\]╭─\[\e[m\]\`parse_git_branch\`\w
\[\e[33m\]╰\[\e[m\]"

# PATH
export GOPATH="/usr/local/go/bin"
export COREUTILS_PATH="/usr/local/opt/coreutils/libexec/gnubin"
export MYSQL_PATH="/usr/local/mysql/bin"
export PORT_PATH="/opt/local/bin"
export SUMO_HOME="/opt/local/share/sumo"
export RUST_PATH="$HOME/.cargo/bin"
export FZF_PATH="/usr/local/opt/fzf/bin"
export PYENV_ROOT="$HOME/.pyenv"
export GLOBAL_NPM_PACKAGES="$HOME/node_modules/.bin"
export BASE_PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/TeX/texbin:/opt/X11/bin"
export PATH="$PYENV_ROOT/bin:$COREUTILS_PATH:$BASE_PATH:$RUST_PATH:$SUMO_HOME:$GOPATH:$MYSQL_PATH:$PORT_PATH:$FZF_PATH:$GLOBAL_NPM_PACKAGES"

# MANPATH
export COREUTILS_MANPATH="/usr/local/opt/coreutils/libexec/gnuman"
export MACPORTS_PATH="/opt/local/share/man"
export BASE_MANPATH="/usr/share/man:/usr/local/share/man:/usr/X11/share/man"
export MANPATH="$BASE_MANPATH:$MACPORTS_PATH:$COREUTILS_MANPATH"

# other env vars
export LESS="-Ri"
export FZF_RG_OPTIONS='--column --line-number --no-heading --fixed-strings \
    --ignore-case --no-ignore --hidden --glob "!.git/*" \
    --glob "!mozilla-unified/*" --glob "!.mozbuild/*" --glob "!venv/*" \
    --glob "!.pyenv/*" --glob "!Library/*" --glob "!.vim/*" --glob "!.tmux/*" \
    --glob "!.zeppelin/*" --glob "!.mytrash/*" --glob "!.npm/*" \
    --glob "!.vscode/*" --glob "!.cargo/*" --glob "!.rustup/*" \
    --glob "!Downloads/*" --glob "!node_modules/*" --glob "!doc/*"'
export FZF_DEFAULT_COMMAND="rg $FZF_RG_OPTIONS --files"
export FZF_CTRL_T_OPTS='--preview "head -100 {}" --prompt="rg>" --height 90% --margin=5%,2%,5%,2%'
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export VIRTUAL_ENV_DISABLE_PROMPT=1
export PYTHON_CONFIGURE_OPTS="--enable-framework"
export NVM_DIR="$HOME/.nvm"
export THEME_TYPE=0 vim # 0 = dark, 1 = light

# autocomplete
for f in /usr/local/etc/bash_completion.d/*; do source $f; done

#fzf
    # keybindings
    source "/usr/local/opt/fzf/shell/key-bindings.bash"
    bind '"\C-f":" \C-u \C-a\C-k`__fzf_select__`\e\C-e\C-y\C-a\C-y\ey\C-h\C-e\ef \C-h"'
    # completion
    [[ $- == *i* ]] && source "/usr/local/opt/fzf/shell/completion.bash" 2> /dev/null

# pyenv
    # use env var to prevent infinite loop on init
    # see: https://github.com/pyenv/pyenv/issues/264#issuecomment-358490657
    if [ -n "$PYENV_LOADING" ]; then
        true
    else
        if command -v pyenv > /dev/null 2>&1; then
            export PYENV_LOADING="true"
            eval "$(pyenv init -)"
            unset PYENV_LOADING
        fi
    fi

# nvm
    # init
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    # completion
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# aliases
alias la='ls -A'
alias grep='grep --color=auto'
alias ls='ls --color=auto'
alias df='df -h'
alias du='du -h'
alias r='. ~/.bashrc'
alias rg='rg --smart-case'
alias c='clear'
alias wp='pyenv which python'

# perform 'ls' after 'cd' if successful
cd() {
  builtin cd "$*"
  [ "$?" -eq 0 ] && ls
}

# compile, run, and remove the binary
function rust() {
    name=$(basename $1 .rs)
    rustc $@ && ./$name && rm $name
}

# auto load/create vim session
function vim() {
    # use the full path as a unique name for the session
    # replace '/' with '.' and append '.vim'
    VIM_SESSION_FILE="/Users/bigmac/.vim/sessions/$(echo $PWD | tr "/" .).vim"

    if test $# -gt 0; then
        env vim "$@"
    elif test -f "$VIM_SESSION_FILE"; then
        env vim -c "source $VIM_SESSION_FILE"
    else
        env vim -c "Obsession $VIM_SESSION_FILE"
    fi
}

eval "$(dircolors -b ~/.dircolors)"
# change colorscheme based on env var
lightTheme='\033]50;SetColors=preset=Solarized Light\a'
darkTheme='\033]50;SetColors=preset=Solarized Dark\a'
if [ -n "$TMUX" ]; then
    tmuxPrefix="\033Ptmux;\033"
    tmuxSuffix="\033\\"
    lightTheme="$tmuxPrefix$lightTheme$tmuxSuffix"
    darkTheme="$tmuxPrefix$darkTheme$tmuxSuffix"
fi
[[ "$THEME_TYPE" -eq "1" ]] && echo -e "$lightTheme" || echo -e "$darkTheme"
