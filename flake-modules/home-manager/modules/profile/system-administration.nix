{
  lib,
  pkgs,
  ...
}: let
  inherit (lib.lists) optionals;
  inherit (pkgs.stdenv) isLinux isDarwin;
  inherit (lib.attrsets) optionalAttrs;
in {
  imports = [
    ../git.nix
    ../fzf.nix
    ../direnv.nix
    ../wezterm.nix
    ../ripgrep-all.nix
  ];

  home.packages = with pkgs;
    [
      doggo
      duf
      fd
      gping
      jq
      lsd
      moreutils
      xdgWrappers.ripgrep
      tealdeer
      viddy
      zoxide
      file
      chase
      gnugrep
      broot
      hyperfine
      timg
      gzip
      wget
      which
      partialPackages.toybox
      partialPackages.xargs
      partialPackages.ps
      ast-grep
      less
      lesspipe
      diffoscope
      bat
      coreutils-full
      gnused
    ]
    ++ optionals isLinux [
      trashy
      pipr
      catp
      partialPackages.pstree
      cntr
    ]
    ++ optionals isDarwin [
      pstree
    ];

  xdg = {
    configFile = {
      "fish/conf.d/zoxide.fish".source = ''${
          pkgs.runCommand "zoxide-config.fish" {} "${pkgs.zoxide}/bin/zoxide init --no-cmd fish > $out"
        }'';

      # Taken from home-manager [1]. I'm doing this because home-manager was
      # bringing in the broot source code as a dependency. Dummy file to prevent
      # broot from trying to reinstall itself
      # [1]: https://github.com/nix-community/home-manager/blob/47c2adc6b31e9cff335010f570814e44418e2b3e/modules/programs/broot.nix#L151
      "broot" = {
        source = pkgs.writeTextDir "launcher/installed-v1" "";
        recursive = true;
      };

      "fish/conf.d/broot.fish".source = ''${
          pkgs.runCommand "broot.fish" {nativeBuildInputs = [pkgs.broot];}
          "broot --print-shell-function fish > $out"
        }'';
    };
  };

  repository = {
    symlink = {
      xdg.configFile =
        {
          "lsd".source = "lsd";
          "lesskey".source = "less/lesskey";
          "ripgrep/ripgreprc".source = "ripgrep/ripgreprc";
          "ssh/bootstrap.sh".source = "ssh/bootstrap.sh";
          "broot" = {
            source = "broot";
            recursive = true;
          };
          "bat/config".source = "bat/config";
        }
        // optionalAttrs isLinux {
          "pipr/pipr.toml".source = "pipr/pipr.toml";
          "fish/conf.d/pipr.fish".source = "pipr/pipr.fish";
        };

      # tealdeer stores files according to the XDG Base Directory spec[1] on
      # Linux and the Standard Directories guidelines[2] on macOS:
      # [1]: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
      # [2]: https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html#//apple_ref/doc/uid/TP40010672-CH2-SW6
      home.file = {
        "${
          if pkgs.stdenv.isLinux
          then ".config"
          else "Library/Application Support"
        }/tealdeer/config.toml".source = "tealdeer/config.toml";
        "${
          if pkgs.stdenv.isLinux
          then ".config"
          else "Library/Application Support"
        }/viddy.toml".source = "viddy/viddy.toml";
      };
    };
  };
}
