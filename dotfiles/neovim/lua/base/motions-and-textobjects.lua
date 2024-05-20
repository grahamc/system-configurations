vim.opt.matchpairs:append("<:>")

-- select the text that was just pasted
vim.keymap.set({ "n" }, "gp", function()
  vim.api.nvim_buf_set_mark(
    vim.api.nvim_get_current_buf(),
    "y",
    LastPasteStartLine,
    LastPasteStartCol,
    {}
  )
  vim.api.nvim_buf_set_mark(
    vim.api.nvim_get_current_buf(),
    "z",
    LastPasteEndLine,
    LastPasteEndCol,
    {}
  )
  return string.format(
    "`y%s`z",
    (LastPasteStartLine == LastPasteEndLine) and "v" or "V"
  )
end, {
  desc = "Last pasted text",
  expr = true,
})

-- move to left and right side of last selection
vim.keymap.set({ "n" }, "[v", "'<", {
  desc = "Start of last selection",
})
vim.keymap.set({ "n" }, "]v", "'>", {
  desc = "End of last selection",
})

-- move to left and right side of last yank
vim.keymap.set({ "n" }, "[y", "'[", {
  desc = "Start of last yank",
})
vim.keymap.set({ "n" }, "]y", "']", {
  desc = "End of last yank",
})

local function move_cursor_vertically(direction)
  -- TODO: When I use 'gk' at the top of the file it messes up the TUI so I'll
  -- avoid that.
  if IsRunningInTerminal and vim.fn.line(".") == 1 and direction == "k" then
    return vim.v.count1 .. direction
  end

  return vim.v.count1 .. "g" .. direction
end
vim.keymap.set({ "n", "x" }, "j", function()
  return move_cursor_vertically("j")
end, { expr = true })
vim.keymap.set({ "n", "x" }, "k", function()
  return move_cursor_vertically("k")
end, { expr = true })

-- move six lines at a time by holding ctrl and a directional key. Reasoning for
-- using 6 here:
-- https://nanotipsforvim.prose.sh/vertical-navigation-%E2%80%93-without-relative-line-numbers
vim.keymap.set({ "n", "x" }, "<C-j>", "6gj")
vim.keymap.set({ "n", "x" }, "<C-k>", "6gk")

-- move ten columns at a time by holding ctrl and a directional key
vim.keymap.set({ "n", "x" }, "<C-h>", "6h")
vim.keymap.set({ "n", "x" }, "<C-l>", "6l")

-- Using the paragraph motions won't add to the jump stack
vim.keymap.set({ "n" }, "}", [[<Cmd>keepjumps normal! }<CR>]], {
  desc = "End of paragraph",
})
vim.keymap.set({ "n" }, "{", [[<Cmd>keepjumps normal! {<CR>]], {
  desc = "Start of paragraph",
})
vim.keymap.set(
  { "n", "x" },
  "]p",
  "}",
  { remap = true, desc = "End of paragraph" }
)
vim.keymap.set(
  { "n", "x" },
  "[p",
  "{",
  { remap = true, desc = "Start of paragraph" }
)

-- Move to beginning and end of line
vim.keymap.set({ "n" }, "<C-a>", "^", {
  desc = "First non-blank of line [start]",
})
vim.keymap.set({ "n" }, "<C-e>", "$", {
  desc = "End of line",
})
vim.keymap.set({ "i" }, "<C-a>", "<ESC>^i", {
  desc = "First non-blank of line [start]",
})
vim.keymap.set({ "i" }, "<C-e>", "<ESC>$a", {
  desc = "End of line",
})

-- Move to next/last long line, m for max
local function jump_to_long_line(direction)
  local utilities = require("base.utilities")
  local last_line = vim.fn.line("$")
  local current_line = vim.fn.line(".")
  local max_line_length = utilities.get_max_line_length()
  local lines_to_search = nil
  if direction == "next" then
    lines_to_search = utilities.table_concat(
      vim.fn.range(current_line + 1, last_line),
      vim.fn.range(1, current_line - 1)
    )
  else
    lines_to_search = utilities.table_concat(
      vim.fn.range(current_line - 1, 1, -1),
      vim.fn.range(last_line, current_line + 1, -1)
    )
  end
  local long_line = vim
    .iter(lines_to_search)
    :filter(function(line)
      return line >= 0 and line <= last_line
    end)
    :find(function(line)
      return (vim.fn.col({ line, "$" }) - 1) > max_line_length
    end)
  if long_line ~= nil then
    vim.cmd(tostring(long_line))
  end
end
vim.keymap.set({ "n", "x" }, "]m", function()
  jump_to_long_line("next")
end, { remap = true, desc = "Next long line [max]" })
vim.keymap.set({ "n", "x" }, "[m", function()
  jump_to_long_line("prev")
end, { remap = true, desc = "Previous long line [last,max]" })

-- Motions for levels of indentation
Plug("jeetsukumaran/vim-indentwise", {
  config = function()
    vim.keymap.set(
      "",
      "[-",
      "<Plug>(IndentWisePreviousLesserIndent)",
      { remap = true, desc = "Last line with lower indent" }
    )
    vim.keymap.set(
      "",
      "[+",
      "<Plug>(IndentWisePreviousGreaterIndent)",
      { remap = true, desc = "Last line with higher indent" }
    )
    vim.keymap.set(
      "",
      "[=",
      "<Plug>(IndentWisePreviousEqualIndent)",
      { remap = true, desc = "Last block with equal indent" }
    )
    vim.keymap.set(
      "",
      "]-",
      "<Plug>(IndentWiseNextLesserIndent)",
      { remap = true, desc = "Next line with lower indent" }
    )
    vim.keymap.set(
      "",
      "]+",
      "<Plug>(IndentWiseNextGreaterIndent)",
      { remap = true, desc = "Next line with higher indent" }
    )
    vim.keymap.set(
      "",
      "]=",
      "<Plug>(IndentWiseNextEqualIndent)",
      { remap = true, desc = "Next block with equal indent" }
    )
  end,
})
vim.g.indentwise_suppress_keymaps = 1

Plug("andymass/vim-matchup")
vim.g.matchup_transmute_enabled = 1
-- Don't display off-screen matches in my statusline or a popup window
vim.g.matchup_matchparen_offscreen = {}
vim.keymap.set({ "n", "x" }, ";", "%", { remap = true })
vim.keymap.set({ "n", "x" }, "g;", "g%", { remap = true })
vim.keymap.set({ "n", "x" }, "];", ";", { remap = true })
vim.keymap.set({ "n", "x" }, "[;", "g;", { remap = true })

vim.defer_fn(function()
  vim.fn["plug#load"]("CamelCaseMotion")
end, 0)
Plug("bkad/CamelCaseMotion", {
  on = {},
})
vim.g.camelcasemotion_key = ","

vim.defer_fn(function()
  vim.fn["plug#load"]("nvim-treesitter-textobjects")
end, 0)
Plug("nvim-treesitter/nvim-treesitter-textobjects", {
  on = {},
})

local function marker_fold_object()
  -- excluded first and last lines for marker folds
  if vim.wo.foldmethod == "marker" then
    return ":<C-U>silent!normal![zjV]zk<CR>"
  else
    return ":<C-U>silent!normal![zV]z<CR>"
  end
end
vim.keymap.set({ "x" }, "iz", marker_fold_object, {
  desc = "Inner fold",
  expr = true,
})
vim.keymap.set({ "o" }, "iz", ":normal viz<CR>", {
  desc = "Inner fold",
})
vim.keymap.set({ "x" }, "az", ":<C-U>silent!normal![zV]z<CR>", {
  desc = "Outer fold",
})
vim.keymap.set({ "o" }, "az", ":normal vaz<CR>", {
  desc = "Outer fold",
})
