# prompt (ezprompt.net)
function parse_git_branch() {
	BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
	echo "${BRANCH}"
}
PS1="\[\e[35m\]╭─\`parse_git_branch\`|\u@\h|\w\n╰\[\e[m\]"

# set PATH
export GOPATH="/usr/local/go/bin"
export COREUTILS_PATH="/usr/local/opt/coreutils/libexec/gnubin"
export MYSQL_PATH="/usr/local/mysql/bin"
export PORT_PATH="/opt/local/bin"
export SUMO_HOME="/opt/local/share/sumo"
export RUST_PATH="$HOME/.cargo/bin"
export BASE_PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/TeX/texbin:/opt/X11/bin"
export PATH="$COREUTILS_PATH:$BASE_PATH:$RUST_PATH:$SUMO_HOME:$GOPATH:$MYSQL_PATH:$PORT_PATH"

# set other env vars
export COREUTILS_MANPATH="/usr/local/opt/coreutils/libexec/gnuman"
export MACPORTS_PATH="/opt/local/share/man"
export MANPATH="$MACPORTS_PATH:$COREUTILS_MANPATH:$MANPATH"

# autocomplete
eval "`PIP_REQUIRE_VIRTUALENV="" pip3 completion --bash`"

# aliases
# dircolors
alias ls="ls --color=auto "
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
# misc
alias la="ls -A"
alias rm='trash-put'
alias c='clear'
# git
alias gp="git pull"
alias gs="git status"
alias gss="git status --short"
alias gc="git commit"
alias gitall="git add -A"
alias ga="git add"
alias gd="git diff"
# make
alias mc="make clean"
alias m="make"
# perform 'ls' after 'cd' if successful.
cdls() {
  builtin cd "$*"
  RESULT=$?
  if [ "$RESULT" -eq 0 ]; then
    ls
  fi
}
alias cd='cdls'
# disk space/usage
alias df='df -h'
alias du='du -h'
# python version
alias python='python3'
alias pip='pip3'
# global pip install
_gpip() {
    PIP_REQUIRE_VIRTUALENV="" pip3 "$@"
}
alias gpip='_gpip'
