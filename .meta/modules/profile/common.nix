{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (specialArgs) hostName nix-index-database;
    inherit (import ../util.nix {inherit config lib;}) makeOutOfStoreSymlink;
  in
    {
      imports = [
        ../unit/login-shell.nix
        ../unit/fish.nix
        ../unit/nix.nix
        ../unit/neovim.nix
        ../unit/general.nix
        nix-index-database.hmModules.nix-index
      ];

      # Home Manager needs a bit of information about you and the
      # paths it should manage.
      home.username = "biggs";
      home.homeDirectory = "/home/biggs";

      # This lets me know which configuration is currently active (e.g. laptop, desktop) so I can reference it in
      # other programs. For example, I have a git hook that calls `switch` whenever any *.nix files change.
      home.sessionVariables.HOME_MANAGER_HOST_NAME = hostName;

      # The `man` in nixpkgs is only intended to be used for NixOS, it doesn't work properly on other OS's so I'm disabling
      # it. Since I'm not using the nixpkgs man, I have any packages I install their man outputs so my
      # system's `man` can find them.
      programs.man.enable = false;
      home.extraOutputsToInstall = [ "man" ];

      # This value determines the Home Manager release that your
      # configuration is compatible with. This helps avoid breakage
      # when a new Home Manager release introduces backwards
      # incompatible changes.
      #
      # You can update Home Manager without changing this value. See
      # the Home Manager release notes for a list of state version
      # changes in each release.
      home.stateVersion = "22.11";

      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;

      home.file = {
        ".dotfiles/.git/hooks/post-merge".source = makeOutOfStoreSymlink ".meta/git_file_watch/hooks/post-merge.sh";
        ".dotfiles/.git/hooks/post-rewrite".source = makeOutOfStoreSymlink ".meta/git_file_watch/hooks/post-rewrite.sh";
      };

      home.activation.printChanges = lib.hm.dag.entryAnywhere ''
        ${pkgs.nvd}/bin/nvd diff $oldGenPath $newGenPath
      '';

      # When switching generations, stop obsolete services and start ones that are wanted by active units.
      systemd.user.startServices = "sd-switch";
    }
