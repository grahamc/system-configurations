-- vim:foldmethod=marker
---@diagnostic disable: undefined-global
-- This is so I can assign variables to `vim.b`
---@diagnostic disable: inject-field

-- Miscellaneous {{{
vim.opt.nrformats:remove("octal")
vim.o.timeout = true
vim.o.timeoutlen = 500
vim.o.updatetime = 500
vim.o.swapfile = false
vim.o.fileformats = "unix,dos,mac"
vim.o.paragraphs = ""
vim.o.sections = ""

local extend_is_keyword_group_id = vim.api.nvim_create_augroup("ExtendIskeyword", {})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "txt",
  callback = function()
    vim.opt_local.iskeyword:append("_")
  end,
  group = extend_is_keyword_group_id,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "tmux",
  callback = function()
    vim.opt_local.iskeyword:append("-")
  end,
  group = extend_is_keyword_group_id,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "css",
    "scss",
    "javascriptreact",
    "typescriptreact",
    "javascript",
    "typescript",
    "sass",
    "postcss",
  },
  callback = function()
    vim.opt_local.iskeyword:append("-,?,!")
  end,
  group = extend_is_keyword_group_id,
})

vim.keymap.set({ "i" }, "jk", "<Esc>")

-- 1. re-indent the pasted text
-- 2. move to the end of the pasted text
vim.keymap.set({ "n" }, "p", "p=`]", { silent = true })

-- select the text that was just pasted
vim.keymap.set({ "n" }, "gV", "`[v`]")

-- move to left and right side of last selection
vim.keymap.set({ "n" }, "[v", "'<")
vim.keymap.set({ "n" }, "]v", "'>")

-- Prevents inserting two spaces after punctuation on a join (J)
vim.o.joinspaces = false

vim.opt.matchpairs:append("<:>")

-- Always move by screen line, unless a count was specified or we're in a line-wise mode.
local function move_by_screen_line(direction)
  local mode = vim.fn.mode()
  local is_in_linewise_mode = mode == "V" or mode == ""
  if is_in_linewise_mode then
    return direction
  end

  if vim.v.count > 0 then
    return direction
  end

  return "g" .. direction
end
vim.keymap.set({ "n", "x" }, "j", function()
  return move_by_screen_line("j")
end, { expr = true })
vim.keymap.set({ "n", "x" }, "k", function()
  return move_by_screen_line("k")
end, { expr = true })

-- move six lines at a time by holding ctrl and a directional key. Reasoning for using 6 here:
-- https://nanotipsforvim.prose.sh/vertical-navigation-%E2%80%93-without-relative-line-numbers
vim.keymap.set({ "n", "x" }, "<C-j>", "6j")
vim.keymap.set({ "n", "x" }, "<C-k>", "6k")

-- move ten columns at a time by holding ctrl and a directional key
vim.keymap.set({ "n", "x" }, "<C-h>", "6h")
vim.keymap.set({ "n", "x" }, "<C-l>", "6l")

-- Copy up to the end of line, not including the newline character
vim.keymap.set({ "n" }, "Y", "yg_")

-- Using the paragraph motions won't add to the jump stack
vim.keymap.set({ "n" }, "}", [[<Cmd>keepjumps normal! }<CR>]])
vim.keymap.set({ "n" }, "{", [[<Cmd>keepjumps normal! {<CR>]])

-- 'n' always searches forwards, 'N' always searches backwards
vim.keymap.set({ "n", "x", "o" }, "n", "'Nn'[v:searchforward]", { expr = true })
vim.keymap.set({ "n", "x", "o" }, "N", "'nN'[v:searchforward]", { expr = true })

-- Enter a newline above or below the current line.
vim.keymap.set({ "n" }, "<Enter>", "o<ESC>")

-- TODO: This won't work until tmux can differentiate between enter and shift+enter.
-- tmux issue: https://github.com/tmux/tmux/issues/2705#issuecomment-841133549
vim.keymap.set({ "n" }, "<S-Enter>", "O<ESC>")

-- Disable language providers. Feels like a lot of trouble to install neovim bindings for all these
-- languages so I'll just avoid plugins that require them. By disabling the providers, I won't get a
-- warning about missing bindings when I run `:checkhealth`.
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0

vim.keymap.set({ "n" }, "Q", "<Nop>")

-- Execute macros more quickly by enabling `lazyredraw` and disabling events while the macro is
-- running
local function get_char()
  local ret_val, char_num = pcall(vim.fn.getchar)
  -- Return nil if error (e.g. <C-c>) or for control characters
  if not ret_val or char_num < 32 then
    return nil
  end
  local char = vim.fn.nr2char(char_num)

  return char
end
local function fast_macro()
  local mode = vim.fn.mode()
  local count = vim.v.count1
  vim.cmd('execute "normal \\<Esc>"')

  local range = ""
  for _, visual_mode in pairs({ "v", "V", "" }) do
    if mode == visual_mode then
      range = [['<,'>]]
      break
    end
  end

  local register = get_char()
  if register == nil then
    return
  end

  vim.o.eventignore = "all"
  vim.o.lazyredraw = true
  vim.cmd(string.format(
    -- Execute silently so I don't get prompted to press enter if an error is thrown. For example, when I use
    -- substitute and there is no match.
    [[silent! %snormal! %s@%s]],
    range,
    count,
    register
  ))
  vim.o.eventignore = ""
  vim.o.lazyredraw = false
end
vim.keymap.set({ "x", "n" }, "@", fast_macro)
local fast_macro_group_id = vim.api.nvim_create_augroup("FastMacro", {})
vim.api.nvim_create_autocmd("RecordingEnter", {
  callback = function()
    if _G.fast_macro_events == nil then
      local events = vim.fn.getcompletion("", "event")

      for index, event in ipairs(events) do
        if event == "RecordingLeave" then
          table.remove(events, index)
          break
        end
      end

      _G.fast_macro_events = table.concat(events, ",")
    end

    vim.g.old_eventignore = vim.o.eventignore
    vim.o.eventignore = _G.fast_macro_events
  end,
  group = fast_macro_group_id,
})
vim.api.nvim_create_autocmd("RecordingLeave", {
  callback = function()
    vim.o.eventignore = vim.g.old_eventignore
  end,
  group = fast_macro_group_id,
})

vim.o.clipboard = "unnamedplus"

-- Move to beginning and end of line
vim.keymap.set({ "n" }, "<C-a>", "^")
vim.keymap.set({ "n" }, "<C-e>", "$")
vim.keymap.set({ "i" }, "<C-a>", "<ESC>^i")
vim.keymap.set({ "i" }, "<C-e>", "<ESC>$a")

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = ".envrc",
  callback = function()
    vim.opt_local.filetype = "sh"
  end,
  group = vim.api.nvim_create_augroup("Filetype Associations", {}),
})

-- Autocommands get executed without `smagic` so I make sure that I explicitly specify it on the commandline
-- so if my autocommand has a substitute command it will use `smagic`.
SmagicAbbreviation = function()
  local cmdline = vim.fn.getcmdline()
  if vim.fn.getcmdtype() == ":" and cmdline == "s" or cmdline == [['<,'>s]] then
    return "smagic"
  end

  return "s"
end
vim.cmd([[
  cnoreabbrev <expr> s v:lua.SmagicAbbreviation()
  cnoreabbrev <expr> %s getcmdtype() == ':' && getcmdline() == '%s' ? '%smagic' : '%s'
]])

-- Comment formatting
vim.api.nvim_create_autocmd({ "Filetype" }, {
  pattern = "nix",
  callback = function()
    vim.bo.commentstring = "# %s"
  end,
  group = vim.api.nvim_create_augroup("Nix commentstring", {}),
})
vim.api.nvim_create_autocmd("BufNew", {
  pattern = "*",
  callback = function()
    vim.bo.textwidth = _G.GetMaxLineLength()
  end,
  group = vim.api.nvim_create_augroup("Set textwidth", {}),
})
-- removes '%s' and trims trailing whitespace
local function get_commentstring()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  cursor_pos[1] = cursor_pos[1] + 1
  local commentstring = MiniComment.get_commentstring(cursor_pos)

  local index_of_s = (string.find(commentstring, "%%s"))
  if index_of_s then
    return string.sub(commentstring, 1, index_of_s - 1):gsub("^%s*(.-)%s*$", "%1")
  else
    return commentstring
  end
end
local function set_formatprg(text)
  local formatprg =
    string.format("par -w%d", vim.bo.textwidth == 0 and GetMaxLineLength() or vim.bo.textwidth)

  local _, newline_count = string.gsub(text, "\n", "")
  local is_one_line = newline_count == 0
  -- For single lines `par` can't infer what the commentstring is so I'm explicitly setting it
  -- here.
  if is_one_line then
    local commentstring = get_commentstring()
    local index_of_commentstring = (string.find(text, (commentstring:gsub("([^%w])", "%%%1"))))
    if index_of_commentstring ~= nil then
      local prefix = index_of_commentstring + #commentstring
      formatprg = formatprg .. string.format(" -p%d", prefix)
    end
  end

  vim.bo.formatexpr = ""
  vim.bo.formatprg = formatprg
end
-- TODO: This assumes entire lines are selected
local function get_text_for_motion()
  local lines = vim.api.nvim_buf_get_lines(0, vim.fn.line("'[") - 1, vim.fn.line("']"), true)
  return table.concat(lines, "\n")
end
_G.FormatCommentOperatorFunc = function()
  set_formatprg(get_text_for_motion())
  vim.cmd("normal! '[gq']")
end
local function format_comment_operator()
  vim.o.operatorfunc = "v:lua.FormatCommentOperatorFunc"
  return "g@ic"
end
vim.keymap.set("n", "gq", format_comment_operator, { expr = true, remap = true })
local function format_comment_visual()
  set_formatprg(GetVisualSelection())
  -- NOTE: This function returns after enqueuing the keys, not processing them. That is why I'm
  -- leaving the formatprg set.
  vim.fn.feedkeys("gvgq", "n")
end
vim.keymap.set("x", "gq", format_comment_visual, {})

vim.keymap.set({ "n", "x" }, "]p", "}", { remap = true })
vim.keymap.set({ "n", "x" }, "[p", "{", { remap = true })
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

-- Searching {{{
-- searching is only case-sensitive when the query contains an uppercase letter
vim.o.ignorecase = true
vim.o.smartcase = true

-- Use ripgrep as the grep program, if it's available. Otherwise, use the internal
-- grep implementation since it's cross-platform
vim.o.grepprg = vim.fn.executable("rg") and "rg --vimgrep --smart-case --follow" or "internal"

-- Search for selected text, forwards or backwards.
vim.keymap.set(
  { "v" },
  "*",
  [[:<C-U>let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>gvy/<C-R>=&ic?'\c':'\C'<CR><C-R><C-R>=substitute(escape(@", '/\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>gVzv:call setreg('"', old_reg, old_regtype)<CR>]],
  { silent = true }
)
vim.keymap.set(
  { "v" },
  "#",
  [[:<C-U>let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>gvy?<C-R>=&ic?'\c':'\C'<CR><C-R><C-R>=substitute(escape(@", '?\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>gVzv:call setreg('"', old_reg, old_regtype)<CR>]],
  { silent = true }
)
-- }}}

-- Plugins {{{
-- Motions for levels of indentation
Plug("jeetsukumaran/vim-indentwise", {
  config = function()
    vim.keymap.set("", "[-", "<Plug>(IndentWisePreviousLesserIndent)", { remap = true })
    vim.keymap.set("", "[+", "<Plug>(IndentWisePreviousGreaterIndent)", { remap = true })
    vim.keymap.set("", "[=", "<Plug>(IndentWisePreviousEqualIndent)", { remap = true })
    vim.keymap.set("", "]-", "<Plug>(IndentWiseNextLesserIndent)", { remap = true })
    vim.keymap.set("", "]+", "<Plug>(IndentWiseNextGreaterIndent)", { remap = true })
    vim.keymap.set("", "]=", "<Plug>(IndentWiseNextEqualIndent)", { remap = true })
  end,
})
vim.g.indentwise_suppress_keymaps = 1

-- replacement for matchit since matchit wasn't working for me
Plug("andymass/vim-matchup")
-- Don't display off-screen matches in my statusline or a popup window
vim.g.matchup_matchparen_offscreen = {}

Plug("bkad/CamelCaseMotion")
vim.g.camelcasemotion_key = ","

-- Commands/mappings for working with variants of words:
-- - A command for performing substitutions. More features than vim's built-in :substitution
-- - A command for creating abbreviations. More features than vim's built-in `:iabbrev`
-- - Mappings for case switching e.g. mixed-case, title-case, etc.
Plug("tpope/vim-abolish")

-- Extend the types of text that can be incremented/decremented
Plug("monaqa/dial.nvim", {
  on = { "<Plug>(dial-increment)", "<Plug>(dial-decrement)" },
  config = function()
    local augend = require("dial.augend")

    local function words(...)
      return augend.constant.new({
        elements = { ... },
        word = true,
        cyclic = true,
      })
    end

    local function symbols(...)
      return augend.constant.new({
        elements = { ... },
        word = false,
        cyclic = true,
      })
    end

    require("dial.config").augends:register_group({
      default = {
        -- color: #ffffff
        -- NOTE: If the cursor is over one of the two digits in the red, green, or blue value, it
        -- only increments that color of the hex. To increment the red, green, and blue portions,
        -- the cursor must be over the '#'.
        augend.hexcolor.new({}),
        -- time: 14:30:00
        augend.date.alias["%H:%M:%S"],
        -- time: 14:30
        augend.date.alias["%H:%M"],
        -- decimal integer: 0, 4, -123
        augend.integer.alias.decimal_int,
        -- hex: 0x00
        augend.integer.alias.hex,
        -- binary: 0b0101
        augend.integer.alias.binary,
        -- octal: 0o00
        augend.integer.alias.octal,
        -- Semantic Versioning: 1.22.1
        augend.semver.alias.semver,
        -- uppercase letter: A
        augend.constant.alias.Alpha,
        -- lowercase letter: a
        augend.constant.alias.alpha,
        words("and", "or"),
        words("public", "private"),
        words("true", "false"),
        words("True", "False"),
        words("yes", "no"),
        symbols("&&", "||"),
        symbols("!=", "=="),
        symbols("<", ">"),
        symbols("<=", ">="),
        symbols("+=", "-="),
      },
    })
  end,
})
vim.keymap.set({ "n", "v" }, "+", "<Plug>(dial-increment)")
vim.keymap.set({ "n", "v" }, "-", "<Plug>(dial-decrement)")
vim.keymap.set("v", "g+", "g<Plug>(dial-increment)")
vim.keymap.set("v", "g-", "g<Plug>(dial-decrement)")

Plug("arthurxavierx/vim-caser")

-- TODO: Some of this should only be configured when neovim is running in the terminal.
Plug("nvim-treesitter/nvim-treesitter", {
  config = function()
    require("nvim-treesitter.configs").setup({
      auto_install = false,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      incremental_selection = {
        enable = false,
      },
      indent = {
        enable = false,
      },
      matchup = {
        enable = true,
        disable_virtual_text = true,
        include_match_words = true,
      },
      endwise = {
        enable = true,
      },
      autotag = {
        enable = true,
      },
    })

    local function maybe_set_treesitter_foldmethod()
      local foldmethod = vim.o.foldmethod
      local is_foldmethod_overridable = foldmethod ~= "manual"
        and foldmethod ~= "marker"
        and foldmethod ~= "diff"
        and foldmethod ~= "expr"
      if require("nvim-treesitter.parsers").has_parser() and is_foldmethod_overridable then
        vim.o.foldmethod = "expr"
        vim.o.foldexpr = "nvim_treesitter#foldexpr()"
      end
    end
    vim.api.nvim_create_autocmd({ "FileType" }, {
      callback = maybe_set_treesitter_foldmethod,
      group = vim.api.nvim_create_augroup("TreesitterFoldmethod", {}),
    })
  end,
})

Plug("nvim-treesitter/nvim-treesitter-textobjects")

-- TODO: Some of this only applies when neovim is running in the terminal
Plug("echasnovski/mini.nvim", {
  -- Load synchronously for cursor restoration
  sync = true,

  config = function()
    require("mini.comment").setup({
      options = {
        ignore_blank_line = true,
      },

      mappings = {
        textobject = "ic",
      },
    })

    local spec_treesitter = require("mini.ai").gen_spec.treesitter
    require("mini.ai").setup({
      custom_textobjects = {
        d = spec_treesitter({ a = "@function.outer", i = "@function.inner" }),
        C = spec_treesitter({ a = "@conditional.outer", i = "@conditional.inner" }),
        s = spec_treesitter({ a = "@assignment.lhs", i = "@assignment.rhs" }),
      },
      silent = true,
    })
    local function move_like_curly_brace(id, direction)
      local old_position = vim.api.nvim_win_get_cursor(0)
      MiniAi.move_cursor(direction, "a", id, {
        search_method = (direction == "left") and "cover_or_prev" or "cover_or_next",
      })
      local new_position = vim.api.nvim_win_get_cursor(0)
      local has_cursor_moved = old_position[0] ~= new_position[0]
        or old_position[1] ~= new_position[1]
      if has_cursor_moved then
        vim.cmd(string.format([[normal! %s]], direction == "left" and "k" or "j"))
      end
    end
    vim.keymap.set({ "n", "x" }, "]d", function()
      move_like_curly_brace("d", "right")
    end)
    vim.keymap.set({ "n", "x" }, "[d", function()
      move_like_curly_brace("d", "left")
    end)

    require("mini.operators").setup({
      evaluate = { prefix = "" },
      multiply = { prefix = "" },
      replace = { prefix = "" },
      exchange = { prefix = "gx" },
      sort = { prefix = "so" },
    })

    require("mini.indentscope").setup({
      mappings = {
        object_scope = "iI",
        object_scope_with_border = "aI",
        goto_top = "[I",
        goto_bottom = "]I",
      },
      symbol = "┊",
    })
    local new_opts = {
      options = { indent_at_cursor = false },
    }
    local function run_without_indent_at_cursor(fn)
      local old_opts = vim.b.miniindentscope_config
      if old_opts ~= nil then
        vim.b.miniindentscope_config = vim.tbl_deep_extend("force", old_opts, new_opts)
      else
        vim.b.miniindentscope_config = new_opts
      end
      fn()
      vim.b.miniindentscope_config = old_opts
    end
    vim.keymap.set({ "o", "x" }, "ii", function()
      run_without_indent_at_cursor(MiniIndentscope.textobject)
    end)
    vim.keymap.set({ "o", "x" }, "ai", function()
      run_without_indent_at_cursor(function()
        MiniIndentscope.textobject(true)
      end)
    end)
    vim.keymap.set({ "n", "x" }, "[i", function()
      run_without_indent_at_cursor(function()
        MiniIndentscope.move_cursor("top", false)
      end)
    end)
    vim.keymap.set({ "n", "x" }, "]i", function()
      run_without_indent_at_cursor(function()
        MiniIndentscope.move_cursor("bottom", false)
      end)
    end)
    local mini_group_id = vim.api.nvim_create_augroup("MyMiniNvim", {})
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "python", "yaml" },
      callback = function()
        vim.b.miniindentscope_config = {
          options = {
            border = "top",
          },
        }
      end,
      group = mini_group_id,
    })
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "man", "aerial" },
      callback = function()
        vim.b.miniindentscope_disable = true
        vim.b.miniindentscope_disable_permanent = true
      end,
      group = mini_group_id,
    })
    -- TODO: I want to disable this per window, but mini only supports disabling per buffer
    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "*",
      callback = function()
        if not vim.b.miniindentscope_disable_permanent then
          vim.b.miniindentscope_disable = false
        end
      end,
      group = mini_group_id,
    })
    vim.api.nvim_create_autocmd("BufLeave", {
      pattern = "*",
      callback = function()
        vim.b.miniindentscope_disable = true
      end,
      group = mini_group_id,
    })

    require("mini.surround").setup({
      n_lines = 50,
      search_method = "cover_or_next",
      silent = true,
    })

    require("mini.misc").setup_restore_cursor({
      center = false,
    })

    require("mini.animate").setup({
      cursor = {
        timing = require("mini.animate").gen_timing.exponential({
          duration = 7,
          easing = "out",
          unit = "step",
        }),
      },
      resize = {
        timing = require("mini.animate").gen_timing.linear({ duration = 100, unit = "total" }),
      },
      scroll = {
        enable = false,
      },
      open = {
        enable = false,
      },
      close = {
        enable = false,
      },
    })

    require("mini.jump").setup({
      mappings = {
        repeat_jump = "",
      },
      delay = {
        highlight = 10000000,
        idle_stop = 10000000,
      },
    })

    require("mini.jump2d").setup({
      mappings = {
        start_jumping = ";",
      },

      view = {
        dim = true,
        n_steps_ahead = 0,
      },

      allowed_windows = {
        not_current = false,
      },

      silent = true,
    })

    require("mini.cursorword").setup()
    -- Don't highlight keywords
    vim.api.nvim_create_autocmd("CursorMoved", {
      pattern = "*",
      callback = function()
        if vim.b.minicursorword_disable_permanent then
          return
        end

        local captures = vim.treesitter.get_captures_at_cursor()
        for _, capture in ipairs(captures) do
          if string.find(capture, "keyword") then
            vim.b.minicursorword_disable = true
            return
          end
        end
        vim.b.minicursorword_disable = false
      end,
      group = mini_group_id,
    })
  end,
})

Plug("tpope/vim-repeat")

-- For filetype detection
Plug("NoahTheDuke/vim-just")
-- }}}
