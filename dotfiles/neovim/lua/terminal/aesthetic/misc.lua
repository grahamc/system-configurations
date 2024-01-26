vim.o.linebreak = true
vim.o.breakat = " ^I"
vim.o.cursorline = true
vim.o.cursorlineopt = "number,screenline"
vim.o.showtabline = 2
vim.o.wrap = true
-- chars to represent tabs and spaces when 'setlist' is enabled
vim.o.listchars = "tab:¬-,space:·"
vim.o.signcolumn = "yes:2"
vim.opt.fillchars:append("eob: ")
vim.o.termguicolors = false

Plug("nvim-tree/nvim-web-devicons")
