vim.o.foldlevelstart = 99
vim.opt.fillchars:append("fold: ")
vim.o.foldtext = ""

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
vim.keymap.set(
  "n",
  "<S-Tab>",
  fold_toggle,
  { silent = true, expr = true, desc = "Toggle all folds [expand,collapse]" }
)
vim.keymap.set("n", "<Tab>", function()
  vim.cmd([[silent! normal! za]])
end, { desc = "Toggle fold [expand,collapse]" })

-- Jump to the top and bottom of the current fold
vim.keymap.set({ "n", "x" }, "[<Tab>", "[z", {
  desc = "Start of fold",
})
vim.keymap.set({ "n", "x" }, "]<Tab>", "]z", {
  desc = "End of fold",
})

local function SetDefaultFoldMethod()
  local is_foldmethod_overridable =
    not vim.tbl_contains({ "marker", "diff", "expr" }, vim.wo.foldmethod)
  if is_foldmethod_overridable then
    vim.wo.foldmethod = "indent"
  end
end
vim.api.nvim_create_autocmd("BufEnter", {
  callback = SetDefaultFoldMethod,
  group = vim.api.nvim_create_augroup("SetDefaultFoldMethod", {}),
})

local function maybe_set_treesitter_foldmethod()
  local is_foldmethod_overridable =
    not vim.tbl_contains({ "marker", "diff", "expr" }, vim.wo.foldmethod)

  if
    require("nvim-treesitter.parsers").has_parser()
    and is_foldmethod_overridable
  then
    vim.wo.foldmethod = "expr"
    vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
  end
end
vim.api.nvim_create_autocmd({ "BufEnter" }, {
  callback = maybe_set_treesitter_foldmethod,
  group = vim.api.nvim_create_augroup("TreesitterFoldmethod", {}),
})
