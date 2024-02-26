-- vim:foldmethod=marker

-- for the globals defined by mini.nvim
---@diagnostic disable: undefined-global

-- Copy up to the end of line, not including the newline character
vim.keymap.set({ "n" }, "Y", "yg_", {
  desc = "Til end of line, excluding newline",
})

vim.defer_fn(function()
  vim.fn["plug#load"]("vim-caser")
end, 0)
Plug("arthurxavierx/vim-caser", {
  on = {},
})

-- Exchange {{{
-- TODO: Using this instead of the one from mini.operators because the mini doesn't have dot-repeat.
Plug("tommcdo/vim-exchange")
vim.g.exchange_no_mappings = true
vim.g.exchange_indent = "=="
vim.keymap.set({ "n", "x" }, "gx", "<Plug>(Exchange)")
vim.keymap.set({ "n" }, "gxx", "<Plug>(ExchangeLine)")
vim.keymap.set({ "n" }, "<Esc>", "<Plug>(ExchangeClear)<ESC>")
-- }}}

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
      vim.api.nvim_feedkeys(command, "n", false)
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

    local prettier = { { "prettierd", "prettier" } }
    local formatters_by_ft = {
      ["*"] = { "injected" },
      ["_"] = { "trim_whitespace", "squeeze_blanks" },
      lua = { "stylua" },
      python = { "usort", "black" },
      sh = { "shfmt" },
      fish = { "fish_indent" },
      nix = { "alejandra" },
      just = { "just" },
      go = { "gofmt" },
      javascript = prettier,
      javascriptreact = prettier,
      typescript = prettier,
      typescriptreact = prettier,
      json = prettier,
      markdown = prettier,
      yaml = prettier,
      css = prettier,
      html = prettier,
      scss = prettier,
    }
    formatters_by_ft = vim.iter(formatters_by_ft):fold({}, function(acc, filetype, formatters)
      formatters = vim.deepcopy(formatters)
      if not vim.tbl_contains({ "*", "_" }, filetype) then
        local first = formatters[1]
        if type(first) == "table" then
          table.insert(first, 0, "dprint")
          table.insert(first, 0, "treefmt")
          formatters[1] = first
        else
          formatters[1] = { "treefmt", "dprint", first }
        end
      end
      acc[filetype] = formatters

      return acc
    end)

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

        -- TODO: should upstream this too
        treefmt = {
          inherit = false,
          stdin = true,
          meta = {
            url = "https://github.com/numtide/treefmt",
            description = "treefmt applies all the needed formatters to your project with one command line.",
          },
          command = "treefmt",
          args = { "--stdin", "$FILENAME" },
          require_cwd = true,
          cwd = util.root_file({ "treefmt.toml" }),
        },
      },
      formatters_by_ft = formatters_by_ft,
    })
  end,
})

vim.api.nvim_create_autocmd("BufNew", {
  callback = function()
    vim.bo.textwidth = utilities.get_max_line_length()
  end,
  group = vim.api.nvim_create_augroup("Set textwidth", {}),
})

local function get_commentstrings()
  return vim
    .iter(vim.opt.comments:get())
    :map(function(commentstring)
      local start_index, _ = commentstring:find(":")
      if start_index ~= nil then
        return commentstring:sub(start_index + 1)
      end
      return commentstring
    end)
    :totable()
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
    local commentstrings = get_commentstrings()
    table.sort(commentstrings, function(a, b)
      return #a < #b
    end)
    local longest_matching_commentstring = vim.iter(commentstrings):find(function(commentstring)
      -- TODO: can only be preceded by spaces
      local start, _ = text:find(commentstring, 1, true)
      return start ~= nil
    end)

    if longest_matching_commentstring ~= nil then
      local start_index_of_commentstring = text:find(longest_matching_commentstring, 1, true)
      local prefix = start_index_of_commentstring + #longest_matching_commentstring
      formatprg = formatprg .. string.format(" -p%d", prefix)
    else
      vim.notify(
        "Unable to detect the comment leader so the comment may not be formatted properly",
        vim.log.levels.ERROR
      )
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

    local defaults = {
      -- color: #ffffff
      -- NOTE: If the cursor is over one of the two digits in the red, green, or blue value, it
      -- only increments that color of the hex. To increment the red, green, and blue portions,
      -- the cursor must be over the '#'.
      hex_rgb = augend.hexcolor.new({}),
      -- time: 14:30:00
      date_hms = augend.date.alias["%H:%M:%S"],
      -- time: 14:30
      date_hm = augend.date.alias["%H:%M"],
      -- decimal integer: 0, 4, -123
      int = augend.integer.alias.decimal_int,
      -- hex: 0x00
      hex = augend.integer.alias.hex,
      -- binary: 0b0101
      binary = augend.integer.alias.binary,
      -- octal: 0o00
      octal = augend.integer.alias.octal,
      -- Semantic Versioning: 1.22.1
      semver = augend.semver.alias.semver,
      -- uppercase letter: A
      Alpha = augend.constant.alias.Alpha,
      -- lowercase letter: a
      alpha = augend.constant.alias.alpha,
      logical_word = words("and", "or"),
      visibility = words("public", "private"),
      boolean = words("true", "false"),
      Boolean = words("True", "False"),
      confirm = words("yes", "no"),
      logical_symbol = symbols("&&", "||"),
      equality = symbols("!=", "=="),
      strict_equality = symbols("!==", "==="),
      lt_gt = symbols("<", ">"),
      lte_gte = symbols("<=", ">="),
      inc_dec = symbols("+=", "-="),
    }

    local function make_table(acc, _, item)
      table.insert(acc, item)
      return acc
    end
    local function extend_defaults(tweaks)
      return require("base.utilities").table_concat(
        vim
          .iter(defaults)
          :filter(function(index, _)
            return not vim.tbl_contains(tweaks.remove or {}, index)
          end)
          :fold({}, make_table),
        tweaks.add or {}
      )
    end

    require("dial.config").augends:register_group({ default = vim.tbl_values(defaults) })

    local augends_for_js_based_languages = extend_defaults({
      add = {
        augend.constant.new({ elements = { "let", "const" } }),
      },
    })

    require("dial.config").augends:on_filetype({
      javascript = augends_for_js_based_languages,
      javascriptreact = augends_for_js_based_languages,
      typescript = augends_for_js_based_languages,
      typescriptreact = augends_for_js_based_languages,
      lua = extend_defaults({
        add = {
          symbols("~=", "=="),
        },
        remove = {
          "equality",
        },
      }),
      markdown = extend_defaults({
        add = {
          augend.misc.alias.markdown_header,
        },
      }),
    })
  end,
})

local is_dial_loaded = false
local function manipulate(...)
  if not is_dial_loaded then
    vim.fn["plug#load"]("dial.nvim")
    is_dial_loaded = true
  end

  return require("dial.map").manipulate(...)
end
vim.keymap.set("n", "+", function()
  manipulate("increment", "normal")
end)
vim.keymap.set("n", "-", function()
  manipulate("decrement", "normal")
end)
vim.keymap.set("n", "g+", function()
  manipulate("increment", "gnormal")
end)
vim.keymap.set("n", "g-", function()
  manipulate("decrement", "gnormal")
end)
vim.keymap.set("v", "+", function()
  manipulate("increment", "visual")
end)
vim.keymap.set("v", "-", function()
  manipulate("decrement", "visual")
end)
vim.keymap.set("v", "g+", function()
  manipulate("increment", "gvisual")
end)
vim.keymap.set("v", "g-", function()
  manipulate("decrement", "gvisual")
end)
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
