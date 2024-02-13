vim.o.linebreak = true
vim.o.breakat = " ^I"
vim.o.cursorline = true
vim.o.cursorlineopt = "number,screenline"
vim.o.wrap = true
-- chars to represent tabs and spaces when 'setlist' is enabled
vim.o.listchars = "tab:¬-,space:·"
vim.opt.fillchars:append("eob: ")
vim.o.pumblend = 2

Plug("nvim-tree/nvim-web-devicons")

Plug("yamatsum/nvim-nonicons", {
  config = function()
    require("nvim-nonicons").setup({})
    -- Since nvim-web-devicons reloads when the background changes, I need to reapply the
    -- overrides
    vim.api.nvim_create_autocmd("OptionSet", {
      pattern = "background",
      callback = function()
        package.loaded["nvim-web-devicons.override"] = nil
        require("nvim-web-devicons.override")
      end,
      group = vim.api.nvim_create_augroup("bigolu/nvim-nonicons", {}),
    })
  end,
})
