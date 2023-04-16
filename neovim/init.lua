-- vim:foldmethod=marker
-- Import my vim-plug wrapper
require('plug')

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

-- Calling this before I load the profiles so I can register plugins inside them
plug_begin()

-- Register Plugins
vim.cmd('source ' .. vim.g.config_path .. '/plugfile.lua')

-- Load profiles
for _, profile in pairs(vim.g.profiles) do
  vim.cmd('source ' .. profile)
end

-- Calling this after I load the profiles so I can register plugins inside them
plug_end()
