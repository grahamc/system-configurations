Plug("folke/which-key.nvim", {
  config = function()
    -- controls how long it takes which-key to pop up
    vim.o.timeout = true
    vim.o.timeoutlen = 500

    require("which-key").setup({
      ignore_missing = false,
      popup_mappings = {
        scroll_down = "<c-j>",
        scroll_up = "<c-k>",
      },
      -- hide mapping boilerplate
      hidden = {
        "<silent>",
        "<cmd>",
        "<Cmd>",
        "<CR>",
        "call",
        "lua",
        "^:",
        "^ ",
        "<Plug>",
        "<plug>",
      },
      layout = {
        height = {
          max = math.floor(vim.o.lines * 0.20),
        },
        align = "center",
      },
      window = {
        border = { " ", " ", " ", " ", " ", " ", " ", " " },
        margin = { 1, 0.05, 2, 0.05 },
      },
      icons = {
        separator = " ",
      },
    })
  end,
})
