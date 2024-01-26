-- vim:foldmethod=marker

-- for the globals defined by mini.nvim
---@diagnostic disable: undefined-global

-- Copy up to the end of line, not including the newline character
vim.keymap.set({ "n" }, "Y", "yg_")

Plug("arthurxavierx/vim-caser")

-- Comment formatting {{{
vim.api.nvim_create_autocmd("BufNew", {
  pattern = "*",
  callback = function()
    vim.bo.textwidth = require("utilities").get_max_line_length()
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
    vim.bo.textwidth == 0 and require("utilities").get_max_line_length() or vim.bo.textwidth
  )

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

local function get_text_for_motion()
  -- TODO: This assumes entire lines are selected
  local lines = vim.api.nvim_buf_get_lines(0, vim.fn.line("'[") - 1, vim.fn.line("']"), true)
  return table.concat(lines, "\n")
end

_G.FormatCommentOperatorFunc = function()
  set_formatprg(get_text_for_motion())
  vim.cmd("normal! '[gq']")
end
vim.keymap.set("n", "gq", function()
  vim.o.operatorfunc = "v:lua.FormatCommentOperatorFunc"
  return "g@ic"
end, { expr = true, remap = true })

vim.keymap.set("x", "gq", function()
  set_formatprg(require("utilities").get_visual_selection())
  -- NOTE: This function returns after enqueuing the keys, not processing them. That is why I'm
  -- leaving the formatprg set.
  vim.fn.feedkeys("gvgq", "n")
end)
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
-- }}}
