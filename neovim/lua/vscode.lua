-- Exit if we are not running inside vscode
if vim.g.vscode == nil then
  return
end

-- TODO: I have this set in init.lua, but it won't work in vscode unless I set it here.
vim.g.mapleader = ' '

-- search
vim.keymap.set({'n'}, '<Leader>f', vim.cmd.Find, {silent = true})
vim.keymap.set({'n'}, '<Leader>g', function() vim.fn.VSCodeNotify("workbench.action.findInFiles") end, {silent = true})
vim.keymap.set({'n'}, '<Leader>s', function() vim.fn.VSCodeNotify("workbench.action.showAllSymbols") end, {silent = true})

-- window
vim.keymap.set({'n'}, '<Leader><Bar>', '<C-w>v', {remap = true})
vim.keymap.set({'n'}, '<Leader>-', '<C-w>s', {remap = true})

-- Folds
vim.keymap.set({'n'}, '<Tab>', function() vim.fn.VSCodeNotify('editor.toggleFold') end, {silent = true})
local function fold_toggle()
  if _G.is_folded == nil then
    _G.is_folded = false
  end
  if _G.is_folded then
    vim.fn.VSCodeNotify('editor.unfoldAll')
    _G.is_folded = false
  else
    vim.fn.VSCodeNotify('editor.foldAll')
    _G.is_folded = true
  end
end
vim.keymap.set({'n'}, '<S-Tab>', fold_toggle, {silent = true})
local function MoveCursor(direction)
    if vim.fn.reg_recording() == '' and vim.fn.reg_executing() == '' then
        return 'g' .. direction
    else
        return direction
    end
end
-- TODO: These mappings allow me to move over folds without opening them. However, I won't be able to navigate through
-- folds while creating a macro.
-- source: https://github.com/vscode-neovim/vscode-neovim/issues/58#issuecomment-989481648
vim.keymap.set({'n'}, 'j', function() MoveCursor('j') end, {expr = true, remap = true})
vim.keymap.set({'n'}, 'k', function() MoveCursor('k') end, {expr = true, remap = true})

vim.keymap.set({'n'}, '[<Tab>', function() vim.fn.VSCodeNotify('editor.gotoPreviousFold') end)
vim.keymap.set({'n'}, ']<Tab>', function() vim.fn.VSCodeNotify('editor.gotoNextFold') end)
vim.keymap.set({'x'}, '[<Tab>', function() vim.fn.VSCodeNotify('editor.gotoPreviousFold') end)
vim.keymap.set({'x'}, ']<Tab>', function() vim.fn.VSCodeNotify('editor.gotoNextFold') end)

-- comment
vim.keymap.set({'x'}, 'gc', '<Plug>VSCodeCommentary', {remap = true})
vim.keymap.set({'n'}, 'gc', '<Plug>VSCodeCommentary', {remap = true})
vim.keymap.set({'o'}, 'gc', '<Plug>VSCodeCommentary', {remap = true})
vim.keymap.set({'n'}, 'gcc', '<Plug>VSCodeCommentaryLine', {remap = true})

-- language server
vim.keymap.set({'n'}, '[l', function() vim.fn.VSCodeNotify('editor.action.marker.prev') end)
vim.keymap.set({'n'}, ']l', function() vim.fn.VSCodeNotify('editor.action.marker.next') end)
-- Since vscode only has one hover action to show docs and lints I'll have my lint keybind also trigger hover
vim.keymap.set({'n'}, '<S-l>', '<S-k>', {remap = true})
vim.keymap.set({'n'}, 'ga', function() vim.fn.VSCodeNotify('editor.action.quickFix') end)
vim.keymap.set({'n'}, 'gi', function() vim.fn.VSCodeNotify('editor.action.goToImplementation') end)
vim.keymap.set({'n'}, 'gr', function() vim.fn.VSCodeNotify('editor.action.goToReferences') end)
vim.keymap.set({'n'}, 'gn', function() vim.fn.VSCodeNotify('editor.action.rename') end)
vim.keymap.set({'n'}, 'gt', function() vim.fn.VSCodeNotify('editor.action.goToTypeDefinition') end)
vim.keymap.set({'n'}, 'gd', function() vim.fn.VSCodeNotify('editor.action.revealDefinition') end)
vim.keymap.set({'n'}, 'gD', function() vim.fn.VSCodeNotify('editor.action.revealDeclaration') end)
vim.keymap.set({'n'}, 'gh', function() vim.fn.VSCodeNotify('references-view.showCallHierarchy') end)
vim.keymap.set({'n'}, 'ght', function() vim.fn.VSCodeNotify('references-view.showTypeHierarchy') end)

-- version control
vim.keymap.set({'n'}, 'zv', function() vim.fn.VSCodeNotify('editor.action.dirtydiff.next') end)
vim.keymap.set({'n'}, ']c', function() vim.fn.VSCodeNotify('workbench.action.editor.nextChange') end)
vim.keymap.set({'n'}, '[c', function() vim.fn.VSCodeNotify('workbench.action.editor.previousChange') end)


-- right click
vim.keymap.set({'n'}, '<Leader><Leader>', function() vim.fn.VSCodeNotify('editor.action.showContextMenu') end)
vim.keymap.set({'x'}, '<Leader><Leader>', function() vim.fn.VSCodeNotify('editor.action.showContextMenu') end)
