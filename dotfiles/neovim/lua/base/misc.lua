-- vim:foldmethod=marker

vim.o.timeout = false
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
vim.keymap.set({ "n" }, "<S-Enter>", "O<ESC>", {
  desc = "Insert newline below",
})

vim.keymap.set({ "n" }, "gF", "gf", {
  desc = "Go to file [jump]",
})

-- leave cursor at the end of yanked text
vim.keymap.set({ "x" }, "y", "ygv<Esc>", { silent = true })

-- paste {{{
-- * re-indent the pasted text which will also move me to the end of the text.
-- * set markers for the start and end of the pasted text so I can reselect it.
-- * when pasting from visual mode, it won't overwrite the clipboard.
-- * if the register has multiple lines it, make sure it ends in a newline so we
--   get vim's visual-line yank behavior even with text copied outside of vim.
-- * set lazyredraw while mapping is running for speed
function MyPaste(was_in_visual_mode, is_capital_p)
  ---@diagnostic disable-next-line: undefined-global
  local register = was_in_visual_mode and LastReg or vim.v.register
  local register_contents = vim.fn.getreg(register) or ""
  ---@diagnostic disable-next-line: undefined-global
  local count = was_in_visual_mode and LastCount or vim.v.count1
  local is_multi_line_paste = register_contents:find("\n")

  -- set globals with the region of the pasted text so I can select it with 'gp'
  -- (above).  People usually use `[ and `] for this, but that gives you the
  -- region of the last changed text and since I use autosave, it will always be
  -- the entire buffer.
  --
  -- TODO: I should post this somewhere since I know I've seen this question
  -- asked.
  if is_multi_line_paste then
    -- When you yank multiple lines in vim it always appends a newline to the
    -- end so the lines don't interleave with the text where you paste. I'm
    -- doing that here as well to account for text that is copied outside of
    -- vim.
    if register_contents:sub(-1) ~= "\n" then
      register_contents = register_contents .. "\n"
      ---@diagnostic disable-next-line: param-type-mismatch
      vim.fn.setreg(register, "\n", "a")
    end
    local _, newline_count = register_contents:gsub("\n", "")

    -- set start
    LastPasteStartLine = nil
    -- won't matter since the paste textobject will use visual line
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
    LastPasteEndLine = (LastPasteStartLine + (newline_count * count)) - 1
    -- won't matter since the paste textobject will use visual line
    LastPasteEndCol = 0
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
        -- whether the line is is empty or has one char, col() return 1 so we
        -- need to use 0 if the line is empty.
        LastPasteStartCol = (#vim.fn.getline(".") == 0) and 0 or vim.fn.col(".")
      end
    end

    -- set end
    local register_contents_length = #register_contents * count
    LastPasteEndLine = LastPasteStartLine
    LastPasteEndCol = (LastPasteStartCol + register_contents_length) - 1
  end

  local enter_key = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
  local set_lazy_redraw = ":set lazyredraw" .. enter_key
  local unset_lazy_redraw = ":set nolazyredraw" .. enter_key
  local indent = is_multi_line_paste
      and string.format(
        [[:%d,%dnormal! ==]] .. enter_key,
        LastPasteStartLine,
        LastPasteEndLine
      )
    or ""
  local go_back_to_visual = was_in_visual_mode and "gv" or ""
  local delete_into_blackhole = was_in_visual_mode and '"_d' or ""
  local paste = count
    .. [["]]
    .. register
    .. (
      (
                    -- Special case for single line pastes in visual mode at the end of the line or multi-line
          -- pastes in visual mode at the end of the document. They must use 'p'
(
            was_in_visual_mode
            and not is_multi_line_paste
            and (
              vim.fn.col("'>") == (vim.fn.col({ LastPasteEndLine, "$" }) - 1)
            )
          )
          or (
            was_in_visual_mode
            and is_multi_line_paste
            and (vim.fn.line("'>") == (vim.fn.line("$")))
          )
        )
        and "p"
      or (is_capital_p and "P" or "p")
    )
  vim.api.nvim_feedkeys(
    set_lazy_redraw
      .. go_back_to_visual
      .. delete_into_blackhole
      .. paste
      .. indent
      .. unset_lazy_redraw,
    "n",
    false
  )
end
vim.keymap.set({ "n" }, "p", function()
  MyPaste(false, false)
end, { silent = true })
-- In visual mode p should behave like P, unless the paste is at the end of the
-- document/line, but that gets handled in the paste function.
vim.keymap.set({ "x" }, "p", "P", { silent = true, remap = true })
vim.keymap.set({ "n" }, "P", function()
  MyPaste(false, true)
end, { silent = true })
-- Leave visual mode so '< and '> get set, but save the current register
-- beforehand
vim.keymap.set(
  { "x" },
  "P",
  "<Cmd>lua LastReg = vim.v.register; LastCount = vim.v.count1<CR><Esc>:lua MyPaste(true, true)<CR>",
  { silent = true }
)
-- }}}

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

-- Disable language providers. Feels like a lot of trouble to install neovim
-- bindings for all these languages so I'll just avoid plugins that require
-- them. By disabling the providers, I won't get a warning about missing
-- bindings when I run `:checkhealth`.
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
-- }}}

-- Option overrides {{{
-- Vim's default filetype plugins get run when filetype detection is enabled
-- (i.e. ':filetype plugin on'). So in order to override settings from vim's
-- filetype plugins, these FileType autocommands need to be registered after
-- filetype detection is enabled. File type detection is turned on in plug_end()
-- so this function gets called at `PlugEndPost`, which is right after
-- plug_end() is called.
local vim_default_overrides_group_id =
  vim.api.nvim_create_augroup("VimDefaultOverrides", {})
vim.api.nvim_create_autocmd("User", {
  pattern = "PlugEndPost",
  group = vim_default_overrides_group_id,
  callback = function()
    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        -- Don't automatically hard-wrap text
        vim.bo.wrapmargin = 0
        -- r: Automatically insert the current comment leader after hitting
        --   <Enter> in Insert mode.
        -- o: Automatically insert the current comment leader after hitting o/O
        --   in normal mode.
        -- /: Don't auto insert a comment leader if the comment is next to a
        --   statemnt.
        -- j: Remove comment leader when joining lines
        vim.bo.formatoptions = "ro/j"
      end,
      group = vim_default_overrides_group_id,
    })

    if IsRunningInTerminal then
      -- Use vim help pages for `keywordprg` in vim files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "vim",
        callback = function()
          vim.opt_local.keywordprg = ":Help"
        end,
        group = vim_default_overrides_group_id,
      })
    end
  end,
})
-- }}}

-- Substitutions {{{
-- Commands/mappings for working with variants of words. In particular I use its
-- 'S' command for performing substitutions. It has more features than vim's
-- built-in :substitution
Plug("tpope/vim-abolish", {
  on = "S",
})

-- Autocommands get executed without `smagic` so I make sure that I explicitly
-- specify it on the commandline so if my autocommand has a substitute command
-- it will use `smagic`.
vim.keymap.set({ "ca" }, "s", function()
  local cmdline = vim.fn.getcmdline()
  if
    vim.fn.getcmdtype() == ":" and (cmdline == "s" or cmdline == [['<,'>s]])
  then
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
