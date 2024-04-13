local M = {}

function M.set_jump_before(fn)
  return function(...)
    vim.cmd([[
      normal! m'
    ]])
    fn(...)
  end
end

-- Some highlights don't exist in the colorscheme so when I switch they would be erased.
-- This will retain them.
local id_map = {}
function M.set_persistent_highlights(key, highlights)
  local function helper()
    vim.iter(highlights):each(function(from, to)
      vim.api.nvim_set_hl(0, from, { link = to })
    end)
  end
  helper()
  if id_map[key] ~= nil then
    vim.api.nvim_del_autocmd(id_map[key])
  end
  id_map[key] =
    vim.api.nvim_create_autocmd("ColorScheme", { callback = helper })
end

-- Set the filetype of all the currently open buffers to trigger a 'FileType' event for each
-- buffer. This will trigger lsp attach
function M.trigger_lsp_attach()
  vim.iter(vim.api.nvim_list_bufs()):each(function(buf)
    vim.bo[buf].filetype = vim.bo[buf].filetype
  end)
end

local context_by_id = {}
function M.set_up_live_preview(opts)
  local no_op = function(...) end

  local id = opts.id
  local file_type = opts.file_type
  local get_bufnr = opts.get_bufnr
  local on_select = opts.on_select or no_op
  local on_exit = opts.on_exit or no_op
  local on_preview = opts.on_preview or no_op
  local set_up_once = true
  if opts.set_up_once ~= nil then
    set_up_once = opts.set_up_once
  end

  context_by_id[id] = {}
  local context = context_by_id[id]

  vim.api.nvim_create_autocmd("WinLeave", {
    callback = function()
      local is_normal_editor_window = not vim.tbl_contains(
        { "qf", "NvimTree" },
        vim.bo.filetype
      ) and vim.bo.buftype == ""
      if is_normal_editor_window then
        context.position = vim.api.nvim_win_get_cursor(0)
        context.buffer = vim.api.nvim_get_current_buf()
        context.window = vim.api.nvim_get_current_win()
      else
        context.is_leaving = true
      end
    end,
  })

  vim.api.nvim_create_autocmd("WinEnter", {
    callback = function()
      if
        not context.is_explicit_jump
        and not IsExplicitJump
        and vim.bo.filetype ~= file_type
        and context.is_leaving
      then
        context.is_leaving = false
        vim.api.nvim_win_set_buf(context.window, context.buffer)
        vim.api.nvim_win_set_cursor(context.window, context.position)
      elseif context.is_explicit_jump or IsExplicitJump then
        context.is_explicit_jump = false
        IsExplicitJump = nil
        context.is_leaving = false
        vim.bo.buflisted = true
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = file_type,
    once = set_up_once,
    callback = function()
      vim.keymap.set("n", "<CR>", function()
        context.is_explicit_jump = true
        -- TODO: why won't is_explicit_jump work?
        IsExplicitJump = "ok"
        on_select()
      end, { buffer = vim.api.nvim_get_current_buf() })

      vim.api.nvim_create_autocmd("CursorHold", {
        buffer = vim.api.nvim_get_current_buf(),
        nested = true,
        callback = function()
          local bufnr = get_bufnr()
          if bufnr == nil then
            return
          end

          vim.api.nvim_win_set_buf(context.window, bufnr)

          on_preview(context.window)
        end,
      })

      vim.api.nvim_create_autocmd("BufLeave", {
        buffer = vim.api.nvim_get_current_buf(),
        callback = function()
          on_exit(context.window)
        end,
      })
    end,
  })
end

return M
