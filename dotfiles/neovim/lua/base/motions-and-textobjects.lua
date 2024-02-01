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
  return string.format("`y%s`z", (LastPasteStartLine == LastPasteEndLine) and "v" or "V")
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

-- Using the paragraph motions won't add to the jump stack
vim.keymap.set({ "n" }, "}", [[<Cmd>keepjumps normal! }<CR>]], {
  desc = "End of paragraph",
})
vim.keymap.set({ "n" }, "{", [[<Cmd>keepjumps normal! {<CR>]], {
  desc = "Start of paragraph",
})
vim.keymap.set({ "n", "x" }, "]p", "}", { remap = true, desc = "End of paragraph" })
vim.keymap.set({ "n", "x" }, "[p", "{", { remap = true, desc = "Start of paragraph" })

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
  local function table_concat(t1, t2)
    for i = 1, #t2 do
      t1[#t1 + 1] = t2[i]
    end
    return t1
  end
  local last_line = vim.fn.line("$")
  local current_line = vim.fn.line(".")
  local max_line_length = require("utilities").get_max_line_length()
  local lines_to_search = nil
  if direction == "next" then
    lines_to_search =
      table_concat(vim.fn.range(current_line + 1, last_line), vim.fn.range(1, current_line - 1))
  else
    lines_to_search = table_concat(
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
      return vim.fn.col({ line, "$" }) > max_line_length
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

-- replacement for matchit since matchit wasn't working for me
Plug("andymass/vim-matchup")
-- Don't display off-screen matches in my statusline or a popup window
vim.g.matchup_matchparen_offscreen = {}

Plug("bkad/CamelCaseMotion")
vim.g.camelcasemotion_key = ","

Plug("nvim-treesitter/nvim-treesitter-textobjects")

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
