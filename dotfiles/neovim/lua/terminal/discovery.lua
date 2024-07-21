Plug("folke/which-key.nvim", {
  config = function()
    -- controls how long it takes which-key to pop up
    vim.o.timeout = true
    vim.o.timeoutlen = 500

    require("which-key").setup({
      keys = {
        scroll_down = "<c-j>",
        scroll_up = "<c-k>",
      },
      win = {
        height = {
          max = math.floor(vim.o.lines * 0.20),
        },
        border = { "─", "─", "─", " ", " ", " ", " ", " " },
      },
      icons = {
        separator = " ",
        mappings = false,
        colors = false,
      },
    })
  end,
})
