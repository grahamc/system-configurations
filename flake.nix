{
  description = "Biggie's host configurations";

  nixConfig = {
    extra-substituters = "https://bigolu.cachix.org";
    extra-trusted-public-keys = "bigolu.cachix.org-1:AJELdgYsv4CX7rJkuGu5HuVaOHcqlOgR07ZJfihVTIw=";
  };

  outputs = inputs @ {
    flake-parts,
    flake-utils,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake
    {inherit inputs;}
    (
      {self, ...}: {
        imports = [
          ./flake-modules/cache.nix
          ./flake-modules/nix-darwin
          ./flake-modules/overlay
          ./flake-modules/portable-home
          ./flake-modules/bundler
          ./flake-modules/home-manager
          ./flake-modules/lib.nix
          ./flake-modules/assign-inputs-to-host-managers.nix
          ./flake-modules/smart-plug.nix
          ./flake-modules/dev-shell.nix
          ./flake-modules/bootstrap.nix
        ];

        systems = with flake-utils.lib.system; [
          x86_64-linux
          x86_64-darwin
        ];

        perSystem = {system, ...}: {
          _module.args.pkgs =
            import nixpkgs
            {
              inherit system;
              overlays = [self.overlays.default];
            };
        };
      }
    );

  # These names need to match the flake ID regex. The regex can be found here:
  # https://github.com/NixOS/nix/blob/ccaadc957593522e9b46336eb5afa45ff876f13f/src/libutil/url-parts.hh#L42
  #
  # There is also an issue open for relaxing the constraints in this regex:
  # https://github.com/NixOS/nix/issues/7703
  inputs = {
    stackline = {
      url = "github:AdamWagner/stackline";
      flake = false;
    };
    # TODO: I should do a sparse checkout to get the single Spoon I need.
    # issue: https://github.com/NixOS/nix/issues/5811
    spoons = {
      url = "github:Hammerspoon/Spoons";
      flake = false;
    };
    wezterm-terminfo = {
      url = "github:wez/wezterm";
      flake = false;
    };
    wezterm = {
      url = "github:wez/wezterm?dir=nix";
    };
    nixpkgs-for-wezterm-darwin.url = "github:nixos/nixpkgs?rev=ff0a5a776b56e0ca32d47a4a47695452ec7f7d80";
    # UNFREE
    # IMPURE
    # TODO: I think I can make its auto-detection pure by having the nixGL executable be a script
    # that reads /proc/driver at runtime, instead of at buildtime:
    # https://github.com/nix-community/nixGL/blob/489d6b095ab9d289fe11af0219a9ff00fe87c7c5/nixGL.nix#L225C14-L225C72
    nixgl = {
      url = "github:guibou/nixGL";
      # Per the readme, nixgl needs to use the same nixpkgs as the program it's wrapping:
      # https://github.com/nix-community/nixGL?tab=readme-ov-file#directly-run-nixgl
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix
    ########################################
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    nix-darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    nix-xdg = {
      url = "github:infinisil/nix-xdg";
      flake = false;
    };
    gomod2nix = {
      url = "github:nix-community/gomod2nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    flake-utils.url = "github:numtide/flake-utils";
    # TODO: I get an 'infinite recursion' error when I upgrade this
    flake-parts.url = "github:hercules-ci/flake-parts?rev=b253292d9c0a5ead9bc98c4e9a26c6312e27d69f";

    # tmux
    ########################################
    tmux = {
      url = "github:tmux/tmux";
      flake = false;
    };
    tmux-plugin-resurrect = {
      url = "github:tmux-plugins/tmux-resurrect";
      flake = false;
    };
    tmux-plugin-tmux-suspend = {
      url = "github:MunifTanjim/tmux-suspend";
      flake = false;
    };
    tmux-plugin-better-mouse-mode = {
      url = "github:NHDaly/tmux-better-mouse-mode";
      flake = false;
    };
    tmux-plugin-mode-indicator = {
      url = "github:MunifTanjim/tmux-mode-indicator";
      flake = false;
    };
    tmux-plugin-continuum = {
      url = "github:tmux-plugins/tmux-continuum";
      flake = false;
    };

    # fish
    ########################################
    fish-plugin-autopair-fish = {
      url = "github:jorgebucaran/autopair.fish";
      flake = false;
    };
    fish-plugin-async-prompt = {
      url = "github:acomagu/fish-async-prompt";
      flake = false;
    };
    fish-plugin-completion-sync = {
      url = "github:pfgray/fish-completion-sync";
      flake = false;
    };
    fish-plugin-done = {
      url = "github:franciscolourenco/done";
      flake = false;
    };

    # vim
    ########################################
    neodev-nvim = {
      url = "github:folke/neodev.nvim";
      flake = false;
    };
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
    };
    vim-plugin-firenvim = {
      url = "github:glacambre/firenvim";
      flake = false;
    };
    vim-plugin-vim-indentwise = {
      url = "github:jeetsukumaran/vim-indentwise";
      flake = false;
    };
    vim-plugin-vim-matchup = {
      url = "github:andymass/vim-matchup";
      flake = false;
    };
    vim-plugin-CamelCaseMotion = {
      url = "github:bkad/CamelCaseMotion";
      flake = false;
    };
    vim-plugin-vim-abolish = {
      url = "github:tpope/vim-abolish";
      flake = false;
    };
    vim-plugin-dial-nvim = {
      url = "github:monaqa/dial.nvim";
      flake = false;
    };
    vim-plugin-vim-signify = {
      url = "github:mhinz/vim-signify";
      flake = false;
    };
    vim-plugin-nvim-autopairs = {
      url = "github:windwp/nvim-autopairs";
      flake = false;
    };
    vim-plugin-vim-tmux-navigator = {
      url = "github:christoomey/vim-tmux-navigator";
      flake = false;
    };
    vim-plugin-reticle-nvim = {
      url = "github:Tummetott/reticle.nvim";
      flake = false;
    };
    vim-plugin-vim-plug = {
      url = "github:junegunn/vim-plug";
      flake = false;
    };
    vim-plugin-traces-vim = {
      url = "github:markonm/traces.vim";
      flake = false;
    };
    vim-plugin-nvim-treesitter-endwise = {
      url = "github:RRethy/nvim-treesitter-endwise";
      flake = false;
    };
    vim-plugin-virt-column-nvim = {
      url = "github:lukas-reineke/virt-column.nvim";
      flake = false;
    };
    vim-plugin-plenary-nvim = {
      url = "github:nvim-lua/plenary.nvim";
      flake = false;
    };
    vim-plugin-telescope-nvim = {
      url = "github:nvim-telescope/telescope.nvim";
      flake = false;
    };
    vim-plugin-dressing-nvim = {
      url = "github:stevearc/dressing.nvim";
      flake = false;
    };
    vim-plugin-which-key-nvim = {
      url = "github:folke/which-key.nvim";
      flake = false;
    };
    vim-plugin-vim-repeat = {
      url = "github:tpope/vim-repeat";
      flake = false;
    };
    vim-plugin-vim-sleuth = {
      url = "github:tpope/vim-sleuth";
      flake = false;
    };
    vim-plugin-vim-fish = {
      url = "github:blankname/vim-fish";
      flake = false;
    };
    vim-plugin-nvim-ts-autotag = {
      url = "github:windwp/nvim-ts-autotag";
      flake = false;
    };
    vim-plugin-nvim-lightbulb = {
      url = "github:kosayoda/nvim-lightbulb";
      flake = false;
    };
    vim-plugin-cmp-omni = {
      url = "github:hrsh7th/cmp-omni";
      flake = false;
    };
    vim-plugin-cmp-cmdline = {
      url = "github:hrsh7th/cmp-cmdline";
      flake = false;
    };
    vim-plugin-cmp-cmdline-history = {
      url = "github:dmitmel/cmp-cmdline-history";
      flake = false;
    };
    vim-plugin-cmp-tmux = {
      url = "github:andersevenrud/cmp-tmux";
      flake = false;
    };
    vim-plugin-cmp-buffer = {
      url = "github:hrsh7th/cmp-buffer";
      flake = false;
    };
    vim-plugin-cmp-nvim-lsp = {
      url = "github:hrsh7th/cmp-nvim-lsp";
      flake = false;
    };
    vim-plugin-cmp-path = {
      url = "github:hrsh7th/cmp-path";
      flake = false;
    };
    vim-plugin-cmp-nvim-lsp-signature-help = {
      url = "github:hrsh7th/cmp-nvim-lsp-signature-help";
      flake = false;
    };
    vim-plugin-cmp-env = {
      url = "github:bydlw98/cmp-env";
      flake = false;
    };
    vim-plugin-LuaSnip = {
      url = "github:L3MON4D3/LuaSnip";
      flake = false;
    };
    vim-plugin-cmp_luasnip = {
      url = "github:saadparwaiz1/cmp_luasnip";
      flake = false;
    };
    vim-plugin-friendly-snippets = {
      url = "github:rafamadriz/friendly-snippets";
      flake = false;
    };
    vim-plugin-nvim-cmp = {
      url = "github:hrsh7th/nvim-cmp";
      flake = false;
    };
    vim-plugin-mason-nvim = {
      url = "github:williamboman/mason.nvim";
      flake = false;
    };
    vim-plugin-mason-lspconfig-nvim = {
      url = "github:williamboman/mason-lspconfig.nvim";
      flake = false;
    };
    vim-plugin-nvim-lspconfig = {
      url = "github:neovim/nvim-lspconfig";
      flake = false;
    };
    vim-plugin-SchemaStore-nvim = {
      url = "github:b0o/SchemaStore.nvim";
      flake = false;
    };
    # Can go back to latest when they completely remove the deprecated sources. This is the commit
    # before they added the deprecation notice.
    # https://github.com/nvimtools/none-ls.nvim/issues/58
    vim-plugin-none-ls-nvim = {
      url = "github:nvimtools/none-ls.nvim?rev=bb680d752cec37949faca7a1f509e2fe67ab418a";
      flake = false;
    };
    vim-plugin-vim-caser = {
      url = "github:arthurxavierx/vim-caser";
      flake = false;
    };
    vim-plugin-czs-nvim = {
      url = "github:oncomouse/czs.nvim";
      flake = false;
    };
    vim-plugin-nvim-tree-lua = {
      url = "github:kyazdani42/nvim-tree.lua";
      flake = false;
    };
    vim-plugin-bufferline-nvim = {
      url = "github:akinsho/bufferline.nvim";
      flake = false;
    };
    vim-plugin-fidget-nvim = {
      url = "github:j-hui/fidget.nvim";
      flake = false;
    };
    vim-plugin-nvim-notify = {
      url = "github:rcarriga/nvim-notify";
      flake = false;
    };
    vim-plugin-git-blame-nvim = {
      url = "github:f-person/git-blame.nvim";
      flake = false;
    };
    vim-plugin-vim-just = {
      url = "github:NoahTheDuke/vim-just";
      flake = false;
    };
    vim-plugin-telescope-smart-history-nvim = {
      url = "github:nvim-telescope/telescope-smart-history.nvim";
      flake = false;
    };
    vim-plugin-nvim-treesitter = {
      url = "github:nvim-treesitter/nvim-treesitter";
      flake = false;
    };
    vim-plugin-sqlite-lua = {
      url = "github:kkharji/sqlite.lua";
      flake = false;
    };
    vim-plugin-telescope-fzf-native = {
      url = "github:nvim-telescope/telescope-fzf-native.nvim";
      flake = false;
    };
    vim-plugin-markdown-preview-nvim = {
      url = "github:iamcco/markdown-preview.nvim";
      flake = false;
    };
    vim-plugin-actions-preview-nvim = {
      url = "github:aznhe21/actions-preview.nvim";
      flake = false;
    };
    vim-plugin-nvim-web-devicons = {
      url = "github:nvim-tree/nvim-web-devicons";
      flake = false;
    };
    vim-plugin-mini-nvim = {
      url = "github:echasnovski/mini.nvim";
      flake = false;
    };
    vim-plugin-lush-nvim = {
      url = "github:rktjmp/lush.nvim";
      flake = false;
    };
    vim-plugin-nvim-colorizer-lua = {
      url = "github:mehalter/nvim-colorizer.lua";
      flake = false;
    };
    vim-plugin-dropbar-nvim = {
      url = "github:Bekaboo/dropbar.nvim";
      flake = false;
    };
    vim-plugin-legendary-nvim = {
      url = "github:mrjones2014/legendary.nvim";
      flake = false;
    };
    vim-plugin-smartcolumn-nvim = {
      url = "github:m4xshen/smartcolumn.nvim";
      flake = false;
    };
    vim-plugin-splitjoin-vim = {
      url = "github:AndrewRadev/splitjoin.vim";
      flake = false;
    };
    vim-plugin-treesj = {
      url = "github:Wansmer/treesj";
      flake = false;
    };
    vim-plugin-nvim-lsp-file-operations = {
      url = "github:antosha417/nvim-lsp-file-operations";
      flake = false;
    };
    vim-plugin-nvim-pqf = {
      url = "github:yorickpeterse/nvim-pqf";
      flake = false;
    };
    vim-plugin-telescope-menufacture = {
      url = "github:molecule-man/telescope-menufacture";
      flake = false;
    };
    vim-plugin-tree-sitter-just = {
      url = "github:IndianBoy42/tree-sitter-just";
      flake = false;
    };
    vim-plugin-cmp-dictionary = {
      url = "github:uga-rosa/cmp-dictionary";
      flake = false;
    };
    vim-plugin-telescope-sg = {
      url = "github:Marskey/telescope-sg";
      flake = false;
    };
    vim-plugin-conform-nvim = {
      url = "github:stevearc/conform.nvim";
      flake = false;
    };
    vim-plugin-nvim-treesitter-context = {
      url = "github:nvim-treesitter/nvim-treesitter-context";
      flake = false;
    };
    vim-plugin-vim-exchange = {
      url = "github:tommcdo/vim-exchange";
      flake = false;
    };
    vim-plugin-bullets-vim = {
      url = "github:bullets-vim/bullets.vim";
      flake = false;
    };
    vim-plugin-ltex-extra-nvim = {
      url = "github:barreiroleo/ltex_extra.nvim";
      flake = false;
    };
    vim-plugin-none-ls-shellcheck-nvim = {
      url = "github:gbprod/none-ls-shellcheck.nvim";
      flake = false;
    };
    vim-plugin-replacer-nvim = {
      url = "github:gabrielpoca/replacer.nvim";
      flake = false;
    };
  };
}
