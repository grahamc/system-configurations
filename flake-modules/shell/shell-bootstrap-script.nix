{
  mktemp,
  copy,
  chmod,
  fish,
  coreutilsBinaryPath,
  basename,
  which,
  foreignEnvFunctionPath,
  activationPackage,
}:
  ''#!${fish}

  # For packages that need one of their XDG Base directories to be mutable
  set -g mutable_bin (${mktemp} --directory)
  set -g state_dir (${mktemp} --directory)
  set -g config_dir (${mktemp} --directory)
  set -g data_dir (${mktemp} --directory)
  set -g runtime_dir (${mktemp} --directory)
  set -g cache_dir (${mktemp} --directory)

  # Clean up temporary directories when the shell exits
  function _cleanup --on-event fish_exit \
  --inherit-variable mutable_bin \
  --inherit-variable state_dir \
  --inherit-variable config_dir \
  --inherit-variable data_dir \
  --inherit-variable runtime_dir \
  --inherit-variable cache_dir
    rm -rf "$mutable_bin" "$state_dir" "$config_dir" "$data_dir" "$runtime_dir" "$cache_dir"
  end

  # Make mutable copies of the contents of any XDG Base Directory in the Home Manager configuration.
  # This is because some programs need to be able to write to one of these directories e.g. `fish`.
  ${copy} --no-preserve=mode --recursive --dereference ${activationPackage}/home-files/.config/* ''$config_dir
  ${copy} --no-preserve=mode --recursive --dereference ${activationPackage}/home-files/.local/share/* ''$data_dir

  for program in ${activationPackage}/home-path/bin/*
    set base (${basename} ''$program)

    # NOTE: The hashbangs in the scripts need to be the first two bytes in the file for the kernel to
    # recognize them so it must come directly after the opening quote of the script.
    switch "$base"
      case env
        # TODO: Wrapping this caused an infinite loop so I'll copy it instead
        ${copy} -L ''$program ''$mutable_bin/env
      case fish
        echo -s >''$mutable_bin/''$base "#!${fish}
          # I unexport the XDG Base directories so host programs pick up the host's XDG directories.
          XDG_CONFIG_HOME=''$config_dir XDG_DATA_HOME=''$data_dir XDG_STATE_HOME=''$state_dir XDG_RUNTIME_DIR=''$runtime_dir XDG_CACHE_HOME=''$cache_dir \
          ''$program \
            --init-command 'set --unexport XDG_CONFIG_HOME' \
            --init-command 'set --unexport XDG_DATA_HOME' \
            --init-command 'set --unexport XDG_STATE_HOME' \
            --init-command 'set --unexport XDG_RUNTIME_DIR' \
            --init-command 'set --unexport XDG_CACHE_HOME_DIR' \
            " ' ''$argv'
      case '*'
        echo -s >''$mutable_bin/''$base "#!${fish}
          XDG_CONFIG_HOME=''$config_dir XDG_DATA_HOME=''$data_dir XDG_STATE_HOME=''$state_dir XDG_RUNTIME_DIR=''$runtime_dir XDG_CACHE_HOME=''$cache_dir \
          ''$program" ' ''$argv'
    end

    ${chmod} +x ''$mutable_bin/''$base
  end

  # My login shell .profile sets the LOCALE_ARCHIVE for me, but it sets it to
  # <profile_path>/lib/locale/locale-archive and I won't have that in a 'sealed' environment so instead
  # I will source the Home Manager setup script because it sets the LOCALE_ARCHIVE to the path of the
  # archive in the Nix store.
  set --prepend fish_function_path ${foreignEnvFunctionPath}
  PATH="${coreutilsBinaryPath}:''$PATH" fenv source ${activationPackage}/home-path/etc/profile.d/hm-session-vars.sh >/dev/null
  set -e fish_function_path[1]

  fish_add_path --global --prepend ''$mutable_bin
  fish_add_path --global --prepend ${activationPackage}/home-files/.local/bin

  # Set fish as the default shell
  set --global --export SHELL (${which} fish)

  # Compile my custom themes for bat.
  chronic bat cache --build

  ''$SHELL ''$argv
  ''

