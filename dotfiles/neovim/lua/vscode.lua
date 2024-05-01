-- vim:foldmethod=marker

if not vim.g.vscode then
  return
end

local vscode = require("vscode-neovim")

vim.g.clipboard = vim.g.vscode_clipboard

-- I use `gq` to format my comments so I'm removing this so nvim won't wait to
-- see if I'll press another 'q'.
vim.keymap.del({ "n" }, "gqq")

-- TODO: Unlike other extensions, vscode-neovim is not picking up the
-- environment variables set by direnv-vscode, even after direnv restarts
-- all extensions. Based on my testing, it seems that this because I set an
-- `affinity` for it in my vscode settings. I need to open an issue with vscode
-- to see why setting an `affinity` on an extension would prevent it from
-- inheriting environment variables that other extensions are inheriting. In the
-- meantime, I'll use the extension below which applies the .envrc on VimEnter
-- and DirChanged events.
Plug("direnv/direnv.vim")
vim.g.direnv_silent_load = 1

-- There are three reasons why I'm disabling this:
--
-- 1. The readme for the vscode-neovim extension [1] recommends disabling any
-- plugins that render decorators very often, such as bracket highlighters, so
-- when I'm running in vscode I'll disable highlights for matching symbols.
--
-- 2. When this is enabled and I press `jk` in between two parentheses, while in
-- insert mode, another pair of parentheses would get added. Other kinds of text
-- would get inserted too.
--
-- 3. It's unnecessary since vscode does its own highlighting for matching
-- symbols.
--
-- [1]: https://marketplace.visualstudio.com/items?itemName=asvetliakov.vscode-neovim#performance
vim.g.matchup_matchparen_enabled = 0

-- Windows
vim.keymap.set({ "n" }, "<Leader><Bar>", "<C-w>v", { remap = true })
vim.keymap.set({ "n" }, "<Leader>-", "<C-w>s", { remap = true })

-- right click
vim.keymap.set({ "n", "x" }, "<Leader><Leader>", function()
  vscode.call("editor.action.showContextMenu")
end)

-- vscode-neovim maps this to the formatter configured in vscode, but I'm
-- removing it since I use conform.nvim
vim.keymap.del({ "n", "x" }, "=")
vim.keymap.del({ "n" }, "==")

-- Toggle visual elements {{{
local function toggle(values, setting)
  local current = vscode.get_config(setting)

  local new = nil
  if values[1] == current then
    new = values[2]
  else
    new = values[1]
  end

  vscode.update_config(setting, new, "global")
end

local function on_off_toggle(setting)
  toggle({ "on", "off" }, setting)
end

local function boolean_toggle(setting)
  toggle({ true, false }, setting)
end

vim.keymap.set("n", [[\b]], function()
  vscode.call("gitlens.toggleLineBlame")
end, { desc = "Toggle git blame" })
vim.keymap.set("n", [[\i]], function()
  on_off_toggle("editor.inlayHints.enabled")
end, { desc = "Toggle inlay hints" })
vim.keymap.set("n", [[\|]], function()
  boolean_toggle("editor.guides.indentation")
end, { desc = "Toggle indent guide" })
vim.keymap.set("n", [[\s]], function()
  boolean_toggle("editor.stickyScroll.enabled")
end, { desc = "Toggle sticky scroll [context]" })
vim.keymap.set("n", [[\ ]], function()
  vscode.call("editor.action.toggleRenderWhitespace")
end, { desc = "Toggle whitespace" })
vim.keymap.set("n", [[\n]], function()
  on_off_toggle("editor.lineNumbers")
end, { desc = "Toggle line numbers" })
vim.keymap.set("n", [[\d]], function()
  vscode.call("errorLens.toggle")
end, { desc = "Toggle inline diagnostics" })
-- }}}

-- version control {{{
vim.keymap.set({ "n" }, "]c", function()
  vscode.call("workbench.action.editor.nextChange")
end)
vim.keymap.set({ "n" }, "[c", function()
  vscode.call("workbench.action.editor.previousChange")
end)
-- }}}

-- search {{{
vim.keymap.set({ "n" }, "<Leader>f", function()
  vscode.call("workbench.action.quickOpen")
end, { silent = true })
vim.keymap.set({ "n", "v" }, "<Leader>g", function()
  vscode.call("workbench.action.experimental.quickTextSearch")
end, { silent = true })
vim.keymap.set({ "n", "v" }, "<Leader>s", function()
  vscode.call("workbench.action.showAllSymbols")
end, { silent = true })
vim.keymap.set({ "n", "x" }, "<Leader>b", function()
  vscode.call("fuzzySearch.activeTextEditorWithCurrentSelection")
end, { silent = true })
-- }}}

-- Folds {{{
vim.keymap.set({ "n" }, "<Tab>", function()
  vscode.call("editor.toggleFold")
end, { silent = true })

local function fold_toggle()
  if vim.b.is_folded == nil or vim.b.is_folded == false then
    vscode.call("editor.foldAll")
    vim.b.is_folded = true
  else
    vscode.call("editor.unfoldAll")
    vim.b.is_folded = false
  end
end

vim.keymap.set({ "n" }, "<S-Tab>", fold_toggle, { silent = true })

vim.keymap.set({ "n", "x" }, "[<Tab>", function()
  vscode.call("editor.gotoPreviousFold")
end)

vim.keymap.set({ "n", "x" }, "]<Tab>", function()
  vscode.call("editor.gotoNextFold")
end)
-- }}}

-- language server {{{
local function jump_to_problem(direction)
  -- To avoid a flash of the popup that I close, I try to run the close-popup
  -- command as soon as possible after running the jump command. To do so, I run
  -- the jump and close-popup commands asynchronously so I don't have to wait
  -- for the jump command to finish before queueing up the close-popup command.
  vscode.action("editor.action.marker." .. direction)
  -- close popup
  vscode.action("closeMarkersNavigation")
end
vim.keymap.set({ "n" }, "[l", function()
  jump_to_problem("prev")
end)
vim.keymap.set({ "n" }, "]l", function()
  jump_to_problem("next")
end)
-- Since vscode only has one hover action to show docs and lints I'll have my
-- lint keybind also trigger hover
vim.keymap.set({ "n" }, "<S-l>", "<S-k>", { remap = true })
vim.keymap.set({ "n" }, "ga", function()
  vscode.call("editor.action.quickFix")
end)
vim.keymap.set({ "n" }, "gi", function()
  vscode.call("editor.action.goToImplementation")
end)
vim.keymap.set({ "n" }, "gr", function()
  vscode.call("references-view.findReferences")
end)
vim.keymap.set({ "n" }, "gn", function()
  vscode.call("editor.action.rename")
end)
vim.keymap.set({ "n" }, "gt", function()
  vscode.call("editor.action.goToTypeDefinition")
end)
vim.keymap.set({ "n" }, "gd", function()
  vscode.call("editor.action.revealDefinition")
end)
vim.keymap.set({ "n" }, "gD", function()
  vscode.call("editor.action.revealDeclaration")
end)
vim.keymap.set({ "n" }, "gh", function()
  vscode.call("references-view.showCallHierarchy")
end)
vim.keymap.set({ "n" }, "gH", function()
  vscode.call("references-view.showTypeHierarchy")
end)
vim.keymap.set({ "n" }, "gl", function()
  vscode.call("codelens.showLensesInCurrentLine")
end)
-- }}}
