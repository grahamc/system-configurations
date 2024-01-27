vim.o.foldlevelstart = 99
vim.opt.fillchars:append("fold: ")
vim.o.foldtext = ""
vim.keymap.set("n", "<Tab>", function()
  vim.cmd([[silent! normal! za]])
end)

-- Setting this so that the fold column gets displayed
vim.o.foldenable = true

-- Set max number of nested folds when 'foldmethod' is 'syntax' or 'indent'
vim.o.foldnestmax = 1

-- Minimum number of lines a fold must have to be able to be closed
vim.o.foldminlines = 1

-- Fold visually selected lines. 'foldmethod' must be set to 'manual' for this work.
vim.keymap.set("x", "Tab", "zf")

-- Toggle opening and closing all folds
local function fold_toggle()
  if vim.o.foldlevel > 0 then
    return "zM"
  else
    return "zR"
  end
end
vim.keymap.set("n", "<S-Tab>", fold_toggle, { silent = true, expr = true })

-- Jump to the top and bottom of the current fold
vim.keymap.set({ "n", "x" }, "[<Tab>", "[z")
vim.keymap.set({ "n", "x" }, "]<Tab>", "]z")

local function SetDefaultFoldMethod()
  local foldmethod = vim.o.foldmethod
  local isFoldmethodOverridable = foldmethod ~= "marker"
    and foldmethod ~= "diff"
    and foldmethod ~= "expr"
  if isFoldmethodOverridable then
    vim.o.foldmethod = "indent"
  end
end
vim.api.nvim_create_autocmd("FileType", {
  callback = SetDefaultFoldMethod,
  group = vim.api.nvim_create_augroup("SetDefaultFoldMethod", {}),
})

-- Use folds provided by a language server
Plug("pierreglaser/folding-nvim")
