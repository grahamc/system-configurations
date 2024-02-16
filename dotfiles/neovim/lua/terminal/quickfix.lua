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

local namespace = vim.api.nvim_create_namespace("bigolu/qf")
local function get_width()
  -- statuscolumn, but without signcolumn
  return vim.o.columns - 3
end
local function trim_path(path, any_has_text)
  local fn = vim.fn
  local max_filename_length = math.floor(get_width() * (any_has_text and 0.4 or 0.8))
  local len = fn.strchars(path)
  if len > max_filename_length then
    path = "…" .. fn.strpart(path, len - max_filename_length, max_filename_length, vim.v["true"])
  end
  return path
end
local function list_items(info)
  if info.quickfix == 1 then
    return vim.fn.getqflist({ id = info.id, items = 1, qfbufnr = 1 })
  else
    return vim.fn.getloclist(info.winid, { id = info.id, items = 1, qfbufnr = 1 })
  end
end
local function apply_highlights(bufnr, highlights)
  for _, hl in ipairs(highlights) do
    vim.highlight.range(bufnr, namespace, hl.group, { hl.line, hl.col }, { hl.line, hl.end_col })
  end
end
local divider = "   "
function QFTextFunc(info)
  local highlights = {}
  local list = list_items(info)
  ---@diagnostic disable-next-line: undefined-field, need-check-nil
  local qf_bufnr = list.qfbufnr
  ---@diagnostic disable-next-line: undefined-field, need-check-nil
  local raw_items = list.items
  local lines = {}
  local longest_col_length = 0
  local longest_line_length = 0
  local longest_filename_length = 0

  local items = {}

  local any_has_text = vim.iter(raw_items):any(function(item)
    return item.text ~= ""
  end)

  -- If we're adding a new list rather than appending to an existing one, we
  -- need to clear existing highlights.
  if info.start_idx == 1 then
    vim.api.nvim_buf_clear_namespace(qf_bufnr, namespace, 0, -1)
  end

  for i = info.start_idx, info.end_idx do
    local raw = raw_items[i]

    if raw then
      local item = {
        type = raw.type,
        text = raw.text,
        location = "",
        path_size = 0,
        line_col_size = 0,
        index = i,
        line = "",
        col = "",
      }

      if raw.bufnr > 0 then
        item.location =
          trim_path(vim.fn.fnamemodify(vim.fn.bufname(raw.bufnr), ":~:."), any_has_text)
        item.path_size = #item.location
      end

      if raw.lnum and raw.lnum > 0 then
        item.line = tostring(raw.lnum)
      end

      if raw.col and raw.col > 0 then
        item.col = tostring(raw.col)
      end

      local current_filename_length = vim.fn.strwidth(item.location) or 0
      if current_filename_length > longest_filename_length then
        longest_filename_length = current_filename_length
      end

      local current_line_length = vim.fn.strwidth(item.line) or 0
      if current_line_length > longest_line_length then
        longest_line_length = current_line_length
      end

      local current_col_length = vim.fn.strwidth(item.col) or 0
      if current_col_length > longest_col_length then
        longest_col_length = current_col_length
      end

      table.insert(items, item)
    end
  end

  for _, item in ipairs(items) do
    local line_idx = item.index - 1
    item.text = vim.fn.substitute(item.text, "\n\\s*", "␤", "g")
    item.text = vim.fn.trim(item.text)
    item.location = string.format("%-" .. longest_filename_length .. "s", item.location)
    item.line = string.format("%0" .. longest_line_length .. "d", item.line)
    item.col = string.format("%0" .. longest_col_length .. "d", item.col)

    local function build_line()
      local columns = {}
      if longest_filename_length > 0 then
        table.insert(columns, item.location)
      end
      if longest_line_length > 0 or longest_col_length > 0 then
        table.insert(columns, item.line .. ":" .. item.col)
      end
      if any_has_text then
        table.insert(columns, item.text)
      end
      local line = vim.iter(columns):join(divider)
      return line
    end

    local function splitByChunk(text, chunkSize)
      local s = {}
      if #text == 0 then
        s = { text }
      else
        for i = 1, #text, chunkSize do
          s[#s + 1] = text:sub(i, i + chunkSize - 1)
        end
      end
      -- pad last line so it fills the max width
      s[#s] = s[#s] .. string.rep(" ", chunkSize - vim.fn.strwidth(s[#s]))
      return s
    end
    local line = build_line()
    local length_without_text = (#line - #item.text)
    local max_text_length = (get_width() - length_without_text) - 1
    local position_length = longest_col_length + longest_line_length + 1
    local chunks = splitByChunk(item.text, max_text_length)
    item.text = vim.iter(chunks):join(
      string.rep(" ", length_without_text - position_length - 5)
        .. divider
        .. string.rep(" ", position_length)
        .. divider
    )
    line = build_line()

    -- If a line is completely empty, Vim uses the default format, which
    -- involves inserting `|| `. To prevent this from happening we'll just
    -- insert an empty space instead.
    if line == "" then
      line = " "
    end

    local entry_line_count = math.ceil(vim.fn.strwidth(line) / get_width())
    local col = entry_line_count == 1 and 0
      or vim.str_utf_pos(line)[(get_width() * (entry_line_count - 1))]
    table.insert(highlights, {
      group = "QuickFixEntryUnderline",
      line = line_idx,
      col = col,
      end_col = #line,
    })

    table.insert(lines, line)
  end

  -- Applying highlights has to be deferred, otherwise they won't apply to the
  -- lines inserted into the quickfix window.
  vim.schedule(function()
    apply_highlights(qf_bufnr, highlights)
  end)

  return lines
end
vim.o.quickfixtextfunc = "v:lua.QFTextFunc"

vim.api.nvim_create_autocmd("WinLeave", {
  callback = function()
    if vim.bo.filetype ~= "qf" then
      QfLastPos = vim.api.nvim_win_get_cursor(0)
      QfLastBuf = vim.api.nvim_get_current_buf()
      QfLastWin = vim.api.nvim_get_current_win()
    else
      IsLeavingQf = true
    end
  end,
})
local function get_fname(num)
  return vim.trim(vim.split(vim.fn.getline(num), divider)[1])
end
function QFFoldExpr()
  local line_count = vim.fn.line("$")

  local next_lnum = vim.v.lnum + 1
  local next_file = nil
  if next_lnum <= line_count then
    next_file = get_fname(next_lnum)
  end

  local last_lnum = vim.v.lnum - 1
  local last_file = nil
  if last_lnum >= 1 then
    last_file = get_fname(last_lnum)
  end

  local current_file = get_fname(vim.v.lnum)

  if current_file ~= last_file and current_file ~= next_file then
    return 0
  elseif current_file ~= last_file and current_file == next_file then
    return ">1"
  elseif current_file == last_file and current_file ~= next_file then
    return "<1"
  else
    return 1
  end
end
function QFFoldText()
  return string.format("%s (%d)", get_fname(vim.v.foldstart), (vim.v.foldend - vim.v.foldstart) + 1)
end
vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function()
    if vim.bo.filetype == "qf" then
      vim.wo.winbar =
        "%=%#QuickfixBorder#█%#QuickfixTitle#󰖷  Quickfix%#QuickfixBorder#█%="
      vim.wo.foldexpr = "v:lua.QFFoldExpr()"
      vim.wo.foldtext = "v:lua.QFFoldText()"
      vim.defer_fn(function()
        vim.wo.foldmethod = "expr"
      end, 0)
      vim.wo.signcolumn = "no"
      vim.wo.linebreak = false
      vim.wo.winhighlight = "CursorLine:NeotestCurrentLine,Folded:QuickfixFold"
    end
  end,
})
vim.api.nvim_create_autocmd("QuickfixCmdPost", {
  callback = function()
    local qflist = vim.fn.getqflist()
    table.sort(qflist, function(a, b)
      return vim.api.nvim_buf_get_name(a.bufnr) < vim.api.nvim_buf_get_name(b.bufnr)
    end)
    vim.fn.setqflist(qflist, "r")
  end,
})
vim.api.nvim_create_autocmd("VimResized", {
  callback = function()
    for _, win in pairs(vim.fn.getwininfo() or {}) do
      if win["quickfix"] == 1 then
        local old_position = vim.api.nvim_win_get_cursor(win.winid)
        vim.fn.setqflist(vim.fn.getqflist(), "r")
        vim.api.nvim_win_set_cursor(win.winid, old_position)
        break
      end
    end
  end,
})
vim.api.nvim_create_autocmd("WinEnter", {
  callback = function()
    if not QfIsExplicitJump and vim.bo.filetype ~= "qf" and IsLeavingQf then
      IsLeavingQf = false
      vim.api.nvim_set_current_win(QfLastWin)
      vim.api.nvim_win_set_buf(QfLastWin, QfLastBuf)
      vim.api.nvim_win_set_cursor(QfLastWin, QfLastPos)
    elseif QfIsExplicitJump then
      QfIsExplicitJump = false
      IsLeavingQf = false
      vim.bo.buflisted = true
    end
  end,
})
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = "qf",
  once = true,
  callback = function()
    -- don't move by screen line
    vim.keymap.set({ "n", "x" }, "j", "j", { buffer = true })
    vim.keymap.set({ "n", "x" }, "k", "k", { buffer = true })

    vim.b.minicursorword_disable = true
    vim.b.minicursorword_disable_permanent = true
    vim.b.minianimate_disable = true

    vim.keymap.set("n", "q", vim.cmd.cclose, { buffer = true, desc = "Close quickfix window" })

    function QFRemove(start_line, end_line)
      start_line = start_line or vim.fn.line(".")
      end_line = end_line or start_line
      local filtered_list = vim
        .iter(ipairs(vim.fn.getqflist()))
        :filter(function(index, _)
          return index < start_line or index > end_line
        end)
        :map(function(_, entry)
          return entry
        end)
        :totable()
      vim.fn.setqflist(filtered_list, "r")
    end

    vim.keymap.set("n", "dd", function()
      return ":lua QFRemove()<CR>:" .. vim.fn.line(".") .. "<CR>"
    end, { expr = true, buffer = true })

    function QFRemoveVisual()
      QFRemove(vim.fn.line("'<"), vim.fn.line("'>"))
      vim.cmd(tostring(vim.fn.line("'<")))
    end
    vim.keymap.set("x", "d", "<Esc>:lua QFRemoveVisual()<CR>", { buffer = true })

    local ns = vim.api.nvim_create_namespace("bigolu/qf")
    local last_highlighted_buffer = nil
    local function clear_last_highlighted_buffer()
      if last_highlighted_buffer ~= nil then
        vim.api.nvim_buf_clear_namespace(last_highlighted_buffer, ns, 1, -1)
        last_highlighted_buffer = nil
      end
    end
    vim.keymap.set("n", "<CR>", function()
      QfIsExplicitJump = true
      return "<CR>"
    end, { buffer = true, expr = true })
    vim.api.nvim_create_autocmd("CursorHold", {
      buffer = vim.api.nvim_get_current_buf(),
      nested = true,
      callback = function()
        local item_under_cursor = vim.fn.getqflist()[vim.fn.line(".")]
        if item_under_cursor == nil then
          return
        end
        local last_winid = vim.fn.win_getid(vim.fn.winnr("#"))
        ---@diagnostic disable-next-line: param-type-mismatch
        vim.api.nvim_win_set_buf(last_winid, item_under_cursor.bufnr)
        vim.api.nvim_set_option_value("winhighlight", "MiniCursorword:Clear", { win = last_winid })
        local end_line = item_under_cursor.end_lnum == 0 and item_under_cursor.lnum
          or item_under_cursor.end_lnum
        clear_last_highlighted_buffer()
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
        last_highlighted_buffer = item_under_cursor.bufnr
        ---@diagnostic disable-next-line: param-type-mismatch
        vim.api.nvim_win_set_cursor(last_winid, { item_under_cursor.lnum, item_under_cursor.col })
      end,
    })
    vim.api.nvim_create_autocmd("BufLeave", {
      buffer = vim.api.nvim_get_current_buf(),
      callback = function()
        clear_last_highlighted_buffer()
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
