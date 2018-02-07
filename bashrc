# prompt (ezprompt.net)
function parse_git_branch() {
	BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
	echo "${BRANCH}"
}
PS1="\[\e[35m\]╭─\`parse_git_branch\`|\u@\h|\w\n╰\[\e[m\]"

# PATH
export GOPATH="/usr/local/go/bin"
export COREUTILS_PATH="/usr/local/opt/coreutils/libexec/gnubin"
export MYSQL_PATH="/usr/local/mysql/bin"
export PORT_PATH="/opt/local/bin"
export SUMO_HOME="/opt/local/share/sumo"
export RUST_PATH="$HOME/.cargo/bin"
export BASE_PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/TeX/texbin:/opt/X11/bin"
export PATH="$COREUTILS_PATH:$BASE_PATH:$RUST_PATH:$SUMO_HOME:$GOPATH:$MYSQL_PATH:$PORT_PATH"

# MANPATH
export COREUTILS_MANPATH="/usr/local/opt/coreutils/libexec/gnuman"
export MACPORTS_PATH="/opt/local/share/man"
export MANPATH="$MACPORTS_PATH:$COREUTILS_MANPATH"

# autocomplete
for f in /usr/local/etc/bash_completion.d/*; do source $f; done

# aliases
#shopt -s expand_aliases
alias ls="ls --color=auto "
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias la="ls -A"
alias rm='trash-put'
alias df='df -h'
alias du='du -h'
alias gpip3='PIP_REQUIRE_VIRTUALENV="" pip3'

# perform 'ls' after 'cd' if successful
cdls() {
  builtin cd "$*"
  RESULT=$?
  if [ "$RESULT" -eq 0 ]; then
    ls
  fi
}
alias cd='cdls'

# change colorscheme based on time of day
colorUpdate() {
    hour=`date +%H`
    lightTheme=''
    darkTheme=''

    # modify escape sequences if in a tmux session
    if [ -n "$TMUX" ]; then
        lightTheme='\033Ptmux;\033\033]50;SetColors=preset=Solarized Light\a\033\\'
        darkTheme='\033Ptmux;\033\033]50;SetColors=preset=Nord\a\033\\'
    else
        lightTheme='\033]50;SetColors=preset=Solarized Light\a'
        darkTheme='\033]50;SetColors=preset=Nord\a'
    fi
    
    if [ $hour -lt 18 ]; then
        echo -e "$lightTheme"
    else
        echo -e "$darkTheme"
    fi
}
alias color='colorUpdate'
colorUpdate

