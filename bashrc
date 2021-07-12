# prompt (ezprompt.net)
function parse_git_branch() {
	BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
    [ -n "$BRANCH" ] && echo "${BRANCH}"
}
PS1="\[\e[33m\]╭─\[\e[m\]\[\e[37;41m\]\`parse_git_branch\`\[\e[m\]\[\e[37;44m\]\w\[\e[m\]
\[\e[33m\]╰\[\e[m\]🎸"

# PATH
export GOPATH="/usr/local/go/bin"
export COREUTILS_PATH="/usr/local/opt/coreutils/libexec/gnubin"
export MYSQL_PATH="/usr/local/mysql/bin"
export PORT_PATH="/opt/local/bin"
export SUMO_HOME="/opt/local/share/sumo"
export RUST_PATH="$HOME/.cargo/bin"
export FZF_PATH="/usr/local/opt/fzf/bin"
export PYENV_ROOT="$HOME/.pyenv"
export PYENV_BINARIES="$PYENV_ROOT/bin"
export GLOBAL_NPM_PACKAGES="$HOME/node_modules/.bin"
export PATH="$PYENV_BINARIES:$COREUTILS_PATH:$PATH:$RUST_PATH:$SUMO_HOME:$GOPATH:$MYSQL_PATH:$PORT_PATH:$FZF_PATH:$GLOBAL_NPM_PACKAGES"

# MANPATH
export COREUTILS_MANPATH="/usr/local/opt/coreutils/libexec/gnuman"
export MACPORTS_PATH="/opt/local/share/man"
export BASE_MANPATH="/usr/share/man:/usr/local/share/man:/usr/X11/share/man"
export MANPATH="$BASE_MANPATH:$MACPORTS_PATH:$COREUTILS_MANPATH"

# other env vars
export LESS="-Ri"
export FZF_RG_OPTIONS='--hidden --column --line-number --no-heading --fixed-strings \
    --ignore-case --no-ignore \
    --glob "!.git" \
    --glob "!.cache" \
    --glob "!*.log" \
    --glob "!*.plist" \
    --glob "!*.jpg" \
    --glob "!*.lock-info" \
    --glob "!.vscode" \
    --glob "!dist" \
    --glob "!package-lock.json" \
    --glob "!node_modules"'
export FZF_DEFAULT_COMMAND="rg $FZF_RG_OPTIONS --files"
export FZF_CTRL_T_OPTS='--preview "head -100 {}" --prompt="rg>" --height 90% --margin=5%,2%,5%,2%'
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_DEFAULT_OPTS='--bind tab:down,shift-tab:up'
export VIRTUAL_ENV_DISABLE_PROMPT=1
export PYTHON_CONFIGURE_OPTS="--enable-framework"
export NVM_DIR="$HOME/.nvm"
export BASH_SILENCE_DEPRECATION_WARNING=1

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
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # init
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # completion

#sdkman
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# aliases
alias grep='grep --color=auto'
alias ls='ls --color=auto'
alias la='ls -A'
alias df='df -h'
alias du='du -h'
alias r="source ~/.bashrc"
alias c='clear'
alias wp='pyenv which python'
alias youtube-mp3='youtube-dl -x --audio-format mp3 '
alias trash='trash -F '

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

# Check every minute if macos is in darkmode and update the iTerm theme accordingly.
# Also store an integer in '~/.darkmode' to signify the current mode. (1=darkmode, 0=lightmode)
# This way other programs, like vim, can easily check if darkmode is active and update their theme too.
set_theme() {
    CURRENT_MODE=''
    while :; do
        SYSTEM_THEME="$(defaults read -g AppleInterfaceStyle 2>/dev/null)"
        [ "$SYSTEM_THEME" = "Dark" ] && NEW_MODE='1' || NEW_MODE='0'

        if [ "$NEW_MODE" != "$CURRENT_MODE" ]; then
            CURRENT_MODE="$NEW_MODE" && echo -n "$NEW_MODE" > ~/.darkmode
            [[ "$NEW_MODE" -eq '0' ]] && newTheme='Solarized Light' || newTheme='Nord'

            setThemeEscapeSequence="\033]50;SetColors=preset=$newTheme\a"
            [ -n "$TMUX" ] && setThemeEscapeSequence="\033Ptmux;\033$setThemeEscapeSequence\033\a"
            echo -ne "$setThemeEscapeSequence"
        fi

        sleep 60
    done
}
# The last command on this line runs the theme checking function in the background. The prior commands
# are to verify that the os is macos, the terminal is iTerm, and that we have a mechanism in place to
# cleanup the background function once the session ends (via 'trap')
[[ "$OSTYPE" == "darwin"* ]] && [ "$TERM_PROGRAM" == "iTerm.app" ] && trap 'kill $(jobs -p); exit $?' INT TERM EXIT SIGHUP && set_theme &

# Fetch colors 
wget -nc -O ~/.dircolors 'https://raw.githubusercontent.com/arcticicestudio/nord-dircolors/develop/src/dir_colors' 2>/dev/null
eval "$(dircolors -b ~/.dircolors)"

# autocomplete
for f in /usr/local/etc/bash_completion.d/*; do source $f; done
