-- vim:foldmethod=marker

-- The '_' in the beginning of the file name is to avoid a collision with vscode-neovim which already has a module named 'vscode'

if not vim.g.vscode then
  return
end

local vscode = require("vscode")

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
  boolean_toggle("problems.visibility")
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
  vscode.call("workbench.action.quickTextSearch")
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

-- move cursor {{{
-- TODO: This can be removed when this issue is resolved:
-- https://github.com/vscode-neovim/vscode-neovim/issues/58
--
-- source: https://github.com/vscode-neovim/vscode-neovim/issues/58#issuecomment-2081304618
-- A few changes were made to the original and there are comments that describe them.
--
-- vim script 中的 cursorMove 不支持 select 参数
-- 所以这里通过lua脚本，同样调用 cursorMove，但是可以传递 select 参数
-- !但仍然存在问题：
-- 1. cursorMove 会破坏 visual line 模式，所以 visual line 模式只会保留一次，然后就会变成 visual 模式
-- 2. 文档中存在有中文时，移动过程中，col 会出现偏移，导致选区不准确
-- local vim_api = vim.api
-- 行内移动
local function moveInLine(d)
  require("vscode").action("cursorMove", {
    args = {
      {
        to = d == "end" and "wrappedLineEnd" or "wrappedLineStart",
        by = "wrappedLine",
        -- by = 'line',
        -- value = vim.v.count1,
        -- value = vim.v.count,
        value = 0,
        select = true,
      },
    },
  })
  return "<Ignore>"
end

-- 行间移动
local function moveLine(d)
  -- local current_mode = vim.api.nvim_get_mode().mode
  require("vscode").action("cursorMove", {
    args = {
      {
        to = d == "j" and "down" or "up",
        by = "wrappedLine",
        -- by = 'line',
        value = vim.v.count1,
        -- value = vim.v.count,
        select = true,
      },
    },
    -- not work
    -- callback = function()
    --     -- cb()
    --     if current_mode == 'V' then
    --         vim.schedule(function()
    --             vim_api.nvim_input('V')
    --         end)
    --         -- vim_api.nvim_input('V')
    --         -- vim_api.nvim_feedkeys('V', 'x', false)
    --         -- vim_api.nvim_feedkeys('V', 'v', true)
    --         -- debug.debug()
    --         -- return 'V'
    --     end
    --     -- return '<Ignore>'
    -- end
  })
  return "<Ignore>"
end

local function move(d)
  return function()
    local current_mode = vim.api.nvim_get_mode().mode
    -- Only works in charwise visual and visual line mode
    -- if current_mode ~= 'v' and current_mode ~= 'V' then
    --     return 'g' .. d
    -- end

    -- 因为 moveCursor 会破坏 visual line 模式，所以 visual line 模式只会保留一次，然后就会变成 visual 模式
    -- 因此这段逻辑在一次选区的动作中只会执行一次
    if current_mode == "V" then
      moveLine(d)
      if d == "j" then
        moveInLine("end")
      else
        moveInLine("start")
      end
    else
      -- 获取当前选区的标记的位置（<）
      local start_pos = vim.api.nvim_buf_get_mark(0, "<")
      local end_pos = vim.api.nvim_buf_get_mark(0, ">")
      -- 提取列号 和 行号
      local start_line = start_pos[1]
      local start_col = start_pos[2]
      local end_line = end_pos[1]
      local end_col = end_pos[2]

      local cursor_col = vim.fn.col(".")
      local line_end_col = vim.fn.col("$")
      -- 获取选区的结束行文本内容
      local selected_end_line_text = vim.fn.getline(end_line)
      -- 获取当前光标位置的行号和列号
      -- 参数 0 表示当前窗口
      local cursor = vim.api.nvim_win_get_cursor(0)
      -- 提取行号
      local current_line = cursor[1]

      -- 如果选区只有一行，而且整行内容都已被选中
      -- 那么在执行完行间移动后，就将新行的光标移动到行首或行尾
      -- 实现模拟 visual line 的效果
      -- 最后直接返回，不再执行下面的逻辑
      if
        start_col == 0
        and end_col + 1 == #selected_end_line_text
        and start_line == end_line
      then
        moveLine(d)
        if d == "j" then
          moveInLine("end")
        else
          moveInLine("start")
        end
        return "<Ignore>"
      end

      -- 其他情况
      moveLine(d)

      -- k方向，向上移动
      -- 如果选区的结束行行内容被全选中，那么在执行完行间移动后，就将新行的光标移动到行尾
      -- 实现模拟 visual line 的效果
      if end_col + 1 == #selected_end_line_text and current_line < end_line then
        moveInLine("start")
        -- return 'V'
      end
      -- j方向，向下移动
      -- 如果选区的开始行行内容被全选中，那么在执行完行间移动后，就将新行的光标移动到行首
      -- 实现模拟 visual line 的效果
      if start_col == 0 and current_line > start_line then
        moveInLine("end")
        -- return 'V'
      end
    end
    return "<Ignore>"
  end
end

vim.keymap.set("v", "gj", move("j"), {
  expr = true,
  noremap = true,
  silent = true,
})
vim.keymap.set("v", "gk", move("k"), {
  expr = true,
  noremap = true,
  silent = true,
})

local function moveCursor(d)
  return function()
    -- 当 v.count 为 0 时，表示没有使用数字修饰符，此时可以执行自定义的移动
    -- 否则，执行原生的移动，如 10j
    if
      vim.v.count == 0
      and vim.fn.reg_recording() == ""
      and vim.fn.reg_executing() == ""
    then
      return "g" .. d
    else
      return d
    end
  end
end

local function bigMoveCursor(d)
  return function()
    return string.rep(moveCursor(d)(), 6)
  end
end

-- 依赖于 gj 和 gk 的定义，所以要放在 gj 和 gk 的后面
--
-- Unlike the original, I only map these in normal mode because it was messing
-- with visual mode. For example, <C-v><S-i> wasn't working and my visual
-- selections would always be a few characters off.
vim.keymap.set("n", "k", moveCursor("k"), {
  expr = true,
  remap = true,
  silent = true,
})
vim.keymap.set("n", "j", moveCursor("j"), {
  expr = true,
  remap = true,
  silent = true,
})
vim.keymap.set("n", "<C-k>", bigMoveCursor("k"), {
  expr = true,
  remap = true,
  silent = true,
})
vim.keymap.set("n", "<C-j>", bigMoveCursor("j"), {
  expr = true,
  remap = true,
  silent = true,
})
-- }}}
