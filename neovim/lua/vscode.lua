-- Exit if we are not running inside vscode
if vim.g.vscode == nil then
  return
end

-- TODO: I have this set in init.lua, but it won't work in vscode unless I set it here.
vim.g.mapleader = ' '

-- search
vim.keymap.set({'n'}, '<Leader>f', vim.cmd.Find, {silent = true})
vim.keymap.set(
  {'n', 'v'},
  '<Leader>g',
  function()
    vim.fn.VSCodeNotify("workbench.action.findInFiles")
    vim.fn.VSCodeNotify("workbench.action.toggleZenMode")
    vim.fn.VSCodeNotify("workbench.view.search.focus")
  end,
  {silent = true}
)
vim.keymap.set({'n', 'v'}, '<Leader>s', function() vim.fn.VSCodeNotify("workbench.action.showAllSymbols") end, {silent = true})

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

vim.keymap.set({'n', 'x'}, '[<Tab>', function() vim.fn.VSCodeNotify('editor.gotoPreviousFold') end)
vim.keymap.set({'n', 'x'}, ']<Tab>', function() vim.fn.VSCodeNotify('editor.gotoNextFold') end)

-- comment
vim.keymap.set({'x', 'n', 'o'}, 'gc', '<Plug>VSCodeCommentary', {remap = true})
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
vim.keymap.set({'n', 'x'}, '<Leader><Leader>', function() vim.fn.VSCodeNotify('editor.action.showContextMenu') end)

-- Sync the visual mode selection with vscode's selection.
local selection_sync_group_id = vim.api.nvim_create_augroup('SyncVisualSelectionWithVscode', {})
vim.api.nvim_create_autocmd(
  'ModeChanged',
  {
    pattern = '[^vV\x16]*:[vV\x16]*',
    callback = function()
      vim.api.nvim_create_autocmd(
        'CursorMoved',
        {
          callback = function() vim.fn.VSCodeNotifyVisual('noop', true) end,
          group = selection_sync_group_id,
        }
      )
    end,
    group = vim.api.nvim_create_augroup('StartSelectionSync', {}),
  }
)
vim.api.nvim_create_autocmd(
  'ModeChanged',
  {
    pattern = '[vV\x16]*:[^vV\x16]*',
    callback = function()
      -- Stop syncing the selection
      pcall(vim.api.nvim_del_augroup_by_name, selection_sync_group_id)
    end,
    group = vim.api.nvim_create_augroup('StopSelectionSync', {}),
  }
)
-- Clear vscode selection along with neovim's.
--
-- First we press <Esc> to end visual mode. Now since vscode's selection doesn't update until the cursr is moved,
-- we see which direction we can move the cursor in, without hitting a boundary, and move the cursor once in that
-- direction and once back.
local function clear_selection()
  local result = '<Esc>'
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  local total_lines = vim.o.lines
  local total_columns = vim.fn.col('$') - 1
  if col - 1 >= 0 then
    result = result .. '<Left><Right>'
  elseif col + 1 < total_columns then
    result = result .. '<Right><Left>'
  elseif line + 1 <= total_lines then
    result = result .. '<Down><Up>'
  elseif line - 1 >= 1 then
    result = result .. '<Up><Down>'
  end

  return result
end
vim.keymap.set({'x'}, '<Esc>', clear_selection, {expr = true})
