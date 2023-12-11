{
  description = "Biggie's host configurations";

  nixConfig = {
    extra-substituters = "https://bigolu.cachix.org";
    extra-trusted-public-keys = "bigolu.cachix.org-1:AJELdgYsv4CX7rJkuGu5HuVaOHcqlOgR07ZJfihVTIw=";
  };

  # These names need to match the flake ID regex. The regex can be found here:
  # https://github.com/NixOS/nix/blob/ccaadc957593522e9b46336eb5afa45ff876f13f/src/libutil/url-parts.hh#L42
  #
  # There is also an issue open for relaxing the constraints in this regex: https://github.com/NixOS/nix/issues/7703
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-parts.url = "github:hercules-ci/flake-parts";
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
    gomod2nix = {
      url = "github:nix-community/gomod2nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    speakers = {
      url = "./dotfiles/smart_plug";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    vim-plugin-firenvim = {url = "github:glacambre/firenvim"; flake = false;};
    vim-plugin-vim-indentwise = {url = "github:jeetsukumaran/vim-indentwise"; flake = false;};
    vim-plugin-vim-matchup = {url = "github:andymass/vim-matchup"; flake = false;};
    vim-plugin-targets-vim = {url = "github:wellle/targets.vim"; flake = false;};
    vim-plugin-CamelCaseMotion = {url = "github:bkad/CamelCaseMotion"; flake = false;};
    vim-plugin-nvim-surround = {url = "github:kylechui/nvim-surround"; flake = false;};
    vim-plugin-vim-exchange = {url = "github:tommcdo/vim-exchange"; flake = false;};
    vim-plugin-vim-abolish = {url = "github:tpope/vim-abolish"; flake = false;};
    vim-plugin-vim-indent-object = {url = "github:michaeljsmith/vim-indent-object"; flake = false;};
    vim-plugin-dial-nvim = {url = "github:monaqa/dial.nvim"; flake = false;};
    vim-plugin-vim-signify = {url = "github:mhinz/vim-signify"; flake = false;};
    vim-plugin-nvim-autopairs = {url = "github:windwp/nvim-autopairs"; flake = false;};
    vim-plugin-vim-tmux-navigator = {url = "github:christoomey/vim-tmux-navigator"; flake = false;};
    vim-plugin-reticle-nvim = {url = "github:Tummetott/reticle.nvim"; flake = false;};
    vim-plugin-nvim-lastplace = {url = "github:ethanholz/nvim-lastplace"; flake = false;};
    vim-plugin-vim-plug = {url = "github:junegunn/vim-plug"; flake = false;};
    vim-plugin-traces-vim = {url = "github:markonm/traces.vim"; flake = false;};
    vim-plugin-nvim-treesitter-endwise = {url = "github:RRethy/nvim-treesitter-endwise"; flake = false;};
    vim-plugin-nvim-osc52 = {url = "github:ojroques/nvim-osc52"; flake = false;};
    vim-plugin-virt-column-nvim = {url = "github:lukas-reineke/virt-column.nvim"; flake = false;};
    vim-plugin-plenary-nvim = {url = "github:nvim-lua/plenary.nvim"; flake = false;};
    vim-plugin-telescope-nvim = {url = "github:nvim-telescope/telescope.nvim"; flake = false;};
    vim-plugin-dressing-nvim = {url = "github:stevearc/dressing.nvim"; flake = false;};
    vim-plugin-folding-nvim = {url = "github:pierreglaser/folding-nvim"; flake = false;};
    vim-plugin-which-key-nvim = {url = "github:folke/which-key.nvim"; flake = false;};
    vim-plugin-vim-repeat = {url = "github:tpope/vim-repeat"; flake = false;};
    vim-plugin-nvim-comment = {url = "github:terrortylor/nvim-comment"; flake = false;};
    vim-plugin-vim-sleuth = {url = "github:tpope/vim-sleuth"; flake = false;};
    vim-plugin-vim-fish = {url = "github:blankname/vim-fish"; flake = false;};
    vim-plugin-nvim-ts-autotag = {url = "github:windwp/nvim-ts-autotag"; flake = false;};
    vim-plugin-nvim-ts-context-commentstring = {url = "github:JoosepAlviste/nvim-ts-context-commentstring"; flake = false;};
    vim-plugin-nvim-lightbulb = {url = "github:kosayoda/nvim-lightbulb"; flake = false;};
    vim-plugin-cmp-omni = {url = "github:hrsh7th/cmp-omni"; flake = false;};
    vim-plugin-cmp-cmdline = {url = "github:hrsh7th/cmp-cmdline"; flake = false;};
    vim-plugin-cmp-cmdline-history = {url = "github:dmitmel/cmp-cmdline-history"; flake = false;};
    vim-plugin-cmp-tmux = {url = "github:andersevenrud/cmp-tmux"; flake = false;};
    vim-plugin-cmp-buffer = {url = "github:hrsh7th/cmp-buffer"; flake = false;};
    vim-plugin-cmp-nvim-lsp = {url = "github:hrsh7th/cmp-nvim-lsp"; flake = false;};
    vim-plugin-cmp-path = {url = "github:hrsh7th/cmp-path"; flake = false;};
    vim-plugin-cmp-nvim-lsp-signature-help = {url = "github:hrsh7th/cmp-nvim-lsp-signature-help"; flake = false;};
    vim-plugin-cmp-env = {url = "github:bydlw98/cmp-env"; flake = false;};
    vim-plugin-LuaSnip = {url = "github:L3MON4D3/LuaSnip"; flake = false;};
    vim-plugin-cmp_luasnip = {url = "github:saadparwaiz1/cmp_luasnip"; flake = false;};
    vim-plugin-friendly-snippets = {url = "github:rafamadriz/friendly-snippets"; flake = false;};
    vim-plugin-nvim-cmp = {url = "github:hrsh7th/nvim-cmp"; flake = false;};
    vim-plugin-mason-nvim = {url = "github:williamboman/mason.nvim"; flake = false;};
    vim-plugin-mason-lspconfig-nvim = {url = "github:williamboman/mason-lspconfig.nvim"; flake = false;};
    vim-plugin-nvim-lspconfig = {url = "github:neovim/nvim-lspconfig"; flake = false;};
    vim-plugin-SchemaStore-nvim = {url = "github:b0o/SchemaStore.nvim"; flake = false;};
    vim-plugin-none-ls-nvim = {url = "github:nvimtools/none-ls.nvim"; flake = false;};
    vim-plugin-vim = {url = "github:nordtheme/vim"; flake = false;};
    vim-plugin-vim-caser = {url = "github:arthurxavierx/vim-caser"; flake = false;};
    vim-plugin-czs-nvim = {url = "github:oncomouse/czs.nvim"; flake = false;};
    vim-plugin-nvim-tree-lua = {url = "github:kyazdani42/nvim-tree.lua"; flake = false;};
    vim-plugin-bufferline-nvim = {url = "github:akinsho/bufferline.nvim"; flake = false;};
    vim-plugin-fidget-nvim = {url = "github:j-hui/fidget.nvim"; flake = false;};
    vim-plugin-nvim-notify = {url = "github:rcarriga/nvim-notify"; flake = false;};
    vim-plugin-nui-nvim = {url = "github:MunifTanjim/nui.nvim"; flake = false;};
    vim-plugin-nvim-navic = {url = "github:SmiteshP/nvim-navic"; flake = false;};
    vim-plugin-git-blame-nvim = {url = "github:f-person/git-blame.nvim"; flake = false;};
    vim-plugin-vim-just = {url = "github:NoahTheDuke/vim-just"; flake = false;};
    tree-sitter-just = {url = "github:IndianBoy42/tree-sitter-just"; flake = false;};
    neodev-nvim = {url = "github:folke/neodev.nvim"; flake = false;};
    vim-plugin-aerial-nvim = {url = "github:stevearc/aerial.nvim"; flake = false;};
    vim-plugin-telescope-smart-history-nvim = {url = "github:nvim-telescope/telescope-smart-history.nvim"; flake = false;};
    vim-plugin-middleclass = {url = "github:anuvyklack/middleclass"; flake = false;};
    vim-plugin-animation-nvim = {url = "github:anuvyklack/animation.nvim"; flake = false;};
    vim-plugin-windows-nvim = {url = "github:anuvyklack/windows.nvim"; flake = false;};
    vim-plugin-ltex-extra-nvim = {url = "github:barreiroleo/ltex-extra.nvim"; flake = false;};
    vim-plugin-nvim-treesitter = {url = "github:nvim-treesitter/nvim-treesitter"; flake = false;};
    vim-plugin-sqlite-lua = {url = "github:kkharji/sqlite.lua"; flake = false;};
    vim-plugin-telescope-fzf-native = {url = "github:nvim-telescope/telescope-fzf-native.nvim"; flake = false;};
    vim-plugin-markdown-preview-nvim = {url = "github:iamcco/markdown-preview.nvim"; flake = false;};
    vim-plugin-actions-preview-nvim = {url = "github:aznhe21/actions-preview.nvim"; flake = false;};

    tmux-plugin-resurrect = {url = "github:tmux-plugins/tmux-resurrect"; flake = false;};
    tmux-plugin-tmux-suspend = {url = "github:MunifTanjim/tmux-suspend"; flake = false;};
    tmux-plugin-better-mouse-mode = {url = "github:NHDaly/tmux-better-mouse-mode"; flake = false;};
    tmux-plugin-mode-indicator = {url = "github:MunifTanjim/tmux-mode-indicator"; flake = false;};
    tmux-plugin-continuum = {url = "github:tmux-plugins/tmux-continuum"; flake = false;};

    fish-plugin-autopair-fish = {url = "github:jorgebucaran/autopair.fish"; flake = false;};
    fish-plugin-async-prompt = {url = "github:acomagu/fish-async-prompt"; flake = false;};
    fish-plugin-completion-sync = {url = "github:pfgray/fish-completion-sync"; flake = false;};
    fish-plugin-done = {url = "github:franciscolourenco/done"; flake = false;};
  };

  outputs = inputs@{ flake-parts, flake-utils, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./flake-modules/cache.nix
        ./flake-modules/nix-darwin
        ./flake-modules/overlay.nix
        ./flake-modules/shell
        ./flake-modules/bundler
        ./flake-modules/home-manager
        ./flake-modules/lib.nix
        ./flake-modules/assign-inputs-to-host-managers.nix
      ];

      systems = with flake-utils.lib.system; [
        x86_64-linux
        x86_64-darwin
      ];
    };
}
