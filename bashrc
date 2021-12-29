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
	if [ "$HOSTNAME" == "bigpop-os" ]; then
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
export PAGER="vim -c PAGER -"

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
alias r="source ~/.bashrc"
alias r-desktop-entries='update-desktop-database ~/.local/share/applications'
alias r-xbindkeys='killall xbindkeys; xbindkeys'
alias r-kitty='xdotool key Super+F5'
alias r-asdf='asdf reshim'
alias r-tmux='xdotool key ctrl+b key r'
alias r-tmux-plugins='xdotool key ctrl+b key I'
alias r-tmux-server='tmux kill-server; tmux'
alias r-tmux-pane='tmux respawn-pane -k'
alias trash='trash-put'
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
alias ls='ls --classify'
cdl() { cd "$@" && ls; }
alias tree='rg --color=never --files | \tree --fromfile  .'
# Quick way to reconnect to tmux after a restart/closed-terminal.
# This command connects to a running session, or if there isn't one, it just
# launches tmux, in which case tmux-resurrect should restore the entire tmux environment
alias reconnect='tmux a || tmux'
tunnel() { cloudflared tunnel run --url "http://localhost:$1"; }

# man
export MANPAGER="vim -c MANPAGER -"

#fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
bind '"\C-f":" \C-u \C-a\C-k`__fzf_select__`\e\C-e\C-y\C-a\C-y\ey\C-h\C-e\ef \C-h"'
export FZF_DEFAULT_COMMAND="rg --files"
export FZF_CTRL_T_OPTS='--preview "head -100 {}" --prompt="rg>" --height 90% --margin=5%,2%,5%,2%'
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_DEFAULT_OPTS='--bind tab:down,shift-tab:up'

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
