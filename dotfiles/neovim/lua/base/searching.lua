vim.o.grepprg = vim.fn.executable("rg")

-- searching is only case-sensitive when the query contains an uppercase letter
vim.o.ignorecase = true
vim.o.smartcase = true

-- Search for selected text, forwards or backwards.
vim.keymap.set(
  { "v" },
  "*",
  [[:<C-U>let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>gvy/<C-R>=&ic?'\c':'\C'<CR><C-R><C-R>=substitute(escape(@", '/\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>gVzv:call setreg('"', old_reg, old_regtype)<CR>]],
  { silent = true }
)
vim.keymap.set(
  { "v" },
  "#",
  [[:<C-U>let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>gvy?<C-R>=&ic?'\c':'\C'<CR><C-R><C-R>=substitute(escape(@", '?\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>gVzv:call setreg('"', old_reg, old_regtype)<CR>]],
  { silent = true }
)

-- 'n' always searches forwards, 'N' always searches backwards
vim.keymap.set({ "n", "x", "o" }, "n", "'Nn'[v:searchforward]", { expr = true })
vim.keymap.set({ "n", "x", "o" }, "N", "'nN'[v:searchforward]", { expr = true })
