-- TODO: consider contributing some these settings to nvim-lspconfig

local M = {}

function M.get(on_attach)
  -- Inlay hint configuration came from here:
  -- https://github.com/simrat39/inlay-hints.nvim
  local settings = {
    jsonls = {
      settings = {
        json = {
          schemas = require("schemastore").json.schemas(),
          validate = { enable = true },
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

  local catalog = "/etc/xml/catalog"
  -- It won't be on macOS
  if vim.fn.filereadable(catalog) ~= 0 then
    vim.tbl_deep_extend("error", settings, {
      lemminx = { settings = { xml = { catalogs = { catalog } } } },
    })
  end

  return settings
end

return M
