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
vim.g.profiles = {}
local profile_directory = vim.fn.expand('<sfile>:h') .. '/profiles'
if vim.fn.isdirectory(profile_directory) then
  vim.g.profiles = vim.fn.split(vim.fn.globpath(profile_directory, '*'), '\n')
end

-- Install vim-plug if not found
local vim_plug_plugin_file = vim.g.data_path .. '/site/autoload/plug.vim'
if vim.fn.empty(vim.fn.glob(vim_plug_plugin_file)) ~= 0 then
  vim.cmd([[
    silent execute '!curl -fLo ]] .. vim_plug_plugin_file .. [[ --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  ]])
end

-- Wrapper for vim-plug. Adds the option to specify a function to run after a plugin is loaded.
local configs = {
  immediate = {},
  lazy = {},
}
local plug_begin = vim.fn['plug#begin']
local original_plug_end = vim.fn['plug#end']
local function plug_end()
  original_plug_end()
  for _, config in pairs(configs.immediate) do
    config()
  end
end
_G.PlugWrapperApplyConfig = function(plugin_name)
  local config = configs.lazy[plugin_name]
  if type(config) == 'function' then
    config()
  end
end
local original_plug = vim.fn['plug#']
function Plug(repo, options)
  local original_plug_options = vim.tbl_deep_extend('force', options, {config = nil})
  original_plug(repo, original_plug_options)

  local config = options.config
  if type(config) == 'function' then
    if options['on'] or options['for'] then
      local plugin_name = repo:match("^[%w-]+/([%w-_.]+)$")
      configs.lazy[plugin_name] = config
      vim.cmd(string.format(
        [[ autocmd! User %s ++once lua PlugWrapperApplyConfig('%s') ]],
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

-- Load profiles
for _, profile in pairs(vim.g.profiles) do
  vim.cmd('source ' .. profile)
end

-- Calling this after I load the profiles so I can register plugins inside them
plug_end()

-- This way the profiles can run code after plugins are loaded, but before 'VimEnter'
vim.cmd('doautocmd User PlugEndPost')
