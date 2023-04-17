-- Wrapper for vim-plug with a few new features.

-- Original vim-plug commands/functions
local original_plug_begin = vim.fn['plug#begin']
local original_plug_end = vim.fn['plug#end']
local original_plug = vim.fn['plug#']

-- Plugins that have been added through `RegisterPlug`
vim.g.registered_plugs = {}

-- Functions to be called after a plugin is loaded to configure it.
local configs = {
  immediate = {},
  lazy = {},
}

-- Calls the configuration function for the specified, lazy-loaded plugin.
function PlugWrapperApplyLazyConfig(plugin_name)
  local config = configs.lazy[plugin_name]
  if type(config) == 'function' then
    config()
  end
end

-- Calls the configuration function for all non-lazy-loaded plugins.
local function PlugWrapperApplyImmediateConfigs()
  for _, config in pairs(configs.immediate) do
    config()
  end
end

function plug_begin()
  original_plug_begin()

  -- Loading this now so that it caches any lua modules that are required after this point.
  Plug(
    'lewis6991/impatient.nvim',
    {
      ['on'] = {},
      ['for'] = {},
    }
  )
  pcall(vim.fn['plug#load'], 'impatient.nvim')
  pcall(require, 'impatient')
end

function plug_end()
  original_plug_end()

  -- This way code can be run after plugins are loaded, but before 'VimEnter'
  vim.cmd('doautocmd User PlugEndPost')

  PlugWrapperApplyImmediateConfigs()
end

-- Similar to the vim-plug `Plug` command, but with an additional option to specify a function to run after a
-- plugin is loaded.
function Plug(repo, options)
  if not options then
    original_plug(repo)
    return
  end

  local original_plug_options = vim.tbl_deep_extend('force', options, {config = nil})
  original_plug(repo, original_plug_options)

  local config = options.config
  if type(config) == 'function' then
    if options['on'] or options['for'] then
      local plugin_name = repo:match("^[%w-]+/([%w-_.]+)$")
      configs.lazy[plugin_name] = config
      vim.cmd(string.format(
        [[ autocmd! User %s ++once lua PlugWrapperApplyLazyConfig('%s') ]],
        plugin_name,
        plugin_name
      ))
    else
      table.insert(configs.immediate, config)
    end
  end
end

-- This command only registers the plugin, but it won't be loaded. This way if I run PlugClean from one profile it
-- won't delete all the plugins from the other profiles since all plugins get registered here.
function RegisterPlug(repo)
  original_plug(repo, {['on'] = {}, ['for'] = {},})

  local plugin_name = repo:match("^[%w-]+/([%w-_.]+)$")

  local temp = vim.g.registered_plugs
  table.insert(temp, plugin_name)
  vim.g.registered_plugs = temp
end
