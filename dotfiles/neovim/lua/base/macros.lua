-- vim:foldmethod=marker

local utilities = require("base.utilities")

vim.keymap.set({ "n", "x" }, "Q", function()
  local last_recorded_register = vim.fn.reg_recorded()
  if last_recorded_register ~= "" then
    return "@" .. last_recorded_register
  end
end, { remap = true, expr = true, desc = "Run last recorded macro" })

-- change macro
vim.keymap.set({ "n" }, "cq", function()
  local register = utilities.get_char()
  if register == nil then
    return
  end

  local macro_content = vim.fn.getreg(register)
  local input_config = {
    prompt = "Edit Macro [" .. register .. "]:",
    default = macro_content,
  }
  vim.ui.input(input_config, function(edited_macro)
    if not edited_macro then
      return
    end -- cancellation
    vim.fn.setreg(register, edited_macro)
  end)
end, {
  desc = "Change macro [edit,modify]",
})

-- Faster macro execution {{{
-- Execute macros more quickly by enabling `lazyredraw` and disabling events
-- while the macro is running

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

  local register = utilities.get_char()
  if register == nil then
    return
  end

  vim.o.eventignore = "all"
  vim.o.lazyredraw = true
  vim.cmd(string.format(
    -- Execute silently so I don't get prompted to press enter if an error is
    -- thrown. For example, when I use substitute and there is no match.
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
      local events = vim.fn.getcompletion("", "event") or {}

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
