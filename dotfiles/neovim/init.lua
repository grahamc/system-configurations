-- Enabling this will cache any lua modules that are required after this point.
vim.loader.enable()

-- Import my vim-plug wrapper
require("plug")

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
vim.g.mapleader = " "
_G.GetMaxLineLength = function()
  local editorconfig = vim.b["editorconfig"]
  if editorconfig ~= nil and editorconfig.max_line_length ~= nil then
    return tonumber(editorconfig.max_line_length)
  end

  return 100
end
function GetVisualSelection()
  local mode_char = vim.fn.mode()
  -- "\x16" is the code for ctrl+v i.e. visual-block mode
  local in_visual_mode = mode_char == "v" or mode_char == "V" or mode_char == "\x16"
  if not in_visual_mode then
    return ""
  end

  vim.cmd('noau normal! "vy"')
  local text = vim.fn.getreg("v")
  vim.fn.setreg("v", {})

  -- remove trailing newline
  if mode_char == "V" then
    text = text:sub(1, -2)
  end

  return text
end

-- Calling this before I load the profiles so I can register plugins inside them
PlugBegin()

-- Load profiles
require("base")
require("terminal")
require("vscode")
require("browser")

-- Calling this after I load the profiles so I can register plugins inside them
PlugEnd()
