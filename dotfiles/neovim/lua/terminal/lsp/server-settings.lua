-- TODO: consider contributing some these settings to nvim-lspconfig

local M = {}

function M.get(on_attach)
  -- Inlay hint configuration came from here:
  -- https://github.com/simrat39/inlay-hints.nvim
  return {
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

    tsserver = {
      settings = {
        javascript = {
          inlayHints = {
            includeInlayEnumMemberValueHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
            includeInlayParameterNameHintsWhenArgumentMatchesName = true,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayVariableTypeHints = false,
          },
        },

        typescript = {
          inlayHints = {
            includeInlayEnumMemberValueHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
            includeInlayParameterNameHintsWhenArgumentMatchesName = true,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayVariableTypeHints = false,
          },
        },
      },
    },

    gopls = {
      settings = {
        gopls = {
          hints = {
            assignVariableTypes = true,
            compositeLiteralFields = true,
            compositeLiteralTypes = true,
            constantValues = true,
            functionTypeParameters = true,
            parameterNames = true,
            rangeVariableTypes = true,
          },
        },
      },
    },
  }
end

return M
