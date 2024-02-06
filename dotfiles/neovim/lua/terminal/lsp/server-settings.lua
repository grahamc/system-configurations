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
