vim.keymap.set("n", "<M-q>", function()
  local qf_exists = false
  for _, win in pairs(vim.fn.getwininfo() or {}) do
    if win["quickfix"] == 1 then
      qf_exists = true
    end
  end
  if qf_exists == true then
    vim.cmd("cclose")
    return
  end
  if not vim.tbl_isempty(vim.fn.getqflist()) then
    vim.cmd("botright copen")
  end
end, {
  desc = "Toggle quickfix",
})

Plug("romainl/vim-qf", {
  config = function()
    vim.api.nvim_create_autocmd({ "FileType" }, {
      pattern = "qf",
      callback = function()
        vim.keymap.set("n", "dd", function()
          return ":.Reject<CR>:" .. vim.fn.line(".") .. "<CR>"
        end, { expr = true, buffer = true })
        function QfDeleteRange()
          local key = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
          vim.api.nvim_feedkeys(
            "gv:'<,'>Reject" .. key .. ":" .. vim.fn.line("'<") .. key,
            "n",
            false
          )
        end
        vim.keymap.set("x", "d", "<Esc>:lua QfDeleteRange()<CR>", { buffer = true })
      end,
    })
  end,
})

vim.api.nvim_create_autocmd("WinLeave", {
  callback = function()
    if vim.bo.filetype ~= "qf" then
      QfLastPos = vim.api.nvim_win_get_cursor(0)
      QfLastBuf = vim.api.nvim_get_current_buf()
    else
      IsLeavingQf = true
    end
  end,
})
vim.api.nvim_create_autocmd("WinEnter", {
  callback = function()
    if not QfIsExplicitJump and vim.bo.filetype ~= "qf" and IsLeavingQf then
      IsLeavingQf = false
      vim.api.nvim_win_set_buf(0, QfLastBuf)
      vim.api.nvim_win_set_cursor(0, QfLastPos)
    elseif QfIsExplicitJump then
      QfIsExplicitJump = false
    end
  end,
})
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = "qf",
  callback = function()
    vim.b.minicursorword_disable = true
    vim.b.minicursorword_disable_permanent = true
    vim.wo.winbar =
      "%=%#QuickfixBorder#█%#QuickfixTitle#󰖷  Quickfix%#QuickfixBorder#█%="

    if HasConfiguredQf then
      return
    else
      HasConfiguredQf = true
    end
    local highlighted_buffers = {}
    local ns = vim.api.nvim_create_namespace("bigolu/qf")
    vim.keymap.set("n", "<CR>", function()
      QfIsExplicitJump = true
      return "<CR>"
    end, { buffer = true, expr = true })
    vim.api.nvim_create_autocmd("CursorMoved", {
      buffer = vim.api.nvim_get_current_buf(),
      callback = function()
        local item_under_cursor = vim.fn.getqflist()[vim.fn.line(".")]
        local last_winid = vim.fn.win_getid(vim.fn.winnr("#"))
        ---@diagnostic disable-next-line: param-type-mismatch
        vim.api.nvim_win_set_buf(last_winid, item_under_cursor.bufnr)
        vim.api.nvim_set_option_value("winhighlight", "MiniCursorword:Clear", { win = last_winid })
        local end_line = item_under_cursor.end_lnum == 0 and item_under_cursor.lnum
          or item_under_cursor.end_lnum
        for cur = item_under_cursor.lnum, end_line do
          vim.api.nvim_buf_add_highlight(
            item_under_cursor.bufnr,
            ns,
            "QuickfixPreview",
            cur - 1,
            item_under_cursor.col - 1,
            item_under_cursor.end_col == 0 and -1 or item_under_cursor.end_col
          )
        end
        highlighted_buffers[item_under_cursor.bufnr] = true
        ---@diagnostic disable-next-line: param-type-mismatch
        vim.api.nvim_win_set_cursor(last_winid, { item_under_cursor.lnum, item_under_cursor.col })
      end,
    })
    vim.api.nvim_create_autocmd("BufLeave", {
      buffer = vim.api.nvim_get_current_buf(),
      callback = function()
        vim.iter(highlighted_buffers):each(function(buf, _)
          vim.api.nvim_buf_clear_namespace(buf, ns, 1, -1)
        end)
        highlighted_buffers = {}
      end,
    })
  end,
})

local utils = require("terminal.utilities")
vim.api.nvim_create_autocmd({ "WinEnter", "FileType" }, {
  callback = function()
    if vim.bo.filetype == "qf" then
      utils.set_persistent_highlights("quickfix", {
        QuickfixTitle = "BufferLineBufferSelected",
        QuickfixBorder = "BufferLineIndicatorSelected",
      })
    end
  end,
})
vim.api.nvim_create_autocmd({ "WinLeave" }, {
  callback = function()
    if vim.bo.filetype == "qf" then
      utils.set_persistent_highlights("quickfix", {
        QuickfixTitle = "BufferLineBufferVisible",
        QuickfixBorder = "Ignore",
      })
    end
  end,
})
