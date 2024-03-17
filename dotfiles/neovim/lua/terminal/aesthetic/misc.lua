vim.o.linebreak = true
vim.o.breakat = " ^I"
vim.o.cursorline = true
vim.o.cursorlineopt = "number,screenline"
vim.o.wrap = true
-- chars to represent tabs and spaces when 'setlist' is enabled
vim.o.listchars = "tab:¬-,space:·"
vim.opt.fillchars:append("eob: ")

Plug("nvim-tree/nvim-web-devicons")

Plug("yamatsum/nvim-nonicons", {
  config = function()
    require("nvim-nonicons").setup({
      devicons = {
        override = false,
      },
    })
  end,
})
