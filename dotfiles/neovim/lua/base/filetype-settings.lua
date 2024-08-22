-- vim:foldmethod=marker

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = ".envrc",
  callback = function()
    vim.opt_local.filetype = "sh"
  end,
  group = vim.api.nvim_create_augroup("Filetype Associations", {}),
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*/git/config",
  callback = function()
    vim.opt_local.filetype = "gitconfig"
  end,
})

-- For indentexpr
Plug("LnL7/vim-nix")

-- Tweak iskeyword {{{
local extend_is_keyword_group_id =
  vim.api.nvim_create_augroup("ExtendIskeyword", {})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "txt",
  callback = function()
    vim.opt_local.iskeyword:append("_")
  end,
  group = extend_is_keyword_group_id,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "sh",
  callback = function()
    vim.opt_local.iskeyword:append("-")
  end,
  group = extend_is_keyword_group_id,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "css",
    "scss",
    "javascriptreact",
    "typescriptreact",
    "javascript",
    "typescript",
    "sass",
    "postcss",
  },
  callback = function()
    vim.opt_local.iskeyword:append("-,?,!")
  end,
  group = extend_is_keyword_group_id,
})
-- }}}
