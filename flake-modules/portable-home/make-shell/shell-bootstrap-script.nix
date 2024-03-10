{
  mktemp,
  mkdir,
  ln,
  copy,
  chmod,
  fish,
  sh,
  basename,
  which,
  activationPackage,
  # Not applicable to macOS
  localeArchive ? null,
}: let
  setLocaleArchive =
    if localeArchive == null
    then ""
    else "set --global --export LOCALE_ARCHIVE '${localeArchive}'";
in ''
  #!${fish}

  if isatty 2
    echo -n "Bootstrapping portable home..."
  end

  set prefix (${mktemp} --tmpdir --directory bigolu_portable_home_XXXXX)
  set --export BIGOLU_PORTABLE_HOME_PREFIX $prefix
  # Clean up temporary directories when the shell exits
  function _cleanup --on-event fish_exit
    rm -rf "$prefix"
  end

  function make_dir --argument-names name
    set path "$prefix/$name"
    ${mkdir} $path
    echo -n $path
  end

  set mutable_bin (make_dir bin)
  set state_dir (make_dir state)
  set runtime_dir (make_dir runtime)
  set cache_dir (make_dir cache)
  set config_dir ${activationPackage}/home-files/.config
  set data_dir ${activationPackage}/home-files/.local/share

  # Some packages need one of their XDG Base directories to be mutable so if the Nix store isn't writable we
  # copy the directories into temporary ones.
  if not test -w ${activationPackage}
    set config_dir (make_dir config)
    set data_dir (make_dir data)

    # Make mutable copies of the contents of any XDG Base Directory in the Home Manager configuration.
    # This is because some programs need to be able to write to one of these directories e.g. `fish`.
    ${copy} --no-preserve=mode --recursive --dereference ${activationPackage}/home-files/.config/* $config_dir
    ${copy} --no-preserve=mode --recursive --dereference ${activationPackage}/home-files/.local/share/* $data_dir
  else
    # This way we have a reference to all the XDG base directories from the prefix
    ${ln} --symbolic $config_dir $prefix/config
    ${ln} --symbolic $data_dir $prefix/data
  end

  for program in ${activationPackage}/home-path/bin/* ${activationPackage}/home-files/.local/bin/*
    set base (${basename} $program)

    # The hashbangs in the scripts need to be the first two bytes in the file for the kernel to
    # recognize them so it must come directly after the opening quote of the script.
    switch "$base"
      case env
        # TODO: Wrapping this caused an infinite loop so I'll copy it instead. I guess the interpreter I was using in the shebang was calling env somehow.
        ${copy} -L $program $mutable_bin/env
      case fish
        echo -s >$mutable_bin/$base "#!${sh}
          # I unexport the XDG Base directories so host programs pick up the host's XDG directories.
          XDG_CONFIG_HOME=$config_dir XDG_DATA_HOME=$data_dir XDG_STATE_HOME=$state_dir XDG_RUNTIME_DIR=$runtime_dir XDG_CACHE_HOME=$cache_dir BIGOLU_IN_PORTABLE_HOME=1 \
          exec $program \
            --init-command 'set --unexport XDG_CONFIG_HOME' \
            --init-command 'set --unexport XDG_DATA_HOME' \
            --init-command 'set --unexport XDG_STATE_HOME' \
            --init-command 'set --unexport XDG_RUNTIME_DIR' \
            --init-command 'set --unexport XDG_CACHE_HOME' \
            \"\$@\""
      case '*'
        echo -s >$mutable_bin/$base "#!${sh}
          XDG_CONFIG_HOME=$config_dir XDG_DATA_HOME=$data_dir XDG_STATE_HOME=$state_dir XDG_RUNTIME_DIR=$runtime_dir XDG_CACHE_HOME=$cache_dir BIGOLU_IN_PORTABLE_HOME=1 \
          exec $program \"\$@\""
    end

    ${chmod} +x $mutable_bin/$base
  end

  ${setLocaleArchive}

  # Though all these programs are inside mutable_bin, I need to have this on the $PATH because my
  # wrappers only work if they are on the $PATH. This is because of how they find the program they
  # are wrapping.
  fish_add_path --global --prepend ${activationPackage}/home-path/bin/
  fish_add_path --global --prepend ${activationPackage}/home-files/.local/bin

  fish_add_path --global --prepend $mutable_bin

  # Set fish as the default shell
  set --global --export SHELL (${which} fish)

  # So TMUX can set the right shell. When it executes my default-command it seems to reset $SHELL
  # first.
  set --export BIGOLU_PORTABLE_HOME_SHELL "$SHELL"

  # Compile my custom themes for bat.
  # I can't use chronic because I don't include moreutils in minimal shell
  bat cache --build >/dev/null

  # Clear the message we printed
  if isatty 2
    echo -en "\33[2K\r"
  end

  # WARNING: don't exec so our cleanup function can run
  $SHELL $argv
''
