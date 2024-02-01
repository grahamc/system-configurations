-- vim:foldmethod=marker

-- Exit if we are not running inside vscode
if vim.g.vscode == nil then
  return
end

-- TODO: I have this set in init.lua, but it won't work in vscode unless I set it here.
vim.g.mapleader = " "

-- comment
vim.keymap.set({ "x", "n" }, "gc", "<Plug>VSCodeCommentary", { remap = true })
vim.keymap.set({ "n" }, "gcc", "<Plug>VSCodeCommentaryLine", { remap = true })

-- Windows
vim.keymap.set({ "n" }, "<Leader><Bar>", "<C-w>v", { remap = true })
vim.keymap.set({ "n" }, "<Leader>-", "<C-w>s", { remap = true })

-- right click
vim.keymap.set({ "n", "x" }, "<Leader><Leader>", function()
  vim.fn.VSCodeNotify("editor.action.showContextMenu")
end)

-- version control {{{
vim.keymap.set({ "n" }, "zv", function()
  vim.fn.VSCodeNotify("editor.action.dirtydiff.next")
end)
vim.keymap.set({ "n" }, "]c", function()
  vim.fn.VSCodeNotify("workbench.action.editor.nextChange")
end)
vim.keymap.set({ "n" }, "[c", function()
  vim.fn.VSCodeNotify("workbench.action.editor.previousChange")
end)
-- }}}

-- search {{{
vim.keymap.set({ "n" }, "<Leader>f", vim.cmd.Find, { silent = true })

vim.keymap.set({ "n", "v" }, "<Leader>g", function()
  vim.fn.VSCodeNotify("workbench.action.findInFiles")
  vim.fn.VSCodeNotify("workbench.action.toggleZenMode")
  vim.fn.VSCodeNotify("workbench.view.search.focus")
end, { silent = true })

vim.keymap.set({ "n", "v" }, "<Leader>s", function()
  vim.fn.VSCodeNotify("workbench.action.showAllSymbols")
end, { silent = true })
-- }}}

-- Folds {{{
vim.keymap.set({ "n" }, "<Tab>", function()
  vim.fn.VSCodeNotify("editor.toggleFold")
end, { silent = true })

local function fold_toggle()
  if _G.is_folded == nil or _G.is_folded == false then
    vim.fn.VSCodeNotify("editor.foldAll")
    _G.is_folded = true
  else
    vim.fn.VSCodeNotify("editor.unfoldAll")
    _G.is_folded = false
  end
end

vim.keymap.set({ "n" }, "<S-Tab>", fold_toggle, { silent = true })

vim.keymap.set({ "n", "x" }, "[<Tab>", function()
  vim.fn.VSCodeNotify("editor.gotoPreviousFold")
end)

vim.keymap.set({ "n", "x" }, "]<Tab>", function()
  vim.fn.VSCodeNotify("editor.gotoNextFold")
end)
-- }}}

-- move cursor {{{
local function moveCursor(line_count)
  local is_count_provided = false
  if vim.v.count > 0 then
    is_count_provided = true
    line_count = line_count * vim.v.count
  end

  -- Move by screen line if the count is 1 or -1 and no count is provided
  if line_count == 1 and not is_count_provided then
    vim.fn.VSCodeCall("cursorDown")
  elseif line_count == -1 and not is_count_provided then
    vim.fn.VSCodeCall("cursorUp")
  else
    local current_line = vim.api.nvim_win_get_cursor(0)[1]

    local target_line = current_line + line_count
    target_line = math.max(0, target_line)
    target_line = math.min(vim.fn.line("$"), target_line)

    vim.cmd(tostring(target_line))
  end

  -- center the current line
  vim.fn.feedkeys("zz")
end
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- TODO: These mappings should override the ones in base.lua since I `require()` this file after base.lua, but
    -- they arent so instead I define them at `VimEnter`.
    vim.keymap.set({ "n" }, "j", function()
      moveCursor(1)
    end)
    vim.keymap.set({ "n" }, "k", function()
      moveCursor(-1)
    end)
    vim.keymap.set({ "n" }, "<C-j>", function()
      moveCursor(10)
    end)
    vim.keymap.set({ "n" }, "<C-k>", function()
      moveCursor(-10)
    end)
  end,
  group = vim.api.nvim_create_augroup("CursorMovement", {}),
})
-- }}}

-- language server {{{
vim.keymap.set({ "n" }, "[l", function()
  vim.fn.VSCodeNotify("editor.action.marker.prev")
end)
vim.keymap.set({ "n" }, "]l", function()
  vim.fn.VSCodeNotify("editor.action.marker.next")
end)
-- Since vscode only has one hover action to show docs and lints I'll have my lint keybind also
-- trigger hover
vim.keymap.set({ "n" }, "<S-l>", "<S-k>", { remap = true })
vim.keymap.set({ "n" }, "ga", function()
  vim.fn.VSCodeNotify("editor.action.quickFix")
end)
vim.keymap.set({ "n" }, "gi", function()
  vim.fn.VSCodeNotify("editor.action.goToImplementation")
end)
vim.keymap.set({ "n" }, "gr", function()
  vim.fn.VSCodeNotify("editor.action.goToReferences")
end)
vim.keymap.set({ "n" }, "gn", function()
  vim.fn.VSCodeNotify("editor.action.rename")
end)
vim.keymap.set({ "n" }, "gt", function()
  vim.fn.VSCodeNotify("editor.action.goToTypeDefinition")
end)
vim.keymap.set({ "n" }, "gd", function()
  vim.fn.VSCodeNotify("editor.action.revealDefinition")
end)
vim.keymap.set({ "n" }, "gD", function()
  vim.fn.VSCodeNotify("editor.action.revealDeclaration")
end)
vim.keymap.set({ "n" }, "gh", function()
  vim.fn.VSCodeNotify("references-view.showCallHierarchy")
end)
vim.keymap.set({ "n" }, "ght", function()
  vim.fn.VSCodeNotify("references-view.showTypeHierarchy")
end)
-- }}}
