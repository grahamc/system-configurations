Plug("Bekaboo/dropbar.nvim", {
  config = function()
    require("dropbar").setup({
      general = {
        update_interval = 100,
        -- I copied the default function and added a check for dapui
        enable = function(buf, win, _)
          local filetype = vim.bo[buf].filetype
          local is_dapui_buffer = vim.startswith(filetype, "dapui_") or filetype == "dap-repl"
          return not vim.api.nvim_win_get_config(win).zindex
            and (vim.bo[buf].buftype == "" or vim.bo[buf].buftype == "terminal")
            and vim.api.nvim_buf_get_name(buf) ~= ""
            and not vim.wo[win].diff
            and not is_dapui_buffer
        end,
      },

      icons = {
        kinds = {
          symbols = {
            Folder = " ",
          },
        },
        ui = {
          bar = {
            -- TODO: This isn't working for some reason
            separator = " ",
          },
        },
      },
    })
  end,
})
