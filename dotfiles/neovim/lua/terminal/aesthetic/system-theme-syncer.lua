local is_wezterm_in_flatpak = os.execute("command -v flatpak") == 0
local runtime_directory = os.getenv("XDG_STATE_HOME")
  or (
    is_wezterm_in_flatpak
      -- source: https://docs.flatpak.org/en/latest/conventions.html#xdg-base-directories
      and (os.getenv("HOME") .. "/.var/app/org.wezfurlong.wezterm/.local/state")
    or (os.getenv("HOME") .. "/.local/state")
  )
local nvim_wezterm_runtime_directory = runtime_directory .. "/nvim-wezterm"

local function get_system_theme()
  local path = nvim_wezterm_runtime_directory .. "/current-theme.txt"
  local file_exists = vim.fn.filereadable(path) ~= 0
  if file_exists then
    return vim.fn.readfile(path)[1]
  end
  return "dark"
end

local function listen_for_system_theme_changes()
  local pipe_directory = nvim_wezterm_runtime_directory .. "/pipes"
  local command = string.format(
    [[mkdir -p %s 1>/dev/null 2>&1 && ln -f -s %s %s 1>/dev/null 2>&1 && mktemp -u]],
    vim.fn.shellescape(pipe_directory),
    vim.fn.shellescape(vim.fn.exepath("nvim")),
    vim.fn.shellescape(nvim_wezterm_runtime_directory .. "/nvim")
  )
  vim.system(
    { "sh", "-c", command },
    { text = true, env = { TMPDIR = pipe_directory } },
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
