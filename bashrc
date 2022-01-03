# If not running interactively, don't do anything.
# Reasoning is explained here: https://unix.stackexchange.com/questions/257571/why-does-bashrc-check-whether-the-current-shell-is-interactive
case $- in
    *i*) ;;
      *) return;;
esac

# prompt
CONNECTBAR_DOWN=$'\u250C\u2500\u257C'
CONNECTBAR_UP=$'\u2514'
SPLITBAR=$'\u257E\u2500\u257C'
ARROW=$'>>>'
BORDER_COLOR="\[\033[0;30m\]"
TEXT_COLOR="\[\033[0;36m\]"
RESET_COLOR="\[\033[0m\]"
# get current branch in git repo (from ezprompt.net)
function git_info() {
	BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
	if [ ! "${BRANCH}" == "" ]
	then
		STAT=`parse_git_dirty`
		echo "[${TEXT_COLOR}${BRANCH}${STAT}${BORDER_COLOR}]$SPLITBAR"
	else
		echo ""
	fi
}
# get current status of git repo (logic taken from ezprompt.net)
function parse_git_dirty {
	status=`git status 2>&1 | tee`
	dirty=`echo -n "${status}" 2> /dev/null | grep "modified:" &> /dev/null; echo "$?"`
	untracked=`echo -n "${status}" 2> /dev/null | grep "Untracked files" &> /dev/null; echo "$?"`
	ahead=`echo -n "${status}" 2> /dev/null | grep "Your branch is ahead of" &> /dev/null; echo "$?"`
	newfile=`echo -n "${status}" 2> /dev/null | grep "new file:" &> /dev/null; echo "$?"`
	renamed=`echo -n "${status}" 2> /dev/null | grep "renamed:" &> /dev/null; echo "$?"`
	deleted=`echo -n "${status}" 2> /dev/null | grep "deleted:" &> /dev/null; echo "$?"`
	bits=''
	if [ "${renamed}" == "0" ]; then
		bits=">${bits}"
	fi
	if [ "${ahead}" == "0" ]; then
		bits="*${bits}"
	fi
	if [ "${newfile}" == "0" ]; then
		bits="+${bits}"
	fi
	if [ "${untracked}" == "0" ]; then
		bits="?${bits}"
	fi
	if [ "${deleted}" == "0" ]; then
		bits="x${bits}"
	fi
	if [ "${dirty}" == "0" ]; then
		bits="!${bits}"
	fi
	if [ ! "${bits}" == "" ]; then
		echo " ${bits}"
	else
		echo ""
	fi
}
function python_info() {
	if [ -n "$VIRTUAL_ENV" ]
	then
		# We use the name of the directory that holds the virtual environment as the virtual environment name.
		# Unless the name of that directory is '.venv' in which case we'll use the name of the folder containing '.venv'
		[ `basename $VIRTUAL_ENV` == '.venv' ] && VIRTUAL_ENVIRONMENT_NAME=`echo $VIRTUAL_ENV  | sed -e "s/.*\/\([^/]*\)\/[^/]*/\1/"` || VIRTUAL_ENVIRONMENT_NAME=`basename $VIRTUAL_ENV`
		echo "${BORDER_COLOR}[${TEXT_COLOR}venv: ${VIRTUAL_ENVIRONMENT_NAME}${BORDER_COLOR}]$SPLITBAR"
	else
		echo ""
	fi
}
function user_info() {
	# If this is not an ssh session, then do not display the user info
	if [ -z "$SSH_CLIENT" ] && [ -z "$SSH_TTY" ]; then
		echo ""
	else
		echo "${BORDER_COLOR}[${TEXT_COLOR}\u@\h${BORDER_COLOR}]$SPLITBAR"
	fi
}
function path_info() {
		echo "${BORDER_COLOR}[${TEXT_COLOR}\w${BORDER_COLOR}]"
}
function set_prompt() {
	PS1="${BORDER_COLOR}${CONNECTBAR_DOWN}$(python_info)$(git_info)$(user_info)$(path_info)\n${BORDER_COLOR}${CONNECTBAR_UP}${ARROW} ${RESET_COLOR}"
}
# We set the PS1 through PROMPT_COMMAND so that the PS1 will get reevaluated each time.
# It needs to be reevaluated each time so things like the git branch can get recalculated
PROMPT_COMMAND="set_prompt"

# general
export PAGER='vim --not-a-term "+set filetype=PAGER" "+set nonumber" "+set norelativenumber" -c PAGER -'

# bash
export LESS="-Ri"
export VISUAL=vim
export EDITOR="$VISUAL"
# remove duplicates in bash history
export HISTCONTROL=ignoredups:erasedups
# use blinking bar for bash cursor
echo -ne '\033[5 q'
# enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
# make tab cycle through commands after listing
bind 'Tab:menu-complete'
bind '"\e[Z":menu-complete-backward'
bind "set show-all-if-ambiguous on"
bind "set completion-ignore-case on"
bind "set menu-complete-display-prefix on"
# aliases
source ~/complete_alias
make_alias_and_enable_autocomplete() {
	if [ $# -ne 2 ]; then
			echo -e "\e[31mError: Two arguments are required, the alias name and the command it should be expanded to. \nExample: make_alias_and_enable_autocomplete la 'ls -a'\e[m" >>/dev/stderr
	fi

	alias "$1"="$2"
	# If the function is defined, call it
	[[ "$(declare -fF _complete_alias)" ]] && complete -F _complete_alias "$1";
}
make_alias_and_enable_autocomplete 'r' "source ~/.bashrc"
make_alias_and_enable_autocomplete 'r-desktop-entries' 'update-desktop-database ~/.local/share/applications'
make_alias_and_enable_autocomplete 'r-xbindkeys' 'killall xbindkeys; xbindkeys'
make_alias_and_enable_autocomplete 'r-kitty' 'xdotool key Super+F5'
make_alias_and_enable_autocomplete 'r-asdf' 'asdf reshim'
make_alias_and_enable_autocomplete 'r-tmux' 'xdotool key ctrl+b key r'
make_alias_and_enable_autocomplete 'r-tmux-plugins' 'xdotool key ctrl+b key I'
make_alias_and_enable_autocomplete 'r-tmux-server' 'tmux kill-server; tmux'
make_alias_and_enable_autocomplete 'r-tmux-pane' 'tmux respawn-pane -k'
make_alias_and_enable_autocomplete 'trash' 'trash-put'
make_alias_and_enable_autocomplete 'pbcopy' 'xclip -selection clipboard'
make_alias_and_enable_autocomplete 'pbpaste' 'xclip -selection clipboard -o'
make_alias_and_enable_autocomplete 'ls' 'ls --classify'
cdl() { cd "$@" && ls; }
make_alias_and_enable_autocomplete 'tree' 'rg --color=never --files | \tree --fromfile  .'
# Quick way to reconnect to tmux after a restart/closed-terminal.
# This command connects to a running session, or if there isn't one, it just
# launches tmux, in which case tmux-resurrect should restore the entire tmux environment
make_alias_and_enable_autocomplete 'reconnect' 'tmux a || tmux'
tunnel() { cloudflared tunnel run --url "http://localhost:$1"; }
# do not show percentages or ascii bars
make_alias_and_enable_autocomplete 'dust' 'dust -b'
mktouch() { mkdir -p "$(dirname "$1")" && touch "$1" ; }
make_alias_and_enable_autocomplete 'sai' 'sudo apt install'
make_alias_and_enable_autocomplete 'sar' 'sudo apt remove'
make_alias_and_enable_autocomplete 'saar' 'sudo apt autoremove'
make_alias_and_enable_autocomplete 'ap' 'apt policy'

# man
export MANPAGER='vim --not-a-term "+set nonumber" "+set norelativenumber" -c MANPAGER -'

#fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
export FZF_DEFAULT_COMMAND="rg --files"
export FZF_CTRL_T_OPTS='--preview "head -100 {}" --prompt="(ctrl+e to open in $EDITOR)>" --height 90% --margin=5%,2%,5%,2% --bind "ctrl-e:execute($EDITOR {} > /dev/tty)+abort"'
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_DEFAULT_OPTS='--bind tab:down,shift-tab:up --color=bg+:black --layout=reverse'
export FZF_ALT_C_COMMAND="rg --files --null | xargs -0 dirname | sort -u"
export FZF_ALT_C_OPTS="--preview '\tree -C {} | head -200'"
# use control+space for history search (bindings taken from ~/.fzf.bash)
bind -m emacs-standard -x '"\C-@": __fzf_history__'
bind -m vi-command -x '"\C-@": __fzf_history__'
bind -m vi-insert -x '"\C-@": __fzf_history__'
# use control +f for directory search (bindings taken from ~/.fzf.bash)
bind -m emacs-standard '"\C-f": " \C-b\C-k \C-u`__fzf_cd__`\e\C-e\er\C-m\C-y\C-h\e \C-y\ey\C-x\C-x\C-d"'
bind -m vi-command '"\C-f": "\C-z\ec\C-z"'
bind -m vi-insert '"\C-f": "\C-z\ec\C-z"'
# use fzf to select a process to kill
fkill() {
    local pid
    if [ "$UID" != "0" ]; then
        pid=$(ps -f -u $UID | sed 1d | fzf -m | awk '{print $2}')
    else
        pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
    fi

    if [ "x$pid" != "x" ]
    then
        echo $pid | xargs kill -${1:-9}
    fi
}


# asdf
# Part of asdf initialization is adding shims. This means that if the bashrc
# gets reloaded, then asdf will add its shims again. This could be an issue if
# the bashrc gets reloaded while you're inside a python virtual environment
# since the asdf shims may override the virtual environment shims.
# To get around this, we make sure asdf is only initialized once by setting
# a variable after init and only initializing asdf if that variable doesn't exist.
if [ -z "$ASDF_INITIALIZED" ]; then
	# Init asdf. This needs to be done after the PATH has been set
	# and any frameworks, like oh-my-zsh, have been sourced
	source $HOME/.asdf/asdf.sh
	# configure completions
	source $HOME/.asdf/completions/asdf.bash
	# Export this variable so we can tell if asdf has been initialized
	export ASDF_INITIALIZED=1
fi

# python
export VIRTUAL_ENV_DISABLE_PROMPT=1

# rg
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# rust
# compile, run, and remove the binary
function rust() {
    name=$(basename $1 .rs)
    rustc $@ && ./$name && rm $name
}
