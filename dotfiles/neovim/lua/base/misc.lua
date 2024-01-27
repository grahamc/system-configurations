-- vim:foldmethod=marker

vim.o.timeout = true
vim.o.timeoutlen = 500
vim.o.updatetime = 500
vim.o.swapfile = false
vim.o.fileformats = "unix,dos,mac"
vim.o.paragraphs = ""
vim.o.sections = ""
vim.g.mapleader = " "
vim.keymap.set({ "i" }, "jk", "<Esc>")
Plug("tpope/vim-repeat")

-- Prevents inserting two spaces after punctuation on a join (J)
vim.o.joinspaces = false

-- Enter a newline above or below the current line.
vim.keymap.set({ "n" }, "<Enter>", "o<ESC>")
-- TODO: This won't work until tmux can differentiate between enter and shift+enter.
-- tmux issue: https://github.com/tmux/tmux/issues/2705#issuecomment-841133549
vim.keymap.set({ "n" }, "<S-Enter>", "O<ESC>")

-- Disable features {{{
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

-- Disable language providers. Feels like a lot of trouble to install neovim bindings for all these
-- languages so I'll just avoid plugins that require them. By disabling the providers, I won't get a
-- warning about missing bindings when I run `:checkhealth`.
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
-- }}}

-- Option overrides {{{
local vim_default_overrides_group_id = vim.api.nvim_create_augroup("VimDefaultOverrides", {})

-- Vim's default filetype plugins get run when filetype detection is enabled (i.e. ':filetype plugin
-- on'). So in order to override settings from vim's filetype plugins, these FileType autocommands
-- need to be registered after filetype detection is enabled. File type detection is turned on in
-- plug_end() so this function gets called at `PlugEndPost`, which is right after plug_end() is
-- called.
local function override_default_filetype_plugins()
  -- Don't automatically hard-wrap text
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    callback = function()
      vim.bo.wrapmargin = 0
      -- ro: auto insert comment character
      -- jr: delete comment character when joining commented lines
      vim.bo.formatoptions = "rojr"
    end,
    group = vim_default_overrides_group_id,
  })

  -- Use vim help pages for `keywordprg` in vim files
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "vim",
    callback = function()
      vim.opt_local.keywordprg = ":tab help"
    end,
    group = vim_default_overrides_group_id,
  })
end

vim.api.nvim_create_autocmd("User", {
  pattern = "PlugEndPost",
  callback = override_default_filetype_plugins,
  group = vim_default_overrides_group_id,
})
-- }}}

-- Clipboard {{{
vim.o.clipboard = "unnamedplus"

-- 1. re-indent the pasted text
-- 2. move to the end of the pasted text
vim.keymap.set({ "n", "x" }, "p", "p=`]", { silent = true })
-- }}}

-- Substitutions {{{
-- Commands/mappings for working with variants of words. In particular I use its 'S' command for
-- performing substitutions. It has more features than vim's built-in :substitution
Plug("tpope/vim-abolish")

-- Autocommands get executed without `smagic` so I make sure that I explicitly specify it on the
-- commandline so if my autocommand has a substitute command it will use `smagic`.
vim.keymap.set({ "ca" }, "s", function()
  local cmdline = vim.fn.getcmdline()
  if vim.fn.getcmdtype() == ":" and (cmdline == "s" or cmdline == [['<,'>s]]) then
    return "smagic"
  else
    return "s"
  end
end, { expr = true })
-- TODO: I can't get this to work as part of the above mapping for some reason.
vim.keymap.set({ "ca" }, "%s", function()
  if vim.fn.getcmdtype() == ":" and vim.fn.getcmdline() == "%s" then
    return "%smagic"
  else
    return "%s"
  end
end, { expr = true })
-- }}}
