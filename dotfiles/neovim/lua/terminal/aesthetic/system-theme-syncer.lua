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

  local command_output = vim.fn.system(string.format([[TMPDIR='%s' mktemp -u]], xdg_runtime_path))
  if command_output == nil then
    vim.notify("Failed to start system theme syncer", vim.log.levels.ERROR)
    return
  end

  local pipe_file = vim.trim(command_output)
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
end

vim.o.background = get_system_theme()
listen_for_system_theme_changes()
