set -o errexit
set -o nounset
set -o pipefail

# Inputs, via shell (i.e. unexported) variables:
# ACTIVATION_PACKAGE
# BASH_PATH

if [ -t 2 ]; then
  printf 'Bootstrapping portable home...'
fi

prefix_directory="$(mktemp --tmpdir --directory 'bigolu_portable_home_XXXXX')"

# So we know where to find the prefix
export BIGOLU_PORTABLE_HOME_PREFIX="$prefix_directory"

# Clean up temporary directories when the shell exits
trap 'rm -rf "$prefix_directory"' SIGTERM ERR EXIT

function make_directory_in_prefix {
  local new_directory_basename="$1"

  local new_directory="$prefix_directory/$new_directory_basename"
  mkdir "$new_directory"
  printf '%s' "$new_directory"
}

xdg_state_directory="$(make_directory_in_prefix 'state')"
xdg_runtime_directory="$(make_directory_in_prefix 'runtime')"
xdg_cache_directory="$(make_directory_in_prefix 'cache')"

# Some packages need one of their XDG Base directories to be mutable so if the
# Nix store isn't writable we copy the directories into temporary ones.
activation_package_config_directory="$ACTIVATION_PACKAGE/home-files/.config"
activation_package_data_directory="$ACTIVATION_PACKAGE/home-files/.local/share"
if ! [ -w "$ACTIVATION_PACKAGE" ]; then
  xdg_config_directory="$(make_directory_in_prefix config)"
  xdg_data_directory="$(make_directory_in_prefix data)"
  cp --no-preserve=mode --recursive --dereference \
    "$activation_package_config_directory"/* "$xdg_config_directory"
  cp --no-preserve=mode --recursive --dereference \
    "$activation_package_data_directory"/* "$xdg_data_directory"
else
  xdg_config_directory="$activation_package_config_directory"
  xdg_data_directory="$activation_package_data_directory"

  # This way we have a reference to all the XDG base directories from the prefix
  ln --symbolic "$xdg_config_directory" "$(make_directory_in_prefix 'config')"
  ln --symbolic "$xdg_data_directory" "$(make_directory_in_prefix 'data')"
fi

function add_directory_to_path {
  local directory="$1"
  local new_directory_basename="$2"

  new_directory="$(make_directory_in_prefix "$new_directory_basename")"
  for program in "$directory"/*; do
    program_basename="$(basename "$program")"

    # The hashbangs in the scripts need to be the first two bytes in the file
    # for the kernel to recognize them so it must come directly after the
    # opening quote of the script.
    case "$program_basename" in
    env)
      # TODO: Wrapping this caused an infinite loop so I'll copy it instead. I
      # guess the interpreter I was using in the shebang was calling env
      # somehow.
      cp -L "$program" "$new_directory/env"
      ;;
    fish)
      printf >"$new_directory/$program_basename" '%s' "#!$BASH_PATH
# I unexport the XDG Base directories so host programs pick up the host's XDG directories.
XDG_CONFIG_HOME=$xdg_config_directory \
XDG_DATA_HOME=$xdg_data_directory \
XDG_STATE_HOME=$xdg_state_directory \
XDG_RUNTIME_DIR=$xdg_runtime_directory \
XDG_CACHE_HOME=$xdg_cache_directory \
BIGOLU_IN_PORTABLE_HOME=1 \
exec $program \
  --init-command 'set --unexport XDG_CONFIG_HOME' \
  --init-command 'set --unexport XDG_DATA_HOME' \
  --init-command 'set --unexport XDG_STATE_HOME' \
  --init-command 'set --unexport XDG_RUNTIME_DIR' \
  --init-command 'set --unexport XDG_CACHE_HOME' \
  \"\$@\""
      ;;
    *)
      printf >"$new_directory/$program_basename" '%s' "#!$BASH_PATH
XDG_CONFIG_HOME=$xdg_config_directory \
XDG_DATA_HOME=$xdg_data_directory \
XDG_STATE_HOME=$xdg_state_directory \
XDG_RUNTIME_DIR=$xdg_runtime_directory \
XDG_CACHE_HOME=$xdg_cache_directory \
BIGOLU_IN_PORTABLE_HOME=1 \
exec $program \"\$@\""
      ;;
    esac

    chmod +x "$new_directory/$program_basename"
  done

  export PATH="$new_directory:$PATH"
}

add_directory_to_path "$ACTIVATION_PACKAGE/home-path/bin" 'bin'
add_directory_to_path "$ACTIVATION_PACKAGE/home-files/.local/bin" 'bin-local'

# Set fish as the default shell
shell="$(which fish)"
export SHELL="$shell"

# Clear the message we printed earlier
if [ -t 2 ]; then
  printf '\33[2K\r'
fi

# WARNING: don't exec so our cleanup function can run
"$SHELL" "$@"
