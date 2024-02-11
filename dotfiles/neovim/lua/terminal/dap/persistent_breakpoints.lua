local breakpoint_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "breakpoints")

local function write_json(path, tbl)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local fp = io.open(path, 'w')
  if fp == nil then
    vim.notify('Failed to write to file. File: ' .. path, vim.log.levels.ERROR)
    return
  else
    fp:write(vim.fn.json_encode(tbl))
    fp:close()
    return
  end
end

vim.api.nvim_create_autocmd("User", {
  pattern = "PlugEndPost",
  callback = function()
    ALL_BREAKPOINTS = ALL_BREAKPOINTS or {}

    local function record_breakpoints_for_buffer(buffer)
      local has_active_session = string.len(vim.v.this_session) > 0
      if not has_active_session then
        return
      end

      local bname = vim.api.nvim_buf_get_name(buffer)
      if bname == '' then
        return
      end

      local breakpoints_for_buffer = require('dap.breakpoints').get(buffer)[buffer]
      if #breakpoints_for_buffer == 0 then
        -- so the key in the JSON will be removed
        breakpoints_for_buffer = nil
      end
      ALL_BREAKPOINTS[bname] = breakpoints_for_buffer
      local basename = vim.fs.basename(vim.v.this_session)
      write_json(vim.fs.joinpath(breakpoint_dir, basename), ALL_BREAKPOINTS)
    end

    local function make_recorder(fn)
      return function(...)
        fn(...)
        record_breakpoints_for_buffer(vim.api.nvim_get_current_buf())
      end
    end
    local dap = require("dap")
    local original_toggle_breakpoint = dap.toggle_breakpoint
    dap.toggle_breakpoint = make_recorder(original_toggle_breakpoint)
    local original_set_breakpoint = dap.set_breakpoint
    dap.set_breakpoint = make_recorder(original_set_breakpoint)
  end,
})

-- To account for breakpoints changed in dapui. I tried to wrap the API it uses to change
-- breakpoints, but failed.
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    local has_active_session = string.len(vim.v.this_session) > 0
    if not has_active_session then
      return
    end

    local breakpoints_by_bufname = vim
      .iter(require('dap.breakpoints').get())
      :fold({}, function (acc, bufnr, breakpoints)
        acc[vim.api.nvim_buf_get_name(bufnr)] = breakpoints
        return acc
      end)
    local basename = vim.fs.basename(vim.v.this_session)
    write_json(vim.fs.joinpath(breakpoint_dir, basename), breakpoints_by_bufname)
  end,
})

-- TODO: Should let people know I figured out how to load breakpoints for all buffers:
-- https://github.com/Weissle/persistent-breakpoints.nvim/issues/8
vim.api.nvim_create_autocmd("SessionLoadPost", {
  callback = function()
    local function read_json(path)
      local fp = io.open(path, 'r')
      if fp == nil then
        vim.notify('Failed to read file. File: ' .. path, vim.log.levels.ERROR)
        return nil
      end

      return vim.fn.json_decode(fp:read('*a'))
    end

    local function open_file_in_background(filename)
      vim.cmd.badd(filename)
      local buf = vim.fn.bufnr(filename)
      vim.bo[buf].buflisted = false

      return buf
    end

    local session_basename = vim.fs.basename(vim.v.this_session)
    local breakpoint_path = vim.fs.joinpath(breakpoint_dir, session_basename)
    if vim.fn.filereadable(breakpoint_path) ~= 0 then
      local breakpoints_by_filename = read_json(breakpoint_path)
      if type(breakpoints_by_filename) == "table" then
        for filename, breakpoints in pairs(breakpoints_by_filename) do
          local buffer = nil
          if vim.fn.bufexists(filename) ~= 0 then
            buffer = vim.fn.bufnr(filename)
          else
            if vim.fn.filereadable(filename) == 0 then
              goto continue
            end
            buffer = open_file_in_background(filename)
          end

          for _, breakpoint in ipairs(breakpoints) do
            local line = breakpoint.line
            local opts = {
              condition = breakpoint.condition,
              log_message = breakpoint.logMessage,
              hit_condition = breakpoint.hitCondition
            }
            require('dap.breakpoints').set(opts, buffer, line)
          end

          ::continue::
        end

        ALL_BREAKPOINTS = breakpoints_by_filename
      end
    end
  end,
})
