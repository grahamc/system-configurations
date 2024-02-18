-- vim:foldmethod=marker

-- for the globals defined by mini.nvim
---@diagnostic disable: undefined-global

-- Copy up to the end of line, not including the newline character
vim.keymap.set({ "n" }, "Y", "yg_", {
  desc = "Til end of line, excluding newline",
})

Plug("arthurxavierx/vim-caser")

-- Formatting {{{
local utilities = require("base.utilities")

-- TODO: If you use direnv to add your formatters to the $PATH, you have to launch vscode
-- from the terminal for it to find the formatters. More on this in my notes.
Plug("stevearc/conform.nvim", {
  -- So when I use my conform executable, my config will be called before I call format()
  sync = true,

  config = function()
    local conform = require("conform")

    local function format_region(start_mark, end_mark)
      local enter_key = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
      local escape_key = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
      local command = string.format(
        [[%s:silent %s,%s!conform %s %s%s]],
        escape_key,
        start_mark,
        end_mark,
        vim.bo.filetype,
        vim.api.nvim_buf_get_name(0),
        enter_key
      )
      vim.api.nvim_feedkeys(command, "n", true)
    end

    vim.keymap.set("x", "gf", function()
      format_region("'<", "'>")
    end, { desc = "Format code", silent = true })

    _G.FormatCodeOperatorFunc = function()
      format_region("'[", "']")
    end
    vim.keymap.set("n", "gf", function()
      vim.o.operatorfunc = "v:lua.FormatCodeOperatorFunc"
      return "g@"
    end, { expr = true, desc = "Format code", silent = true })

    -- run only the first available formatter
    local prettier = { { "prettierd", "prettier" } }
    local util = require("conform.util")
    conform.setup({
      formatters = {
        -- TODO: Made 2 changes to the default shfmt config that should probably be upstreamed:
        -- 1. add another '-' to '-filename'. A single dash works, but I don't see it documented
        -- anywhere
        -- 2. set a CWD so shfmt can pick up editor config settings
        shfmt = {
          inherit = false,
          meta = {
            url = "https://github.com/mvdan/sh",
            description = "A shell parser, formatter, and interpreter with `bash` support.",
          },
          command = "shfmt",
          args = { "--filename", "$FILENAME" },
          cwd = util.root_file({ ".editorconfig" }),
        },
      },
      formatters_by_ft = {
        ["*"] = { "injected" },
        ["_"] = { "trim_whitespace", "squeeze_blanks" },
        lua = { "stylua" },
        -- run multiple formatters sequentially
        python = { "usort", "black" },
        sh = { "shfmt" },
        fish = { "fish_indent" },
        nix = { "alejandra" },
        just = { "just" },
        go = { "gofmt" },
        javascript = prettier,
        javascriptreact = prettier,
        json = prettier,
        markdown = prettier,
        yaml = prettier,
        css = prettier,
        html = prettier,
        typescriptreact = prettier,
        typescript = prettier,
        scss = prettier,
      },
    })
  end,
})

vim.api.nvim_create_autocmd("BufNew", {
  callback = function()
    vim.bo.textwidth = utilities.get_max_line_length()
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
  local formatprg = string.format(
    "par -w%d",
    vim.bo.textwidth == 0 and utilities.get_max_line_length() or vim.bo.textwidth
  )

  local _, newline_count = string.gsub(text, "\n", "")
  local is_one_line = newline_count == 0
  -- For single lines `par` can't infer what the commentstring is so I'm explicitly setting it here.
  if is_one_line then
    local commentstring = get_commentstring()
    local index_of_commentstring = (string.find(text, (utilities.escape_percent(commentstring))))
    if index_of_commentstring ~= nil then
      local prefix = index_of_commentstring + #commentstring
      formatprg = formatprg .. string.format(" -p%d", prefix)
    end
  end

  vim.bo.formatexpr = ""
  vim.bo.formatprg = formatprg
end

local function get_text_for_motion()
  local start_line = vim.fn.line("'[")
  local end_line = vim.fn.line("']")
  if start_line == nil or end_line == nil then
    return ""
  end
  -- TODO: This assumes entire lines are selected
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, true)
  return table.concat(lines, "\n")
end

-- format comment under cursor
_G.FormatCommentOperatorFunc = function()
  set_formatprg(get_text_for_motion())
  vim.cmd("normal! '[gq']")
end
vim.keymap.set("n", "gq", function()
  vim.o.operatorfunc = "v:lua.FormatCommentOperatorFunc"
  return "g@ic"
end, { expr = true, remap = true, desc = "Format comment" })

-- format visual selection
vim.keymap.set("x", "gq", function()
  set_formatprg(utilities.get_visual_selection())
  -- NOTE: This function returns after enqueuing the keys, not processing them. That is why I'm
  -- leaving the formatprg set.
  vim.fn.feedkeys("gvgq", "n")
end, {
  desc = "Format comment",
})
-- }}}

-- Extend the types of text that can be incremented/decremented {{{
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
        symbols("!==", "==="),
        symbols("<", ">"),
        symbols("<=", ">="),
        symbols("+=", "-="),
      },
    })
  end,
})
vim.keymap.set({ "n", "v" }, "+", "<Plug>(dial-increment)", {
  desc = "Increment",
})
vim.keymap.set({ "n", "v" }, "-", "<Plug>(dial-decrement)", {
  desc = "Decrement",
})
vim.keymap.set("v", "g+", "g<Plug>(dial-increment)", {
  desc = "Increment",
})
vim.keymap.set("v", "g-", "g<Plug>(dial-decrement)", {
  desc = "Decrement",
})
-- }}}

-- Split/Join {{{
--
-- fallback for treesj
Plug("AndrewRadev/splitjoin.vim")
vim.g.splitjoin_split_mapping = ""
vim.g.splitjoin_join_mapping = ""

Plug("Wansmer/treesj", {
  config = function()
    require("treesj").setup({
      use_default_keymaps = false,
      max_join_length = 200,
    })

    -- fallback to splitjoin.vim for unsupported languages
    local langs = require("treesj.langs")["presets"]
    vim.api.nvim_create_autocmd({ "FileType" }, {
      group = vim.api.nvim_create_augroup("bigolu/treesj", {}),
      callback = function()
        if langs[vim.bo.filetype] then
          vim.keymap.set(
            "n",
            "ss",
            vim.cmd.TSJToggle,
            { desc = "Toggle split/join", buffer = true }
          )
          vim.keymap.set("n", "sS", function()
            require("treesj").toggle({ join = { recursive = true }, split = { recursive = true } })
          end, { desc = "Toggle recursive split/join", buffer = true })
        else
          vim.keymap.set("n", "ss", vim.cmd.SplitjoinSplit, { desc = "Split", buffer = true })
          -- Must be used on the first line of the split
          vim.keymap.set("n", "sj", vim.cmd.SplitjoinJoin, { desc = "Join", buffer = true })
        end
      end,
    })
  end,
})
-- }}}
