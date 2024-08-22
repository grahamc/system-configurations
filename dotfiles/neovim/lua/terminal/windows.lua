-- open new horizontal and vertical panes to the right and bottom respectively
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.winminheight = 0
vim.o.winminwidth = 0
vim.keymap.set("n", '<C-\\>', vim.cmd.vsplit, {
  desc = "Vertical split",
})
vim.keymap.set("n", "<C-->", vim.cmd.split, {
  desc = "Horizontal split",
})

local window_group_id = vim.api.nvim_create_augroup("Window", {})

-- Automatically resize all splits to make them equal when the vim window is resized or a new window
-- is created/closed.
vim.api.nvim_create_autocmd({ "VimResized", "TabEnter" }, {
  callback = function()
    -- Don't equalize when vim is starting up so it doesn't reset the window sizes from my session.
    local is_vim_starting = vim.fn.has("vim_starting") == 1
    if is_vim_starting then
      return
    end
    vim.cmd.wincmd("=")
  end,
  group = window_group_id,
})
vim.api.nvim_create_autocmd({ "WinNew", "WinClosed" }, {
  callback = function()
    local amatch = vim.fn.expand("<amatch>")
    local id = tonumber(amatch)
    -- sometimes amatch is the file opened in the window
    if id == nil then
      return
    end
    -- Don't equalize splits if the new window is floating, it won't get resized anyway.
    local is_float = vim.api.nvim_win_get_config(id).relative ~= ""
    if is_float then
      return
    end
    vim.cmd.wincmd("=")
  end,
  group = window_group_id,
})

Plug("numToStr/Navigator.nvim", {
  config = function()
    require("Navigator").setup()
    vim.keymap.set({'n', 't'}, '<M-h>', '<CMD>NavigatorLeft<CR>')
    vim.keymap.set({'n', 't'}, '<M-l>', '<CMD>NavigatorRight<CR>')
    vim.keymap.set({'n', 't'}, '<M-k>', '<CMD>NavigatorUp<CR>')
    vim.keymap.set({'n', 't'}, '<M-j>', '<CMD>NavigatorDown<CR>')
  end,
})