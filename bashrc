# prompt
CONNECTBAR_DOWN=$'\u250C\u2500\u257C'
CONNECTBAR_UP=$'\u2514'
SPLITBAR=$'\u257E\u2500\u257C'
ARROW=$'>>>'
c_gray='\e[01;30m'
c_cyan='\e[0;36m'
c_reset='\e[0m'
# get current branch in git repo (from ezprompt.net)
function parse_git_branch() {
	BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
	if [ ! "${BRANCH}" == "" ]
	then
		STAT=`parse_git_dirty`
    echo -e "[${c_cyan}${BRANCH}${STAT}${c_gray}]$SPLITBAR"
	else
		echo ""
	fi
}
# get current status of git repo (from ezprompt.net)
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
PS1="${c_gray}$CONNECTBAR_DOWN\`parse_git_branch\`${c_gray}[${c_cyan}\u@\h${c_gray}]$SPLITBAR${c_gray}[${c_cyan}\w${c_gray}]${c_reset}
${c_gray}$CONNECTBAR_UP$ARROW ${c_reset}"

# PATH
export GOPATH="/usr/local/go/bin"
export COREUTILS_PATH="/usr/local/opt/coreutils/libexec/gnubin"
export RUST_PATH="$HOME/.cargo/bin"
export FZF_PATH="/usr/local/opt/fzf/bin"
export GLOBAL_NPM_PACKAGES="$HOME/node_modules/.bin"
export PATH="$COREUTILS_PATH:$PATH:$RUST_PATH:$SUMO_HOME:$GOPATH:$MYSQL_PATH:$PORT_PATH:$FZF_PATH:$GLOBAL_NPM_PACKAGES"

# MANPATH
export COREUTILS_MANPATH="/usr/local/opt/coreutils/libexec/gnuman"
export BASE_MANPATH="/usr/share/man:/usr/local/share/man:/usr/X11/share/man"
export MANPATH="$BASE_MANPATH:$MACPORTS_PATH:$COREUTILS_MANPATH"

# bash
export LESS="-Ri"
# Get MacOS to stop complaining that I'm not using ZSH
export BASH_SILENCE_DEPRECATION_WARNING=1
export VISUAL=vim
export EDITOR="$VISUAL"
# remove duplicates in bash history
export HISTCONTROL=ignoredups:erasedups
# use blinking bar for bash cursor
echo -ne '\033[5 q'
# bash_completion
# Tells bash_completion to source all completion sources in this directory
export BASH_COMPLETION_COMPAT_DIR="/usr/local/etc/bash_completion.d"
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"
# make tab cycle through commands after listing
bind 'Tab:menu-complete'
bind '"\e[Z":menu-complete-backward'
bind "set show-all-if-ambiguous on"
bind "set completion-ignore-case on"
bind "set menu-complete-display-prefix on"
# aliases
alias r="source ~/.bashrc"
alias trash='trash -F '

# python
export VIRTUAL_ENV_DISABLE_PROMPT=1
export PYTHON_CONFIGURE_OPTS="--enable-framework"

# rg
export RG_DEFAULT_OPTIONS='--hidden --column --line-number --no-heading --fixed-strings --ignore-case --no-ignore \
    --glob "!{.cache,.git,*.log,*.plist,*.jpg,*.lock-info,.vscode,dist,package-lock.json,.DS_Store,node_modules}"'

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

# rust
# compile, run, and remove the binary
function rust() {
    name=$(basename $1 .rs)
    rustc $@ && ./$name && rm $name
}
