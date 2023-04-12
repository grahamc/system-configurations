-- Exit if we are not running inside a browser
if vim.g.started_by_firenvim == nil then
  return
end

-- disable statusline
vim.o.laststatus = 0

vim.keymap.set('n', '<C-x>', '<Cmd>wq<CR>')

Plug(
  'glacambre/firenvim',
  {
    ['do'] = ":call firenvim#install(0)",
    config = function()
      vim.g.firenvim_config =  {
        localSettings = {
          ['.*'] = {
            -- Don't automatically load firenvim in text areas, I'll do it manually with a keybind
            takeover = 'never',
            -- Use firenvim's commandline instead of neovims
            cmdline = 'firenvim',
            -- A second after the cursor moves, hide the commandline. This is a workaround for a bug:
            -- https://github.com/glacambre/firenvim#configuring-message-timeout
            cmdlineTimeout = 1000,
          },
        },
      }
    end,
  }
)
