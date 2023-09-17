-- Wrapper for vim-plug with a few new features.

-- Original vim-plug commands/functions
local original_plug_begin = vim.fn['plug#begin']
local original_plug_end = vim.fn['plug#end']
local original_plug = vim.fn['plug#']

-- Plugins that have been added through `RegisterPlug`
_G.registered_plugs = {}

-- Functions to be called after a plugin is loaded to configure it.
local configs_by_type = {
  async = {},
  lazy = {},
}

-- Calls the configuration function for the specified, lazy-loaded plugin.
function PlugWrapperApplyLazyConfig(plugin_name)
  local config = configs_by_type.lazy[plugin_name]
  if type(config) == 'function' then
    config()
  end
end

-- Calls the configuration function for all non-lazy-loaded plugins.
local function ApplyConfigs(configs)
  for _, config in pairs(configs) do
    config()
  end
end

-- This only registers the plugin, but it won't be loaded. This way if I run PlugClean from one profile it
-- won't delete all the plugins from the other profiles since all plugins get registered here.
local function RegisterPlugin(repo)
  original_plug(repo, {['on'] = {}, ['for'] = {},})

  local plugin_name = repo:match("^[%w-]+/([%w-_.]+)$")

  _G.registered_plugs[plugin_name] = true
end

_G.plug_begin = function()
  original_plug_begin()

  for line in io.lines(vim.fn.stdpath('config') .. '/plugfile.txt') do
    -- skip blank lines
    if #line == 0 then
      goto continue
    end

    RegisterPlugin(line)

    ::continue::
  end
end

_G.plug_end = function()
  original_plug_end()

  -- This way code can be run after plugins are loaded, but before 'VimEnter'
  vim.api.nvim_exec_autocmds('User', {pattern = 'PlugEndPost'})

  -- Apply the async configurations after everything else that is currently on the event loop. Now
  -- configs are applied after any files specified on the commandline are opened and after sessions are restored.
  -- This way, neovim shows me the first file "instantly" and by the time I've looked at the file and decided on my
  -- first keypress, the plugin configs have already been applied.
  vim.fn.timer_start(0, function() ApplyConfigs(configs_by_type.async) end)
end

-- Similar to the vim-plug `Plug` command, but with an additional option to specify a function to run after a
-- plugin is loaded.
function Plug(repo, options)
  if not options then
    original_plug(repo)
    return
  end

  local original_plug_options = vim.tbl_deep_extend('force', options, {config = nil,})
  original_plug(repo, original_plug_options)

  local config = options.config
  if type(config) == 'function' then
    if options['on'] or options['for'] then
      local plugin_name = repo:match("^[%w-]+/([%w-_.]+)$")
      configs_by_type.lazy[plugin_name] = config
      vim.api.nvim_create_autocmd(
        'User',
        {
          pattern = plugin_name,
          callback = function() _G.PlugWrapperApplyLazyConfig(plugin_name) end,
          group = vim.api.nvim_create_augroup('PlugLua', {}),
          once = true,
        }
      )
    else
      table.insert(configs_by_type.async, config)
    end
  end
end
