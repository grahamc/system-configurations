---@diagnostic disable-next-line: unused-function, unused-local
local function get_system_theme()
  local path = (os.getenv("XDG_STATE_HOME") or os.getenv("HOME") .. "/.local/state")
    .. "/wezterm/current-theme.txt"
  local file_exists = vim.fn.filereadable(path) ~= 0
  if file_exists then
    return vim.fn.readfile(path)[1]
  end
  return "dark"
end

---@diagnostic disable-next-line: unused-function, unused-local
local function listen_for_system_theme_changes()
  local run_path = (os.getenv("XDG_RUNTIME_DIR") or os.getenv("TMPDIR") or "/tmp")
    .. "/nvim-wezterm/pipes"
  vim.fn.mkdir(run_path, "p")
  local pipe_file = vim.trim(vim.fn.system(string.format([[TMPDIR='%s' mktemp -u]], run_path)))
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

-- TODO: Forcing dark mode since devicons looks best in dark mode when using 256 colors. If I ever
-- switch to termguicolors I can remove this.
vim.o.background = "dark"
-- nord sets the background on startup so this will overwrite that. I wanted to use 'OptionSet', but this works too.
-- vim.api.nvim_create_autocmd(
--   'ColorScheme',
--   {
--     pattern = 'nord',
--     callback = function()
--       vim.o.background = get_system_theme()
--     end,
--     nested = true,
--     once = true,
--   }
-- )
-- listen_for_system_theme_changes()
