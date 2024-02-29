local function get_system_theme()
  local path = (os.getenv("XDG_STATE_HOME") or os.getenv("HOME") .. "/.local/state")
    .. "/wezterm/current-theme.txt"
  local file_exists = vim.fn.filereadable(path) ~= 0
  if file_exists then
    return vim.fn.readfile(path)[1]
  end
  return "dark"
end

local function listen_for_system_theme_changes()
  local xdg_runtime_path = (os.getenv("XDG_RUNTIME_DIR") or os.getenv("TMPDIR") or "/tmp")
    .. "/nvim-wezterm/pipes"
  vim.fn.mkdir(xdg_runtime_path, "p")

  vim.system(
    { "mktemp", "-u" },
    { text = true, env = { TMPDIR = xdg_runtime_path } },
    vim.schedule_wrap(function(result)
      local pipe_file = vim.trim(result.stdout)
      if result.code ~= 0 then
        vim.notify("Failed to start system theme syncer", vim.log.levels.ERROR)
        return
      end

      vim.fn.serverstart(pipe_file)

      vim.api.nvim_create_autocmd("User", {
        pattern = "ColorSchemeDark",
        callback = function()
          vim.o.background = "dark"
        end,
        nested = true,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "ColorSchemeLight",
        callback = function()
          vim.o.background = "light"
        end,
        nested = true,
      })
    end)
  )
end

vim.o.background = get_system_theme()
listen_for_system_theme_changes()
