lua << EOF
-- TODO: This way the plugins get registered even if we aren't in the browser
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
EOF

" Exit if we are not running inside a browser
if !exists('g:started_by_firenvim')
  finish
endif

lua << EOF
-- disable statusline
vim.o.laststatus = 0

vim.keymap.set('n', '<C-x>', '<Cmd>wq<CR>')
EOF
