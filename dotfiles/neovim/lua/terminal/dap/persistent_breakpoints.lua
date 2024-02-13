local function get_breakpoints_file_path()
  local breakpoint_directory = vim.fs.joinpath(vim.fn.stdpath("data"), "breakpoints")
  local session_basename = vim.fs.basename(vim.v.this_session)
  return vim.fs.joinpath(breakpoint_directory, session_basename)
end

vim.api.nvim_create_autocmd("User", {
  pattern = "PlugEndPost",
  callback = function()
    local function write_dictionary_as_json(path, dictionary)
      -- ensure it's saved as a dictionary
      if vim.tbl_isempty(dictionary) then
        dictionary = vim.empty_dict()
      end

      vim.fn.mkdir(vim.fs.dirname(path), "p")
      local fp = io.open(path, "w")
      if fp == nil then
        vim.notify("Failed to write dictionary to file: " .. path, vim.log.levels.ERROR)
        return
      else
        fp:write(vim.fn.json_encode(dictionary))
        fp:close()
        return
      end
    end

    local function persist_breakpoints()
      local has_active_session = string.len(vim.v.this_session) > 0
      if not has_active_session then
        return
      end

      local breakpoints_by_bufname = vim
        .iter(require("dap.breakpoints").get())
        :fold({}, function(acc, bufnr, breakpoints)
          acc[vim.api.nvim_buf_get_name(bufnr)] = breakpoints
          return acc
        end)

      write_dictionary_as_json(get_breakpoints_file_path(), breakpoints_by_bufname)
    end

    local function persist_breakpoints_after(module_name, function_name)
      local module = require(module_name)
      local original = module[function_name]
      module[function_name] = function(...)
        original(...)
        persist_breakpoints()
      end
    end

    local dap_module_name = "dap"
    persist_breakpoints_after(dap_module_name, "toggle_breakpoint")
    persist_breakpoints_after(dap_module_name, "set_breakpoint")
    persist_breakpoints_after(dap_module_name, "clear_breakpoints")

    -- HACK: This is a private API, but dap-ui is using it so I need to wrap it too.
    local dap_breakpoints_module_name = "dap.breakpoints"
    persist_breakpoints_after(dap_breakpoints_module_name, "toggle")
  end,
})

-- TODO: Should let people know I figured out how to load breakpoints for all files:
-- https://github.com/Weissle/persistent-breakpoints.nvim/issues/8
vim.api.nvim_create_autocmd("SessionLoadPost", {
  callback = function()
    local function is_file_readable(filename)
      return vim.fn.filereadable(filename) ~= 0
    end

    local function read_json(path)
      local fp = io.open(path, "r")
      if fp == nil then
        vim.notify("Failed to read file. File: " .. path, vim.log.levels.ERROR)
        return nil
      end

      return vim.fn.json_decode(fp:read("*a"))
    end

    -- where background means the file won't be focused and it won't show up in my bufferline
    local function open_file_in_background(filename)
      vim.cmd.badd(filename)
      local buf = vim.fn.bufnr(filename)
      vim.bo[buf].buflisted = false

      return buf
    end

    local function restore_breakpoint(breakpoint, buffer)
      local line = breakpoint.line
      local opts = {
        condition = breakpoint.condition,
        log_message = breakpoint.logMessage,
        hit_condition = breakpoint.hitCondition,
      }
      require("dap.breakpoints").set(opts, buffer, line)
    end

    local function restore_breakpoints_for_file(filename, breakpoints)
      local buffer = (vim.fn.bufexists(filename) ~= 0) and vim.fn.bufnr(filename)
        or open_file_in_background(filename)

      vim.iter(breakpoints):each(function(breakpoint)
        restore_breakpoint(breakpoint, buffer)
      end)
    end

    local breakpoints_path = get_breakpoints_file_path()
    if not is_file_readable(breakpoints_path) then
      return
    end

    local breakpoints_by_filename = read_json(breakpoints_path)
    if type(breakpoints_by_filename) ~= "table" then
      return
    end

    vim
      .iter(breakpoints_by_filename)
      :filter(function(filename, _)
        return is_file_readable(filename)
      end)
      :each(restore_breakpoints_for_file)
  end,
})
