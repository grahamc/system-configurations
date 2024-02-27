# If the profile is being sourced, the rc will not get sourced so we should source it:
# https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html
if [ -f ~/.bashrc ]; then
  # shellcheck disable=1090
  . ~/.bashrc
fi
