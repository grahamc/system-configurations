local base_utilities = require("base.utilities")
local terminal_utilities = require("terminal.utilities")

local ns = vim.api.nvim_create_namespace("bigolu/qf-live-preview")
local last_highlighted_buffer = nil
local function clear_last_highlighted_buffer()
  if last_highlighted_buffer ~= nil then
    vim.api.nvim_buf_clear_namespace(last_highlighted_buffer, ns, 1, -1)
    last_highlighted_buffer = nil
  end
end

terminal_utilities.set_up_live_preview({
  id = "QuickFix",
  file_type = "qf",
  on_select = function()
    vim.cmd([[
      normal! <CR>
    ]])
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("<CR>", true, false, true),
      "n",
      false
    )
  end,
  on_exit = clear_last_highlighted_buffer,
  get_bufnr = function()
    local item = vim.fn.getqflist()[vim.fn.line(".")]
    if item == nil or (item.user_data and item.user_data.count) then
      return
    end
    return item.bufnr
  end,
  on_preview = function(last_winid)
    local item = vim.fn.getqflist()[vim.fn.line(".")]
    if item == nil or (item.user_data and item.user_data.count) then
      return
    end

    vim.api.nvim_set_option_value(
      "winhighlight",
      "MiniCursorword:Clear",
      { win = last_winid }
    )
    local end_line = item.end_lnum == 0 and item.lnum or item.end_lnum
    clear_last_highlighted_buffer()
    for cur = item.lnum, end_line do
      vim.api.nvim_buf_add_highlight(
        item.bufnr,
        ns,
        "QuickfixPreview",
        cur - 1,
        item.col - 1,
        item.end_col == 0 and -1 or item.end_col
      )
    end
    last_highlighted_buffer = item.bufnr
    ---@diagnostic disable-next-line: param-type-mismatch
    vim.api.nvim_win_set_cursor(last_winid, { item.lnum, item.col })
  end,
})

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

local namespace = vim.api.nvim_create_namespace("bigolu/qf-entries")
local function get_width()
  -- statuscolumn, but without signcolumn
  return vim.o.columns - 3
end
local function trim_path(path, any_has_text)
  local fn = vim.fn
  local max_filename_length =
    math.floor(get_width() * (any_has_text and 0.4 or 0.8))
  local len = fn.strchars(path)
  if len > max_filename_length then
    path = "…"
      .. fn.strpart(
        path,
        len - max_filename_length,
        max_filename_length,
        vim.v["true"]
      )
  end
  return path
end
local function list_items(info)
  if info.quickfix == 1 then
    return vim.fn.getqflist({ id = info.id, items = 1, qfbufnr = 1 })
  else
    return vim.fn.getloclist(
      info.winid,
      { id = info.id, items = 1, qfbufnr = 1 }
    )
  end
end
local function apply_highlights(bufnr, highlights)
  for _, hl in ipairs(highlights) do
    vim.highlight.range(
      bufnr,
      namespace,
      hl.group,
      { hl.line, hl.col },
      { hl.line, hl.end_col }
    )
  end
end
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
  local any_has_heading = vim.iter(raw_items):any(function(item)
    return (item.user_data and item.user_data.count) ~= nil
  end)

  -- If we're adding a new list rather than appending to an existing one, we
  -- need to clear existing highlights.
  if info.start_idx == 1 then
    vim.api.nvim_buf_clear_namespace(qf_bufnr, namespace, 0, -1)
  end

  for i = info.start_idx, info.end_idx do
    local raw = raw_items[i]

    if raw then
      local item = (raw.user_data and raw.user_data.count)
          and {
            type = raw.type,
            text = "",
            location = "",
            path_size = 0,
            line_col_size = 0,
            index = i,
            line = "",
            col = "",
            user_data = raw.user_data,
          }
        or {
          type = raw.type,
          text = raw.text,
          location = "",
          path_size = 0,
          line_col_size = 0,
          index = i,
          line = "",
          col = "",
          user_data = raw.user_data,
        }

      if raw.bufnr > 0 then
        item.location = trim_path(
          vim.fn.fnamemodify(vim.fn.bufname(raw.bufnr), ":~:."),
          any_has_text
        )
        item.path_size = #item.location
      end
      if true then
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
      end

      table.insert(items, item)
    end
  end

  for _, item in ipairs(items) do
    item.text = vim.fn.substitute(item.text, "\n\\s*", "␤", "g")
    item.text = vim.fn.trim(item.text)
    if item.user_data and item.user_data.count then
      item.line = ""
      item.col = ""
    end

    local function build_line()
      if item.user_data and item.user_data.count then
        return item.location .. " " .. item.user_data.count
      else
        local indentation = any_has_heading and "    " or ""

        local sign = ""
        if item.user_data and item.user_data.severity then
          sign = ({
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.HINT] = "",
            [vim.diagnostic.severity.INFO] = "",
          })[item.user_data.severity] .. " "
        end

        local source = ""
        if item.user_data and item.user_data.source then
          source = " " .. item.user_data.source
        end

        local position = string.format(" [%s, %s]", item.line, item.col)

        -- 5 is for the gutter
        local max_text = vim.api.nvim_win_get_width(0)
          - 5
          - #indentation
          - #sign
          - #source
          - #position
        local text = " " .. item.text
        if #text > max_text then
          text = text:sub(1, max_text - 2) .. " …"
        end

        return indentation .. sign .. text .. source .. position
      end
    end
    local line = build_line()

    -- If a line is completely empty, Vim uses the default format, which
    -- involves inserting `|| `. To prevent this from happening we'll just
    -- insert an empty space instead.
    if line == "" then
      line = " "
    end

    local entry_line_count = math.ceil(vim.fn.strwidth(line) / get_width())
    local col = entry_line_count == 1 and 0
      or vim.str_utf_pos(line)[(get_width() * (entry_line_count - 1))]
    -- table.insert(highlights, {
    --   group = "QuickFixEntryUnderline",
    --   line = line_idx,
    --   col = col,
    --   end_col = #line,
    -- })

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

local function move(direction)
  local current_list_nr = vim.fn.getqflist({ nr = 0 }).nr
  local list_count = vim.fn.getqflist({ nr = "$" }).nr
  local indices_to_search = direction == "next"
      and base_utilities.table_concat(
        vim.fn.range(current_list_nr + 1, list_count),
        vim.fn.range(1, current_list_nr - 1)
      )
    or base_utilities.table_concat(
      vim.fn.range(current_list_nr - 1, 1, -1),
      vim.fn.range(list_count, current_list_nr + 1, -1)
    )
  local target = vim.iter(indices_to_search):find(function(index)
    return #vim.fn.getqflist({ nr = index, items = true }).items > 0
  end)
  if target ~= nil then
    if target > current_list_nr then
      vim.cmd("cnewer " .. target - current_list_nr)
    else
      vim.cmd("colder " .. current_list_nr - target)
    end
  end
end

function QFFoldExpr()
  local item = vim.fn.getqflist()[vim.v.lnum]
  return (item.user_data and item.user_data.count) and ">1" or "="
end
function QFWinBar()
  local current_list_id = vim.fn.getqflist({ id = 0 }).id
  local list_count = vim.fn.getqflist({ nr = "$" }).nr
  local list_indices = list_count == 0 and {} or vim.fn.range(1, list_count)
  local lists_as_winbar_string = vim
    .iter(list_indices)
    -- qf weirdness: id = 0 gets id of quickfix list nr
    :map(function(index)
      return vim.fn.getqflist({ nr = index, id = 0, title = true, items = true })
    end)
    :filter(function(list)
      return #list.items > 0
    end)
    :map(function(list)
      local border_hl = "QuickfixBorderNotCurrent"
      local title_hl = "QuickfixTitleNotCurrent"
      if list.id == current_list_id then
        border_hl = "QuickfixBorderCurrent"
        title_hl = "QuickfixTitleCurrent"
      end

      return string.format(
        "%%#%s#%%#%s#" .. list.title .. "%%#%s#",
        border_hl,
        title_hl,
        border_hl
      )
    end)
    -- TODO: truncate if it overflows
    :join(" ")

  local winbar_string = (#lists_as_winbar_string > 0) and lists_as_winbar_string
    or "%#QFWinBarEmpty#No lists"

  return "%=" .. winbar_string .. "%="
end
vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function()
    if vim.bo.filetype == "qf" then
      vim.wo.winbar = "%{%v:lua.QFWinBar()%}"
      vim.wo.foldexpr = "v:lua.QFFoldExpr()"
      vim.defer_fn(function()
        vim.wo.foldmethod = "expr"
      end, 0)
      vim.wo.signcolumn = "no"
      vim.wo.linebreak = false
      vim.wo.winhighlight = "Folded:QuickfixFold"
    end
  end,
})
vim.api.nvim_create_autocmd("QuickfixCmdPost", {
  callback = function()
    local qflist = vim.fn.getqflist({ title = true, items = true })

    local any_has_multiple = false
    local items_by_filename = vim
      .iter(qflist.items)
      :fold({}, function(acc, item)
        local filename = vim.api.nvim_buf_get_name(item.bufnr)
        if acc[filename] == nil then
          acc[filename] = {}
        end
        table.insert(acc[filename], item)
        if #acc[filename] > 1 then
          any_has_multiple = true
        end
        return acc
      end)
    local filenames = vim.tbl_keys(items_by_filename)
    table.sort(filenames)
    local new_items = vim
      .iter(filenames)
      :map(function(filename)
        local items = items_by_filename[filename]

        local heading = vim.deepcopy(items[1])
        heading.user_data = {
          count = #items,
        }

        return any_has_multiple
            and base_utilities.table_concat({ heading }, items)
          or items
      end)
      :fold({}, base_utilities.table_concat)

    -- the first list will be ignored since the last dictionary is present
    vim.fn.setqflist({}, "r", {
      items = new_items,
      title = qflist.title,
    })
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
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = "qf",
  once = true,
  callback = function()
    vim.b.minicursorword_disable = true
    vim.b.minicursorword_disable_permanent = true
    vim.b.minianimate_disable = true

    vim.keymap.set(
      "n",
      "q",
      vim.cmd.cclose,
      { buffer = true, desc = "Close quickfix window" }
    )
    vim.keymap.set("n", "<F7>", function()
      move("last")
    end, { buffer = true, desc = "Last list [previous]" })
    vim.keymap.set("n", "<F8>", function()
      move("next")
    end, { buffer = true, desc = "Next list" })
    vim.keymap.set("n", "<C-q>", function()
      vim.fn.setqflist({}, "r")
      move("next")
    end, { buffer = true, desc = "Remove list [close,delete]" })
    vim.keymap.set("n", "U", function()
      local item = vim.fn.getqflist()[vim.fn.line(".")]
      local path = item
        and item.user_data
        and item.user_data.lsp
        and item.user_data.lsp.codeDescription
        and item.user_data.lsp.codeDescription.href
      if path == nil then
        return
      end
      local _, err = vim.ui.open(path)
      if err ~= nil then
        vim.notify(
          string.format("Failed to open path '%s'\n%s", path, err),
          vim.log.levels.ERROR
        )
      end
    end, { buffer = true, desc = "Remove list [close,delete]" })
    vim.keymap.set("n", "L", function()
      local item = vim.fn.getqflist()[vim.fn.line(".")]
      vim.diagnostic.open_float({
        bufnr = item.bufnr,
        pos = item.lnum - 1,
      })
    end, { buffer = true, desc = "Remove list [close,delete]" })
    -- don't move by screen line
    vim.keymap.set({ "n", "x" }, "j", "j", { buffer = true })
    vim.keymap.set({ "n", "x" }, "k", "k", { buffer = true })

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
    vim.keymap.set(
      "x",
      "d",
      "<Esc>:lua QFRemoveVisual()<CR>",
      { buffer = true }
    )
  end,
})

-- winbar highlighting
vim.api.nvim_create_autocmd({ "WinEnter", "FileType" }, {
  callback = function()
    if vim.bo.filetype == "qf" then
      terminal_utilities.set_persistent_highlights("quickfix", {
        QuickfixTitleCurrent = "BufferLineBufferSelected",
        QuickfixBorderCurrent = "BufferLineIndicatorSelected",
      })
    end
  end,
})
vim.api.nvim_create_autocmd({ "WinLeave" }, {
  callback = function()
    if vim.bo.filetype == "qf" then
      terminal_utilities.set_persistent_highlights("quickfix", {
        QuickfixTitleCurrent = "BufferLineBufferVisible",
        QuickfixBorderCurrent = "Ignore",
      })
    end
  end,
})

local function on_list(options)
  if #options.items == 1 then
    local item = options.items[1]
    local range = item.user_data.range
      or item.user_data.targetRange
      or item.user_data.targetSelectionRange
    local start_pos = range.start
    local path = item.filename

    local function open_file_in_background(file)
      vim.cmd.badd(file)
      local buf = vim.fn.bufnr(file)

      return buf
    end
    local bufnr = (vim.fn.bufexists(path) ~= 0) and vim.fn.bufnr(path)
      or open_file_in_background(path)

    terminal_utilities.set_jump_before(function()
      ---@diagnostic disable-next-line: param-type-mismatch
      vim.api.nvim_win_set_buf(0, bufnr)
      vim.api.nvim_win_set_cursor(
        0,
        { start_pos.line + 1, start_pos.character }
      )
      -- so it shows up in the tabline
      vim.bo.buflisted = true
    end)()
  else
    vim.fn.setqflist({}, " ", options)
    vim.api.nvim_command("copen")
  end
end
vim.keymap.set("n", "<M-d>", function()
  local qf_entries = vim
    .iter(vim.diagnostic.get())
    :map(function(d)
      return {
        lnum = d.lnum + 1,
        bufnr = d.bufnr,
        end_lnum = d.end_lnum,
        col = d.col + 1,
        end_col = d.end_col,
        text = d.message,
        user_data = {
          severity = d.severity,
          source = d.source,
          lsp = d.user_data and d.user_data.lsp,
        },
      }
    end)
    :totable()

  local params = {
    title = "Diagnostics",
    items = qf_entries,
  }

  local extant_diagnostic_list = vim
    .iter(vim.fn.range(1, vim.fn.getqflist({ nr = "$" }).nr))
    :find(function(nr)
      return vim.fn.getqflist({ nr = nr, title = true }).title == "Diagnostics"
    end)
  if extant_diagnostic_list then
    params.nr = extant_diagnostic_list
  end

  vim.fn.setqflist({}, extant_diagnostic_list and "r" or " ", params)
  vim.api.nvim_command("copen")
end, {
  desc = "Diagnostics [problems,errors]",
})
vim.keymap.set("n", "gd", function()
  vim.lsp.buf.definition({ on_list = on_list })
end, {
  desc = "Definitions",
})
vim.keymap.set("n", "gt", function()
  vim.lsp.buf.type_definition({ on_list = on_list })
end, {
  desc = "Type definitions",
})
vim.keymap.set("n", "gi", function()
  vim.lsp.buf.implementation({ on_list = on_list })
end, {
  desc = "Implementations",
})
-- TODO: When there is only one result, it doesn't add to the jumplist so I'm adding that
-- here. I should upstream this.
vim.keymap.set(
  "n",
  "gr",
  terminal_utilities.set_jump_before(function()
    vim.lsp.buf.references(nil, { on_list = on_list })
  end),
  { desc = "References" }
)

Plug("gabrielpoca/replacer.nvim", {
  config = function()
    local replacer = require("replacer")
    replacer.setup({
      save_on_write = false,
    })
    vim.api.nvim_create_autocmd({ "FileType" }, {
      pattern = "qf",
      callback = function()
        vim.keymap.set("n", "gr", function()
          replacer.run()
        end, { desc = "Activate replacer", buffer = true })
      end,
    })
    vim.api.nvim_create_autocmd({ "FileType" }, {
      pattern = "replacer",
      callback = function()
        vim.keymap.set("n", "gc", function()
          replacer.save({ rename_files = true })
        end, { desc = "Commit changes", buffer = true })
        vim.bo.buflisted = false
      end,
    })
  end,
})
