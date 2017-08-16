# prompt (ezprompt.net)
function parse_git_branch() {
	BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
	echo "${BRANCH}"
}
function line () {
    LINE=`printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -`
	echo "${LINE}"
}
PS1="\`line\`
╭─\`parse_git_branch\`\[\e[31m\]|\[\e[m\]\u@\h\[\e[31m\]|\[\e[m\]\w
╰🎸 "

# set PATH
export GOPATH="/usr/local/go/bin"
export COREUTILS_PATH="/usr/local/opt/coreutils/libexec/gnubin"
export MYSQL_PATH="/usr/local/mysql/bin"
export PORT_PATH="/opt/local/bin"
export SUMO_HOME="/opt/local/share/sumo"
export PATH="$SUMO_HOME:$COREUTILS_PATH:$GOPATH:$MYSQL_PATH:$PORT_PATH:$PATH"

# set other env vars
export COREUTILS_MANPATH="/usr/local/opt/coreutils/libexec/gnuman"
export MANPATH="$COREUTILS_MANPATH:$MANPATH"

# color shit
export TERM="screen-256color" # let tmux know shell supports 256 colors
eval `gdircolors ~/.solarized-dark-dircolors` # color ls output

# aliases
    # dircolors
    alias ls="ls --color=auto "
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    # misc
    alias la="ls -A"
    alias rm='trash-put'
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
