-- open new horizontal and vertical panes to the right and bottom respectively
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.winminheight = 0
vim.o.winminwidth = 0
vim.keymap.set("n", [[<Leader>\]], vim.cmd.vsplit, {
  desc = "Vertical split",
})
vim.keymap.set("n", "<Leader>-", vim.cmd.split, {
  desc = "Horizontal split",
})
-- making it a buffer map so I can use `nowait`
local function close_window_mapping(buf)
  vim.keymap.set("n", "<C-w>", vim.cmd.close, {
    desc = "Close window",
    buffer = buf,
    silent = true,
    nowait = true,
  })
end
vim.api.nvim_create_autocmd("BufNew", {
  callback = function(context)
    close_window_mapping(context.buf)
  end,
})
-- for files specified before vim starts e.g. through the commandline
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function(_context)
    vim.iter(vim.api.nvim_list_bufs()):each(close_window_mapping)
  end,
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

-- Resize windows
vim.keymap.set(
  { "n" },
  "<C-Left>",
  [[<Cmd>vertical resize +1<CR>]],
  { silent = true, desc = "Resize window left" }
)
vim.keymap.set(
  { "n" },
  "<C-Right>",
  [[<Cmd>vertical resize -1<CR>]],
  { silent = true, desc = "Resize window right" }
)
vim.keymap.set(
  { "n" },
  "<C-Up>",
  [[<Cmd>resize +1<CR>]],
  { silent = true, desc = "Resize window up" }
)
vim.keymap.set(
  { "n" },
  "<C-Down>",
  [[<Cmd>resize -1<CR>]],
  { silent = true, desc = "Resize window down" }
)

-- Seamless movement between vim windows and tmux panes.
Plug("christoomey/vim-tmux-navigator", {
  config = function()
    vim.keymap.set(
      { "n", "i", "t" },
      "<M-h>",
      vim.cmd.TmuxNavigateLeft,
      { silent = true, desc = "Move to west window [left]" }
    )
    vim.keymap.set(
      { "n", "i", "t" },
      "<M-l>",
      vim.cmd.TmuxNavigateRight,
      { silent = true, desc = "Move to east window [right]" }
    )
    vim.keymap.set(
      { "n", "i", "t" },
      "<M-j>",
      vim.cmd.TmuxNavigateDown,
      { silent = true, desc = "Move to south window [down]" }
    )
    vim.keymap.set(
      { "n", "i", "t" },
      "<M-k>",
      vim.cmd.TmuxNavigateUp,
      { silent = true, desc = "Move to north window [up]" }
    )
  end,
})
vim.g.tmux_navigator_no_mappings = 1
vim.g.tmux_navigator_preserve_zoom = 1
vim.g.tmux_navigator_disable_when_zoomed = 0
