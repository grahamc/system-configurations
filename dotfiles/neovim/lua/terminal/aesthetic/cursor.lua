local function set_cursor()
  -- Block cursor in normal mode, thin line in insert mode, and underline in replace mode
  vim.o.guicursor =
    "n-v:block-blinkon0,i-c-ci-ve:ver25-blinkwait0-blinkon200-blinkoff200,r-cr-o:hor20-blinkwait0-blinkon200-blinkoff200"
end
set_cursor()

local function reset_cursor()
  -- Reset terminal cursor to blinking bar.
  -- TODO: This won't be necessary once neovim starts doing this automatically.
  -- Issue: https://github.com/neovim/neovim/issues/4396
  vim.o.guicursor = "a:ver25-blinkwait0-blinkon200-blinkoff200"
end

local cursor_group_id = vim.api.nvim_create_augroup("Cursor", {})
vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend" }, {
  callback = reset_cursor,
  group = cursor_group_id,
})
vim.api.nvim_create_autocmd({ "VimResume" }, {
  callback = set_cursor,
  group = cursor_group_id,
})

-- Hide cursor in dropbar
--
-- TODO: Should add this as a tip for dropbar
vim.api.nvim_create_autocmd("FileType", {
  pattern = "dropbar_menu",
  callback = function()
    vim.o.guicursor = "n-v-c:block-DropBarMenuCursor"
  end,
})
vim.api.nvim_create_autocmd("WinLeave", {
  callback = function()
    if vim.bo.filetype == "dropbar_menu" then
      set_cursor()
    end
  end,
})
