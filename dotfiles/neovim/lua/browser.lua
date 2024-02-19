-- Exit if we are not running inside a browser
if vim.g.started_by_firenvim == nil then
  return
end

-- disable statusline
vim.o.laststatus = 0

vim.keymap.set("i", "<M-e>", "<Cmd>wq<CR>")
-- Before quitting in normal mode, I move the cursor one to the right so the cursor will be in front
-- of the current character after quitting neovim instead of behind it. I use `a` instead of `l` to
-- account for when the cursor is on the last character of the line.
vim.keymap.set("n", "<M-e>", "a<Cmd>wq<CR>")
vim.keymap.set("n", "<C-x>", "a<Cmd>wq<CR>")

Plug("glacambre/firenvim")
vim.g.firenvim_config = {
  localSettings = {
    [".*"] = {
      -- Don't automatically load firenvim in text areas, I'll do it manually with a key bind
      takeover = "never",
      -- Use firenvim's commandline instead of neovim's
      cmdline = "firenvim",
      -- A second after the cursor moves, hide the commandline. This is a workaround for a bug:
      -- https://github.com/glacambre/firenvim#configuring-message-timeout
      cmdlineTimeout = 1000,
    },
  },
}
