# prompt (ezprompt.net)
function parse_git_branch() {
    BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
    [ -n "$BRANCH" ] && echo -e "[${BRANCH}]⏤⏤ "
}
PS1="\[\e[34m\]╭─\`parse_git_branch\`[\w]\[\e[m\]
\[\e[34m\]╰\[\e[m\]"

# make tab cycle through commands after listing
bind 'Tab:menu-complete'
bind '"\e[Z":menu-complete-backward'
bind "set show-all-if-ambiguous on"
bind "set completion-ignore-case on"
bind "set menu-complete-display-prefix on"

# PATH
export GOPATH="/usr/local/go/bin"
export COREUTILS_PATH="/usr/local/opt/coreutils/libexec/gnubin"
export MYSQL_PATH="/usr/local/mysql/bin"
export PORT_PATH="/opt/local/bin"
export SUMO_HOME="/opt/local/share/sumo"
export RUST_PATH="$HOME/.cargo/bin"
export FZF_PATH="/usr/local/opt/fzf/bin"
export GLOBAL_NPM_PACKAGES="$HOME/node_modules/.bin"
export PATH="$COREUTILS_PATH:$PATH:$RUST_PATH:$SUMO_HOME:$GOPATH:$MYSQL_PATH:$PORT_PATH:$FZF_PATH:$GLOBAL_NPM_PACKAGES"

# MANPATH
export COREUTILS_MANPATH="/usr/local/opt/coreutils/libexec/gnuman"
export MACPORTS_PATH="/opt/local/share/man"
export BASE_MANPATH="/usr/share/man:/usr/local/share/man:/usr/X11/share/man"
export MANPATH="$BASE_MANPATH:$MACPORTS_PATH:$COREUTILS_MANPATH"

# system
export LESS="-Ri"
# Get MacOS to stop complaining that I'm not using ZSH
export BASH_SILENCE_DEPRECATION_WARNING=1

# python
export VIRTUAL_ENV_DISABLE_PROMPT=1
export PYTHON_CONFIGURE_OPTS="--enable-framework"

# rg
export RG_DEFAULT_OPTIONS='--hidden --column --line-number --no-heading --fixed-strings \
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
    --glob "!.DS_Store" \
    --glob "!node_modules"'

#fzf
source "/usr/local/opt/fzf/shell/key-bindings.bash"
bind '"\C-f":" \C-u \C-a\C-k`__fzf_select__`\e\C-e\C-y\C-a\C-y\ey\C-h\C-e\ef \C-h"'
export FZF_DEFAULT_COMMAND="rg $RG_DEFAULT_OPTIONS --files"
export FZF_CTRL_T_OPTS='--preview "head -100 {}" --prompt="rg>" --height 90% --margin=5%,2%,5%,2%'
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_DEFAULT_OPTS='--bind tab:down,shift-tab:up'

# asdf
# Init asdf. This needs to be done after the PATH has been set
# and any frameworks, like oh-my-zsh, have been sourced
source $(brew --prefix asdf)/libexec/asdf.sh
# set JAVA_HOME
source ~/.asdf/plugins/java/set-java-home.bash

# aliases
alias la='ls -A'
alias r="source ~/.bashrc"
alias youtube-mp3='youtube-dl -x --audio-format mp3 '
alias trash='trash -F '

# compile, run, and remove the binary
function rust() {
    name=$(basename $1 .rs)
    rustc $@ && ./$name && rm $name
}

# Check periodically if macos is in darkmode and update the iTerm theme accordingly.
colorscheme_sync_daemon() {
    while :; do
        SYSTEM_THEME="$(defaults read -g AppleInterfaceStyle 2>/dev/null)"
        [ "$SYSTEM_THEME" = "Dark" ] && NEW_MODE='1' || NEW_MODE='0'

        if [ "$NEW_MODE" != "$CURRENT_MODE" ]; then
            CURRENT_MODE="$NEW_MODE"
            [[ "$NEW_MODE" -eq '0' ]] && newTheme='Solarized Light' || newTheme='Nord'

            setThemeEscapeSequence="\033]50;SetColors=preset=$newTheme\a"
            [ -n "$TMUX" ] && setThemeEscapeSequence="\033Ptmux;\033$setThemeEscapeSequence\033\a"
            echo -ne "$setThemeEscapeSequence"
        fi

        sleep 5
    done
}
[[ "$OSTYPE" == "darwin"* ]] && [ "$TERM_PROGRAM" == "iTerm.app" ] && [ -z "$STARTED_BG" ] && colorscheme_sync_daemon & disown && THEME_PID="$!" && STARTED_BG="true" && trap "kill -9 $THEME_PID" EXIT

# bash_completion
# Tells bash_completion to source all completion sources in this directory
export BASH_COMPLETION_COMPAT_DIR="/usr/local/etc/bash_completion.d"
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"

# use blinking bar for bash cursor
# see: https://superuser.com/questions/361335/how-to-change-the-terminal-cursor-from-box-to-line
echo -ne '\033[5 q'
