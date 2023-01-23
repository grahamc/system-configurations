#!/bin/sh

# Assign stdin, stdout, and stderr to the terminal
exec </dev/tty >/dev/tty 2>&1

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

# Contains each added/deleted/changed file. Each file is on its own line.
#
# Format:
# <status letter>    <filename relative to root of repo>
#
# For example, if the Brewfile was modified, this line would be present:
# M    brew/Brewfile
changed_filenames_with_status="$(git diff-tree -r --name-status ORIG_HEAD HEAD)"

# Exits with 0 if the specified file was added, deleted, or modified.
has_changes() {
  echo "$changed_filenames_with_status" | grep --extended-regexp --quiet "$1"
}

has_added_file() {
  echo "$changed_filenames_with_status" | grep --extended-regexp --quiet "^A"
}

has_deleted_file() {
  echo "$changed_filenames_with_status" | grep --extended-regexp --quiet "^D"
}

confirm() {
  printf "%s (y/n): " "$1"
  read -r answer
  [ "$answer" = 'y' ]
}

# With this, even if a command fails the script will continue
suppress_error() {
  "$@" || true
}

update_module() {
  suppress_error "${REPO_ROOT_DIR}/meta/install-module.bash" "$1"
}

main() {
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  REPO_ROOT_DIR="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel)"
  ACTIVE_PROFILE_PATH="${REPO_ROOT_DIR}/.active-profile"

  if ! [ -f "$ACTIVE_PROFILE_PATH" ]; then
    echo 'Not checking for updates since there is no active profile.'
    exit
  fi

  # If there are changes in a module, run the installer. If it has a 'special' handler then also use that.
  #
  # shellcheck disable=2013
  # I'm ok reading by word since that would be the same as reading by line in this case.
  for module in $(cat "$ACTIVE_PROFILE_PATH"); do
    if has_changes "${module}/*"; then
      update_module "$module"

      # You can't use '-' in a posix shell function name so I'm using '_' instead
      function_name="$(printf %s "$module" | tr '-' '_')"
      if command -V "$function_name" >/dev/null 2>&1; then
        "$function_name"
      fi
    fi
  done
}

asdf() {
  # NOTE: This should be the first check made because if the version for a tool changes to a version we do not have,
  # that tool will error out when you call it. This could be an issue because some of the checks below may depend on
  # these tools.
  tool_versions='asdf/tool-versions'
  if has_changes "$tool_versions"; then
    if confirm "The asdf tool version file has changed, would you like asdf to update from it?"; then
      suppress_error asdf install
    fi
  fi
}

neovim() {
  vim_plug_snapshot='neovim/vim-plug-snapshot.vim'
  if has_changes "$vim_plug_snapshot"; then
    if confirm "The neovim plugin snapshot has changed, would you like neovim to update from it?"; then
      suppress_error nvim -c 'autocmd VimEnter * PlugRestore' -c 'autocmd VimEnter * qall'
    fi
  fi
}

login_shell() {
  if has_changes 'bash/bash_profile'; then
    echo "The bash profile has changed. To apply these changes you can log out. Press enter to continue (This will not log you out)"

    # To hide any keys the user may press before enter I disable echo. After prompting them, I re-enable it.
    stty_original="$(stty -g)"
    stty -echo
    # I don't care if read mangles backslashes since I'm not using the input anyway.
    # shellcheck disable=2162
    read _unused
    stty "$stty_original"
  fi
}

fish() {
  fish_function_pattern='fish/functions/*'
  fish_conf_pattern='fish/conf.d/*'
  if has_changes "$fish_function_pattern" || has_changes "$fish_conf_pattern"; then
    if confirm "A fish configuration or function has changed, would you like to reload all fish shells?"; then
      suppress_error fish -c 'set --universal _fish_reload_indicator (random)'
    fi
  fi

  fish_plugins='fish/fish_plugins'
  if has_changes "$fish_plugins"; then
    if confirm "The fish plugin file has changed, would you like fisher to update from it?"; then
      suppress_error fish -c 'fisher update'
    fi
  fi
}

firefox() {
  firefox_pattern='firefox/*'
  if has_changes "$firefox_pattern"; then
    if confirm "A Firefox Developer Edition configuration has changed, would you like to reinstall it?"; then
      rm -rf /opt/firefox
      suppress_error ~/.dotfiles/firefox/install.sh
    fi
  fi
}

smart_plug() {
  smart_plug_pattern='smart-plug/*'
  if has_changes "$smart_plug_pattern"; then
    if confirm "A smart plug configuration has changed, would you like to reinstall it?"; then
      rm -rf /opt/smart-plug-daemon.d
      suppress_error ~/.dotfiles/smart-plug/install
    fi
  fi
}

blue='\e[34m'
reset='\e[0m'
banner_messsage='POST MERGE HOOK'
banner_underline="$(printf %40s '' | sed 's/ /─/g')"
printf "%b\n%s\n%s\n%b" "$blue" "$banner_messsage" "$banner_underline" "$reset"
printf "Checking to see if any actions should be taken as a result of the merge:\n\n"

main
