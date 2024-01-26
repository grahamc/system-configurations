-- vim:foldmethod=marker

vim.keymap.set({ "n" }, "Q", "<Nop>")

-- Faster macro execution {{{
-- Execute macros more quickly by enabling `lazyredraw` and disabling events while the macro is
-- running
local function get_char()
  local ret_val, char_num = pcall(vim.fn.getchar)
  -- Return nil if error (e.g. <C-c>) or for control characters
  if not ret_val or char_num < 32 then
    return nil
  end
  local char = vim.fn.nr2char(char_num)

  return char
end

vim.keymap.set({ "x", "n" }, "@", function()
  local mode = vim.fn.mode()
  local count = vim.v.count1
  vim.cmd('execute "normal \\<Esc>"')

  local range = ""
  for _, visual_mode in pairs({ "v", "V", "" }) do
    if mode == visual_mode then
      range = [['<,'>]]
      break
    end
  end

  local register = get_char()
  if register == nil then
    return
  end

  vim.o.eventignore = "all"
  vim.o.lazyredraw = true
  vim.cmd(string.format(
    -- Execute silently so I don't get prompted to press enter if an error is thrown. For example, when I use
    -- substitute and there is no match.
    [[silent! %snormal! %s@%s]],
    range,
    count,
    register
  ))
  vim.o.eventignore = ""
  vim.o.lazyredraw = false
end)

local fast_macro_group_id = vim.api.nvim_create_augroup("FastMacro", {})

vim.api.nvim_create_autocmd("RecordingEnter", {
  callback = function()
    if _G.fast_macro_events == nil then
      local events = vim.fn.getcompletion("", "event")

      for index, event in ipairs(events) do
        if event == "RecordingLeave" then
          table.remove(events, index)
          break
        end
      end

      _G.fast_macro_events = table.concat(events, ",")
    end

    vim.g.old_eventignore = vim.o.eventignore
    vim.o.eventignore = _G.fast_macro_events
  end,
  group = fast_macro_group_id,
})

vim.api.nvim_create_autocmd("RecordingLeave", {
  callback = function()
    vim.o.eventignore = vim.g.old_eventignore
  end,
  group = fast_macro_group_id,
})
-- }}}
