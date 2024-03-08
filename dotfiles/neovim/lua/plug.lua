-- Wrapper for vim-plug with a few new features.

local M = {}

-- Functions to be called after a plugin is loaded to configure it.
local configs_by_type = {
  sync = {},
  async = {},
  lazy = {},
}

-- Calls the configuration function for the specified, lazy-loaded plugin.
local function plug_wrapper_apply_lazy_config(plugin_name)
  local config = configs_by_type.lazy[plugin_name]
  if type(config) == "function" then
    config()
  end
end

-- Calls the configuration function for all non-lazy-loaded plugins.
local function apply_configs(configs)
  for _, config in pairs(configs) do
    config()
  end
end

local group_id = vim.api.nvim_create_augroup("PlugLua", {})
local original_plug = vim.fn["plug#"]
local function plug(repo, options)
  if not options then
    original_plug(repo)
    return
  end

  local original_plug_options = vim.tbl_deep_extend("force", options, { config = nil, sync = nil })
  original_plug(repo, original_plug_options)

  local config = options.config
  if type(config) == "function" then
    if options["on"] or options["for"] then
      local plugin_name = repo:match("^[%w-]+/([%w-_.]+)$")
      configs_by_type.lazy[plugin_name] = config
      vim.api.nvim_create_autocmd("User", {
        pattern = plugin_name,
        callback = function()
          plug_wrapper_apply_lazy_config(plugin_name)
        end,
        group = group_id,
        once = true,
      })
    elseif options.sync then
      table.insert(configs_by_type.sync, config)
    else
      table.insert(configs_by_type.async, config)
    end
  end
end

local function plug_begin()
  -- expose the Plug function globally
  _G["Plug"] = plug

  -- To suppress the 'no git executable' warning
  vim.cmd([[
    silent! call plug#begin()
  ]])
end

local original_plug_end = vim.fn["plug#end"]
local function plug_end()
  original_plug_end()

  _G["Plug"] = nil

  -- This way code can be run after plugins are loaded, but before 'VimEnter'
  vim.api.nvim_exec_autocmds("User", { pattern = "PlugEndPost" })

  apply_configs(configs_by_type.sync)

  -- Apply the asynchronous configurations after everything else that is currently on the event
  -- loop. Now configs are applied after any files specified on the commandline are opened and after
  -- sessions are restored. This way, neovim shows me the first file "instantly" and by the time
  -- I've looked at the file and decided on my first key press, the plugin configs have already been
  -- applied.
  local function ApplyAsyncConfigs()
    apply_configs(configs_by_type.async)
  end
  vim.defer_fn(ApplyAsyncConfigs, 0)
end

-- vim-plugs enables syntax highlighting if it isn't already enabled, but I don't want it since I
-- use treesitter.  This will make vim-plug think it's already on so it won't enable it.
local function run_with_faked_syntax_on(fn)
  vim.cmd.syntax("off")
  vim.g.syntax_on = true
  fn()
  vim.g.syntax_on = false
end

function M.load_plugins(plugin_definer)
  run_with_faked_syntax_on(function()
    plug_begin()
    plugin_definer()
    plug_end()
  end)
end

-- On startup, prompt the user to install any missing plugins.
vim.api.nvim_create_autocmd("User", {
  pattern = "PlugEndPost",
  callback = function()
    local plugs = vim.g.plugs or {}
    local missing_plugins = {}
    for name, info in pairs(plugs) do
      local is_installed = vim.fn.isdirectory(info.dir) ~= 0
      if not is_installed then
        missing_plugins[name] = info
      end
    end

    -- checking for empty table
    if next(missing_plugins) == nil then
      return
    end

    local missing_plugin_names = {}
    for key, _ in pairs(missing_plugins) do
      table.insert(missing_plugin_names, key)
    end

    local install_prompt = string.format(
      "The following plugins are not installed:\n%s\nWould you like to install them?",
      table.concat(missing_plugin_names, ", ")
    )
    local should_install = vim.fn.confirm(install_prompt, "yes\nno") == 1
    if should_install then
      vim.cmd(string.format("PlugInstall --sync %s", table.concat(missing_plugin_names, " ")))
    end
  end,
  group = vim.api.nvim_create_augroup("InstallMissingPlugins", {}),
})

return M
