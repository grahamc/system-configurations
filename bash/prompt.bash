# prompt
# number of trailing directories to include in the current working directory
# ('\w' prompt escape sequence). All other directories will be replaced
# with '...'. For example, '/dir1/dir2/dir3/dir4' would be come '/.../dir3/dir4'
# if PROMPT_DIRTRIM is 2
PROMPT_DIRTRIM=2
CONNECTBAR_DOWN=$'\u250C\u257C'
CONNECTBAR_UP=$'\u2514'
SPLITBAR_LINE=$'\u2014'
LEFT_SPLITBAR=$'\u257E'
RIGHT_SPLITBAR=$'\u257C'
SPLITBAR=$"${LEFT_SPLITBAR}${RIGHT_SPLITBAR}"
ARROW=$'>>'
BORDER_COLOR="\[\033[0;30m\]"
TEXT_COLOR="\[\033[0;34m\]"
STANDOUT_TEXT_COLOR="\[\033[0;33m\]"
RESET_COLOR="\[\033[0m\]"
# get current branch in git repo (adapted from ezprompt.net)
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
# get current status of git repo (adapted from ezprompt.net)
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
function job_info() {
	local job_count_escape_sequence='\j'
	local job_count=${job_count_escape_sequence@P}
	if [ "$job_count" -gt '0' ]; then
		local job='job'
		if [ "$job_count" -gt '1' ]; then
			job="${job}s"
		fi
		echo "${BORDER_COLOR}[${TEXT_COLOR}${job_count} ${job}${BORDER_COLOR}]$SPLITBAR"
	else
		echo ''
	fi
}
function root_info() {
	local root_indicator_escape_sequence='\$'
	local root_indicator=${root_indicator_escape_sequence@P}
	if [ "$root_indicator" = '#' ]
	then
		echo "${BORDER_COLOR}${RIGHT_SPLITBAR}[${STANDOUT_TEXT_COLOR}warning: root${BORDER_COLOR}]${SPLITBAR_LINE}"
	else
		echo ''
	fi
}
function set_prompt() {
	PS1="${BORDER_COLOR}${CONNECTBAR_DOWN}$(python_info)$(git_info)$(job_info)$(user_info)$(path_info)\n${BORDER_COLOR}${CONNECTBAR_UP}$(root_info)${ARROW} ${RESET_COLOR}"
}
# We set the PS1 through PROMPT_COMMAND so that the PS1 will get reevaluated each time.
# It needs to be reevaluated each time so things like the git branch can get recalculated
PROMPT_COMMAND="set_prompt"
# call it now so that the code below references the correct prompt
set_prompt
