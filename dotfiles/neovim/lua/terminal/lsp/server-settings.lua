-- TODO: consider contributing some these settings to nvim-lspconfig
--
-- Inlay hint configuration came from here:
-- https://github.com/simrat39/inlay-hints.nvim
--
-- The JSON/YAML configuration came from here:
-- https://www.arthurkoziel.com/json-schemas-in-neovim/

local M = {}

function M.get(on_attach)
  local catalog = "/etc/xml/catalog"

  return {
    jsonls = {
      settings = {
        json = {
          schemas = require("schemastore").json.schemas(),
          validate = { enable = true },
        },
      },
    },

    yamlls = {
      settings = {
        yaml = {
          schemas = require("schemastore").yaml.schemas(),
          -- For why this is needed see:
          -- https://github.com/b0o/SchemaStore.nvim?tab=readme-ov-file#usage
          schemaStore = {
            enable = false,
            url = "",
          },
        },
      },
    },

    -- It won't be on macOS
    lemminx = (vim.fn.filereadable(catalog) == 0) and {} or {
      settings = {
        xml = {
          catalogs = {
            catalog,
          },
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
  }
end

return M
