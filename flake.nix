{
  description = "Biggs's host configurations";

  nixConfig = {
    extra-substituters = "https://bigolu.cachix.org";
    extra-trusted-public-keys = "bigolu.cachix.org-1:AJELdgYsv4CX7rJkuGu5HuVaOHcqlOgR07ZJfihVTIw=";
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # home-manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # bundler
    nix-appimage = {
      url = "github:ralismark/nix-appimage";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    nix-darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    # overlay
    "vim-plugin-vim-CursorLineCurrentWindow" = {url = "github:inkarkat/vim-CursorLineCurrentWindow"; flake = false;};
    "vim-plugin-virt-column.nvim" = {url = "github:lukas-reineke/virt-column.nvim"; flake = false;};
    "vim-plugin-folding-nvim" = {url = "github:pierreglaser/folding-nvim"; flake = false;};
    "vim-plugin-cmp-env" = {url = "github:bydlw98/cmp-env"; flake = false;};
    "vim-plugin-SchemaStore.nvim" = {url = "github:b0o/SchemaStore.nvim"; flake = false;};
    "vim-plugin-vim" = {url = "github:nordtheme/vim"; flake = false;};
    "vim-plugin-vim-caser" = {url = "github:arthurxavierx/vim-caser"; flake = false;};
    "tmux-plugin-resurrect" = {url = "github:tmux-plugins/tmux-resurrect"; flake = false;};
    "tmux-plugin-tmux-suspend" = {url = "github:MunifTanjim/tmux-suspend"; flake = false;};
    "fish-plugin-autopair-fish" = {url = "github:jorgebucaran/autopair.fish"; flake = false;};
    "fish-plugin-async-prompt" = {url = "github:acomagu/fish-async-prompt"; flake = false;};
    nix-xdg = {
      url = "github:infinisil/nix-xdg";
      flake = false;
    };
  };

  outputs = inputs@{ flake-parts, flake-utils, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./flake-modules/cache.nix
        ./flake-modules/nix-darwin.nix
        ./flake-modules/overlay.nix
        ./flake-modules/shell.nix
        ./flake-modules/bundler.nix
        ./flake-modules/home-manager.nix
      ];

      systems = with flake-utils.lib.system; [
        x86_64-linux
        x86_64-darwin
      ];

      flake =
        let
          inputSet = rec {
            home = [
              "nixpkgs"
              "flake-utils"
              "flake-parts"
              "home-manager"
              "nix-index-database"
              "nix-appimage"
              "vim-plugin-vim-CursorLineCurrentWindow"
              "vim-plugin-virt-column.nvim"
              "vim-plugin-folding-nvim"
              "vim-plugin-cmp-env"
              "vim-plugin-SchemaStore.nvim"
              "vim-plugin-vim"
              "vim-plugin-vim-caser"
              "tmux-plugin-resurrect"
              "tmux-plugin-tmux-suspend"
              "fish-plugin-autopair-fish"
              "fish-plugin-async-prompt"
              "nix-xdg"
            ];
            darwin = home ++ [
              "nix-darwin"
            ];
          };
          isInputListed = input:
            (builtins.elem input inputSet.home) || (builtins.elem input inputSet.darwin);
          inputNames = (nixpkgs.lib.lists.remove "self" (builtins.attrNames inputs));
          hasAllInputsListed = builtins.all isInputListed inputNames;
          convertInputsToUpdateFlags = inputNames:
            nixpkgs.lib.concatStringsSep
              " "
              (map (input: ''--update-input ${nixpkgs.lib.strings.escapeShellArgs [input]}'') inputNames);
          updateFlags = if hasAllInputsListed
            then
              nixpkgs.lib.mapAttrs
                (host-manager: inputNames: convertInputsToUpdateFlags inputNames)
                inputSet
            else
              abort "You need to specify when these inputs should be updated: ${nixpkgs.lib.concatStringsSep ", " (builtins.filter (input: !(isInputListed input)) inputNames)}";
        in
          {
            otherlib = {
              inherit updateFlags;
            };
          };
    };
}
