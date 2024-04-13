-- I'm setting a winbar before dropbar loads so the editor window doesn't shift down when dropbar
-- loads.
vim.o.winbar = " "

vim.defer_fn(function()
  vim.fn["plug#load"]("dropbar.nvim")
end, 0)
Plug("Bekaboo/dropbar.nvim", {
  on = {},
  config = function()
    require("dropbar").setup({
      general = {
        update_interval = 100,
        -- I copied the default function and added a check for dapui
        enable = function(buf, win, _)
          local filetype = vim.bo[buf].filetype
          local is_dapui_buffer = vim.startswith(filetype, "dapui_")
            or filetype == "dap-repl"
          return not vim.api.nvim_win_get_config(win).zindex
            and (vim.bo[buf].buftype == "" or vim.bo[buf].buftype == "terminal")
            and vim.api.nvim_buf_get_name(buf) ~= ""
            and not vim.wo[win].diff
            and not is_dapui_buffer
        end,
      },

      bar = {
        -- default value, but with LSP and tree sitter removed
        sources = function(buf, _)
          local sources = require("dropbar.sources")
          if vim.bo[buf].ft == "markdown" then
            return {
              sources.path,
              sources.markdown,
            }
          end
          if vim.bo[buf].buftype == "terminal" then
            return {
              sources.terminal,
            }
          end
          return {
            sources.path,
          }
        end,
      },

      icons = {
        enable = false,
        ui = {
          bar = {
            separator = "",
          },
          menu = {
            indicator = "",
          },
        },
      },
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "dropbar_menu",
      callback = function()
        vim.b.minicursorword_disable = true
        vim.b.minicursorword_disable_permanent = true
      end,
    })
  end,
})
