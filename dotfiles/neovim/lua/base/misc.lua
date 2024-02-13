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
vim.o.clipboard = "unnamedplus"
Plug("tpope/vim-repeat")

-- Prevents inserting two spaces after punctuation on a join (J)
vim.o.joinspaces = false

-- Enter a newline above or below the current line.
vim.keymap.set({ "n" }, "<Enter>", "o<ESC>", {
  desc = "Insert newline above",
})
-- TODO: This won't work until tmux can differentiate between enter and shift+enter.
-- tmux issue: https://github.com/tmux/tmux/issues/2705#issuecomment-841133549
vim.keymap.set({ "n" }, "<S-Enter>", "O<ESC>", {
  desc = "Insert newline below",
})

-- paste {{{
-- * re-indent the pasted text which will also move me to the end of the text.
-- * set markers for the start and end of the pasted text so I can reselect it.
-- * when pasting from visual mode, it won't overwrite the clipboard.
-- * if the clipboard has multiple lines it, make sure it ends in a newline so we get vim's
-- visual-line yank behavior even with text copied outside of vim.
function MyPaste(was_in_visual_mode, is_capital_p)
  local clipboard_contents = vim.fn.getreg(vim.v.register) or ""
  local is_multi_line_paste = clipboard_contents:find("\n")

  -- set globals with the region of the pasted text so I can select it with 'gp' (above).
  -- People usually use `[ and `] for this, but that gives you the region of the last changed
  -- text and since I use autosave, it will always be the entire buffer.
  --
  -- TODO: I should post this somewhere since I know I've seen this question asked.
  --
  -- TODO: Need to add support for counts, right now it ignores it
  if is_multi_line_paste then
    -- When you yank multiple lines in vim it always appends a newline to the end so the lines don't
    -- interleave with the text where you paste. I'm doing that here as well to account for text
    -- that is copied outside of vim.
    if clipboard_contents:sub(-1) ~= "\n" then
      clipboard_contents = clipboard_contents .. "\n"
      ---@diagnostic disable-next-line: param-type-mismatch
      vim.fn.setreg(vim.v.register, "\n", "a")
    end
    local _, newline_count = clipboard_contents:gsub("\n", "")

    -- set start
    LastPasteStartLine = nil
    LastPasteStartCol = 0
    if was_in_visual_mode then
      LastPasteStartLine = vim.fn.line("'<") or 0
    else
      if is_capital_p then
        LastPasteStartLine = vim.fn.line(".")
      else
        LastPasteStartLine = vim.fn.line(".") + 1
      end
    end

    -- set end
    LastPasteEndLine = (LastPasteStartLine + newline_count) - 1
    LastPasteEndCol = vim.fn.col({ LastPasteEndLine, "$" }) or 0
  else
    -- set start
    LastPasteStartLine = vim.fn.line(".") or 0
    LastPasteStartCol = 0
    if was_in_visual_mode then
      LastPasteStartCol = vim.fn.col("'<") - 1
    else
      if is_capital_p then
        LastPasteStartCol = vim.fn.col(".") - 1 or 0
      else
        LastPasteStartCol = vim.fn.col(".") or 0
      end
    end

    -- set end
    local clipboard_length = #clipboard_contents
    LastPasteEndLine = LastPasteStartLine
    LastPasteEndCol = (LastPasteStartCol + clipboard_length) - 1
  end

  local key = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
  local indent = string.format([[:%d,%dnormal! ==]] .. key, LastPasteStartLine, LastPasteEndLine)
  local go_back_to_visual = was_in_visual_mode and "gv" or ""
  local delete_into_blackhole = was_in_visual_mode and '"_d' or ""
  local paste = [["]] .. vim.v.register .. (is_capital_p and "P" or "p")
  vim.api.nvim_feedkeys(go_back_to_visual .. delete_into_blackhole .. paste .. indent, "n", false)
end
vim.keymap.set({ "n" }, "p", ":lua MyPaste(false, false)<CR>", { silent = true })
-- In visual mode p should behave like P
vim.keymap.set({ "x" }, "p", "P", { silent = true, remap = true })
vim.keymap.set({ "n" }, "P", ":lua MyPaste(false, true)<CR>", { silent = true })
-- Leave visual mode so '< and '> get set
vim.keymap.set({ "x" }, "P", "<Esc>:lua MyPaste(true, true)<CR>", { silent = true })
-- }}}

-- leave cursor at the end of yanked text
vim.keymap.set({ "x" }, "y", "ygv<Esc>", { silent = true })

-- Disable features {{{
-- Disable unused builtin plugins.
local plugins_to_disable = {
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
      vim.opt_local.keywordprg = ":Help"
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
