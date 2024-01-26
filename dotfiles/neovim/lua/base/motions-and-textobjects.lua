vim.opt.matchpairs:append("<:>")

-- select the text that was just pasted
vim.keymap.set({ "n" }, "gV", "`[v`]")

-- move to left and right side of last selection
vim.keymap.set({ "n" }, "[v", "'<")
vim.keymap.set({ "n" }, "]v", "'>")

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
vim.keymap.set({ "n" }, "}", [[<Cmd>keepjumps normal! }<CR>]])
vim.keymap.set({ "n" }, "{", [[<Cmd>keepjumps normal! {<CR>]])

-- Move to beginning and end of line
vim.keymap.set({ "n" }, "<C-a>", "^")
vim.keymap.set({ "n" }, "<C-e>", "$")
vim.keymap.set({ "i" }, "<C-a>", "<ESC>^i")
vim.keymap.set({ "i" }, "<C-e>", "<ESC>$a")

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

Plug("nvim-treesitter/nvim-treesitter-textobjects")

vim.keymap.set({ "n", "x" }, "]p", "}", { remap = true })
vim.keymap.set({ "n", "x" }, "[p", "{", { remap = true })

vim.keymap.set({ "x" }, "iz", ":<C-U>silent!normal![zV]z<CR>")
vim.keymap.set({ "o" }, "iz", ":normal viz<CR>")
