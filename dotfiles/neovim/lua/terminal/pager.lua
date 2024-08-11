-- String that will be appended to the buffer name
-- TODO: `page` adds quotations around these strings and I want to remove them
vim.g.page_icon_pipe = "(reading from pipe)" -- When piped
vim.g.page_icon_redirect = "(reading from stdin)" -- When exposes pty device
vim.g.page_icon_instance = "(reading from instance)" -- When `-i, -I` flags provided

local function reset_cursor_position()
  -- TODO: `page` doesn't offer a way to disable the centering of the cursor so I'm using an
  -- autocommand to reset the cursor after it's centered. For more info on why `page` centers the
  -- cursor see: https://github.com/I60R/page/issues/16
  local pager_group_id = vim.api.nvim_create_augroup("Pager", {})
  vim.api.nvim_create_autocmd("CursorMoved", {
    callback = function()
      local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
      -- I assume the cursor is centered if the row is more than one. I tried to calculate the
      -- middle row to have a more accurate check, but occasionally I would be off by one. I can't
      -- imagine where else `page` would move the cursor besides the center so this should be ok.
      --
      -- I also tried assuming that the first cursor movement made must be the centering of the
      -- cursor, but the event would fire a few times before the cursor was centered, though the
      -- cursor position wouldn't change.
      local is_cursor_centered_vertically = cursor_row > 1
      if is_cursor_centered_vertically then
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        vim.api.nvim_clear_autocmds({ group = pager_group_id })
      end
    end,
    group = pager_group_id,
  })
end

-- Will run once when the pager opens
vim.api.nvim_create_autocmd("User", {
  pattern = "PageOpen",
  callback = function()
    reset_cursor_position()
    vim.o.showtabline = 0
    -- disable horizontal scrolling
    vim.o.mousescroll = "ver:1,hor:0"
  end,
})
