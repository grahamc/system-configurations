Plug("williamboman/mason.nvim", {
  config = function()
    require("mason").setup({
      ui = {
        width = 1,
        -- Ideally I'd use a function here so I could set it to '<screen_height> - 1', but this
        -- field doesn't support functions.
        height = 1,
        icons = {
          package_installed = "󰄳  ",
          package_pending = "  ",
          package_uninstalled = "󰝦  ",
        },
        keymaps = {
          toggle_package_expand = "<Tab>",
        },
      },
      log_level = vim.log.levels.DEBUG,
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "mason",
      callback = function()
        vim.b.minicursorword_disable = true
        vim.b.minicursorword_disable_permanent = true
      end,
      group = vim.api.nvim_create_augroup("MyMason", {}),
    })
    vim.api.nvim_create_user_command(
      "Extensions",
      vim.cmd.Mason,
      { desc = "Manage external tooling such as language servers" }
    )

    -- Store the number of packages that have an update available so I can put it in my statusline.
    local registry = require("mason-registry")
    local function maybe_set_update_flag(success, _)
      if success then
        _G.mason_update_available_count = _G.mason_update_available_count + 1
      end
    end
    local function set_mason_update_count()
      _G.mason_update_available_count = 0
      local packages = registry.get_installed_packages()
      for _, package in ipairs(packages) do
        package:check_new_version(maybe_set_update_flag)
      end
    end
    -- Update the registry first so we get the latest package versions.
    registry.update(function(was_successful, registry_sources_or_error)
      if not was_successful then
        vim.notify(
          "Failed to check for mason updates: " .. registry_sources_or_error,
          vim.log.levels.ERROR
        )
        return
      end
      set_mason_update_count()
    end)
    -- Set the count every time we update a package so it gets decremented accordingly.
    --
    -- TODO: This event also fires when a new package is installed, but we aren't interested in that
    -- event. This means we'll set the count more often than we need to.
    registry:on("package:install:success", vim.schedule_wrap(set_mason_update_count))
  end,
})

-- To read/write config files the way the vscode extension does.
Plug("barreiroleo/ltex-extra.nvim")

Plug("williamboman/mason-lspconfig.nvim", {
  config = function()
    require("mason-lspconfig").setup()
    local lspconfig = require("lspconfig")

    local on_attach = function(client, buffer_number)
      local methods = vim.lsp.protocol.Methods
      local buffer_keymap = vim.api.nvim_buf_set_keymap
      local keymap_opts = { noremap = true, silent = true }

      -- TODO: foldmethod is window-local, but I want to set it per buffer. Possible solution here:
      -- https://github.com/ii14/dotfiles/blob/e40d2b8316ec72b5b06b9e7a1d997276ff4ddb6a/.config/nvim/lua/m/opt.lua
      local foldmethod = vim.o.foldmethod
      local isFoldmethodOverridable = foldmethod ~= "marker" and foldmethod ~= "diff"
      if client.supports_method(methods.textDocument_foldingRange) and isFoldmethodOverridable then
        -- folding-nvim prints a message if any attached language server does not support folding so I'm suppressing
        -- that.
        vim.cmd([[silent lua require('folding').on_attach()]])
      end

      local filetype = vim.o.filetype
      local isKeywordprgOverridable = filetype ~= "vim"
      if client.supports_method(methods.textDocument_hover) and isKeywordprgOverridable then
        buffer_keymap(buffer_number, "n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", keymap_opts)

        -- Change border of documentation hover window, See https://github.com/neovim/neovim/pull/13998.
        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
          focusable = true,
          border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
        })
      end

      if client.supports_method(methods.textDocument_documentSymbol) then
        require("nvim-navic").attach(client, buffer_number)
      end
    end

    local cmp_lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()
    local folding_capabilities = {
      textDocument = {
        foldingRange = {
          dynamicRegistration = false,
          lineFoldingOnly = true,
        },
      },
    }
    local capabilities = vim.tbl_deep_extend("error", cmp_lsp_capabilities, folding_capabilities)

    local default_server_config = {
      capabilities = capabilities,
      on_attach = on_attach,
    }

    local server_specific_configs = {
      jsonls = {
        settings = {
          json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
          },
        },
      },

      lemminx = {
        settings = {
          xml = {
            catalogs = { "/etc/xml/catalog" },
          },
        },
      },

      vale_ls = {
        filetypes = {
          -- NOTE: This should have all the programming languages listed here:
          -- https://vale.sh/docs/topics/scoping/#code-1
          "c",
          "cs",
          "cpp",
          "css",
          "go",
          "haskell",
          "java",
          "javascript",
          "less",
          "lua",
          "perl",
          "php",
          "python",
          "r",
          "ruby",
          "sass",
          "scala",
          "swift",
        },
      },

      ltex = {
        on_attach = function(client, buffer_number)
          on_attach(client, buffer_number)
          require("ltex_extra").setup({
            load_langs = { "en-US" },
            -- For compatibility with the vscode extension
            path = ".vscode",
          })
        end,
        -- This should have file types for all the languages specified in `settings.ltex.enabled`
        filetypes = {
          "bib",
          "gitcommit", -- The LSP language ID is `git-commit`, but neovim uses `gitcommit`.
          "markdown",
          "org",
          "plaintex",
          "rst",
          "rnoweb",
          "tex",
          "pandoc",
          "quarto",
          "rmd",

          -- neovim gives plain text files the file type `text`, but ltex-ls only supports the LSP
          -- language ID for plain text, `plaintext`. However, since ltex-ls treats unsupported file
          -- types as plain text, it works out.
          "text",
        },
        settings = {
          ltex = {
            completionEnabled = true,
            enabled = {
              -- This block of languages should contain all the languages here:
              -- https://github.com/valentjn/ltex-ls/blob/1193c9959aa87b3d36ca436060447330bf735a9d/src/main/kotlin/org/bsplines/ltexls/parsing/CodeFragmentizer.kt
              "bib",
              "bibtex",
              "gitcommit", -- The LSP language ID is `git-commit`, but neovim uses `gitcommit`.
              "html",
              "xhtml",
              "context",
              "context.tex",
              "latex",
              "plaintex",
              "rsweave",
              "tex",
              "markdown",
              "nop",
              "org",
              "plaintext",
              "restructuredtext",

              -- neovim gives plain text files the file type `text`, but ltex-ls only supports
              -- the LSP language ID for plain text, `plaintext`. However, since ltex-ls treats
              -- unsupported file types as plain text, it works out.
              "text",
            },
          },
        },
      },
    }

    local server_config_handlers = {}
    -- Default handler to be called for each installed server that doesn't have a dedicated handler.
    server_config_handlers[1] = function(server_name)
      lspconfig[server_name].setup(default_server_config)
    end
    -- server-specific handlers
    for server_name, server_specific_config in pairs(server_specific_configs) do
      server_config_handlers[server_name] = function()
        lspconfig[server_name].setup(
          vim.tbl_deep_extend("force", default_server_config, server_specific_config)
        )
      end
    end
    require("mason-lspconfig").setup_handlers(server_config_handlers)

    -- Set the filetype of all the currently open buffers to trigger a 'FileType' event for each
    -- buffer so nvim_lsp has a chance to attach to any buffers that were openeed before it was
    -- configured. This way I can load nvim_lsp asynchronously.
    local buffer = vim.fn.bufnr()
    vim.cmd([[
        silent! bufdo silent! lua vim.o.filetype = vim.o.filetype
      ]])
    vim.cmd.b(buffer)
  end,
})

Plug("b0o/SchemaStore.nvim")
