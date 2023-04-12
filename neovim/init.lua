-- vim:foldmethod=marker
-- Disable unused builtin plugins.
local plugins_to_disable = {
  "netrw",
  "netrwPlugin",
  "netrwSettings",
  "netrwFileHandlers",
  "gzip",
  "zip",
  "zipPlugin",
  "tar",
  "tarPlugin",
  "getscript",
  "getscriptPlugin",
  "vimball",
  "vimballPlugin",
  "2html_plugin",
  "logipat",
  "rrhelper",
  "spellfile_plugin",
  "matchit",
}
for _, plugin in pairs(plugins_to_disable) do
  vim.g["loaded_" .. plugin] = 1
end

-- Variables used across config files
vim.g.mapleader = vim.api.nvim_replace_termcodes('<Space>', true, false, true)
vim.g.data_path = vim.fn.stdpath('data')
vim.g.config_path = vim.fn.stdpath('config')
vim.g.profiles = {}
local profile_directory = vim.g.config_path .. '/profiles'
if vim.fn.isdirectory(profile_directory) then
  vim.g.profiles = vim.fn.split(vim.fn.globpath(profile_directory, '*'), '\n')
end

-- Wrapper for vim-plug. Adds the option to specify a function to run after a plugin is loaded.
local configs = {
  immediate = {},
  lazy = {},
}
local original_plug_begin = vim.fn['plug#begin']
local function plug_begin()
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
local original_plug_end = vim.fn['plug#end']
local function plug_end()
  original_plug_end()

  -- This way the profiles can run code after plugins are loaded, but before 'VimEnter'
  vim.cmd('doautocmd User PlugEndPost')

  PlugWrapperApplyImmediateConfigs()
end
_G.PlugWrapperApplyLazyConfig = function(plugin_name)
  local config = configs.lazy[plugin_name]
  if type(config) == 'function' then
    config()
  end
end
_G.PlugWrapperApplyImmediateConfigs = function()
  for _, config in pairs(configs.immediate) do
    config()
  end
end
local original_plug = vim.fn['plug#']
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

-- Calling this before I load the profiles so I can register plugins inside them
plug_begin()

-- Register Plugins
vim.cmd('source ' .. vim.fn.expand('<sfile>:h') .. '/plugfile.vim')

-- Load profiles
for _, profile in pairs(vim.g.profiles) do
  vim.cmd('source ' .. profile)
end

-- Calling this after I load the profiles so I can register plugins inside them
plug_end()
