{
  mktemp,
  copy,
  chmod,
  fish,
  basename,
  which,
  activationPackage,
  # Not applicable to macOS
  localeArchive ? null,
}:
  let
    setLocaleArchive =
      if localeArchive == null
        then ""
        else "set --global --export LOCALE_ARCHIVE '${localeArchive}'";
  in
    ''#!${fish}

    set mutable_bin (${mktemp} --directory)
    set state_dir (${mktemp} --directory)
    set runtime_dir (${mktemp} --directory)
    set cache_dir (${mktemp} --directory)
    set config_dir ${activationPackage}/home-files/.config
    set data_dir ${activationPackage}/home-files/.local/share
    # Clean up temporary directories when the shell exits
    function _cleanup --on-event fish_exit
      rm -rf "$mutable_bin" "$state_dir" "$runtime_dir" "$cache_dir"
    end

    # Some packages need one of their XDG Base directories to be mutable so if the Nix store isn't writable we
    # copy the directories into temporary ones.
    if not test -w ${activationPackage}
      set config_dir (${mktemp} --directory)
      set data_dir (${mktemp} --directory)

      # Clean up temporary directories when the shell exits
      function _cleanup --on-event fish_exit
        rm -rf "$config_dir" "$data_dir"
      end

      # Make mutable copies of the contents of any XDG Base Directory in the Home Manager configuration.
      # This is because some programs need to be able to write to one of these directories e.g. `fish`.
      ${copy} --no-preserve=mode --recursive --dereference ${activationPackage}/home-files/.config/* ''$config_dir
      ${copy} --no-preserve=mode --recursive --dereference ${activationPackage}/home-files/.local/share/* ''$data_dir
    end

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
              --init-command 'set --unexport XDG_CACHE_HOME' \
              " ' ''$argv'
        case '*'
          echo -s >''$mutable_bin/''$base "#!${fish}
            XDG_CONFIG_HOME=''$config_dir XDG_DATA_HOME=''$data_dir XDG_STATE_HOME=''$state_dir XDG_RUNTIME_DIR=''$runtime_dir XDG_CACHE_HOME=''$cache_dir \
            ''$program" ' ''$argv'
      end

      ${chmod} +x ''$mutable_bin/''$base
    end

    ${setLocaleArchive}

    fish_add_path --global --prepend ''$mutable_bin
    fish_add_path --global --prepend ${activationPackage}/home-files/.local/bin

    # Set fish as the default shell
    set --global --export SHELL (${which} fish)

    # Compile my custom themes for bat.
    chronic bat cache --build

    exec ''$SHELL ''$argv </dev/tty >/dev/tty 2>&1
    ''

