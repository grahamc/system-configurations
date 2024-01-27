-- vim:foldmethod=marker

vim.o.laststatus = 3
vim.o.statusline = "%!v:lua.StatusLine()"
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "gf", ":cdo s///e<left><left><left>", {})
    vim.opt_local.statusline = "%!v:lua.QuickfixStatusLine()"
  end,
  group = vim.api.nvim_create_augroup("Quickfix Statusline", {}),
})
vim.api.nvim_create_autocmd({ "BufEnter" }, {
  pattern = "*",
  callback = function()
    if vim.o.filetype == "NvimTree" then
      vim.opt_local.statusline = "%!v:lua.FileExplorerStatusLine()"
    elseif vim.o.filetype == "aerial" then
      vim.opt_local.statusline = "%!v:lua.OutlineStatusLine()"
    end
  end,
  group = vim.api.nvim_create_augroup("Widget Statusline", {}),
})

-- statusline helper {{{
local function get_mode_indicator()
  local mode_map = {
    ["n"] = "NORMAL",
    ["no"] = "O-PENDING",
    ["nov"] = "O-PENDING",
    ["noV"] = "O-PENDING",
    ["no\22"] = "O-PENDING",
    ["niI"] = "NORMAL",
    ["niR"] = "NORMAL",
    ["niV"] = "NORMAL",
    ["nt"] = "NORMAL",
    ["ntT"] = "NORMAL",
    ["v"] = "VISUAL",
    ["vs"] = "VISUAL",
    ["V"] = "V-LINE",
    ["Vs"] = "V-LINE",
    ["\22"] = "V-BLOCK",
    ["\22s"] = "V-BLOCK",
    ["s"] = "SELECT",
    ["S"] = "S-LINE",
    ["\19"] = "S-BLOCK",
    ["i"] = "INSERT",
    ["ic"] = "INSERT",
    ["ix"] = "INSERT",
    ["R"] = "REPLACE",
    ["Rc"] = "REPLACE",
    ["Rx"] = "REPLACE",
    ["Rv"] = "V-REPLACE",
    ["Rvc"] = "V-REPLACE",
    ["Rvx"] = "V-REPLACE",
    ["c"] = "COMMAND",
    ["cv"] = "EX",
    ["ce"] = "EX",
    ["r"] = "REPLACE",
    ["rm"] = "MORE",
    ["r?"] = "CONFIRM",
    ["!"] = "SHELL",
    ["t"] = "TERMINAL",
  }
  local mode = mode_map[vim.api.nvim_get_mode().mode]
  if mode == nil then
    mode = "?"
  end
  local function make_highlight_name(name)
    return "%#" .. string.format("StatusLineMode%s", name) .. "#"
  end
  local mode_highlight = make_highlight_name("Other")
  local function startswith(text, prefix)
    return text:find(prefix, 1, true) == 1
  end
  if startswith(mode, "V") then
    mode_highlight = make_highlight_name("Visual")
  elseif startswith(mode, "I") then
    mode_highlight = make_highlight_name("Insert")
  elseif startswith(mode, "N") then
    mode_highlight = make_highlight_name("Normal")
  elseif startswith(mode, "T") then
    mode_highlight = make_highlight_name("Terminal")
  end
  local mode_indicator = "%#StatusLinePowerlineOuter#"
    .. ""
    .. mode_highlight
    .. " "
    .. mode
    .. " "
    .. "%#StatusLinePowerlineInner#"
    .. " "

  return mode_indicator
end

local function filter_out_nils(list)
  local result = {}

  local keys = {}
  for key, value in pairs(list) do
    if value ~= nil then
      table.insert(keys, key)
    end
  end
  table.sort(keys)

  for _, key in ipairs(keys) do
    table.insert(result, list[key])
  end

  return result
end

local function make_statusline(left_items, right_items)
  local showcmd = "%#StatusLineShowcmd#%S"
  local statusline_separator = "%#StatusLineFill# %=" .. showcmd .. "%#StatusLineFill#%= "

  local left_side = get_mode_indicator()
    .. table.concat(filter_out_nils(left_items), "%#StatusLineSeparator# ∙ ")

  local right_side = table.concat(filter_out_nils(right_items), "  ")

  local padding = "%#StatusLine# "

  local statusline = left_side
    .. statusline_separator
    .. right_side
    .. padding
    .. "%#StatusLinePowerlineOuter#"
    .. ""

  return statusline
end
-- }}}

-- main statusline {{{
function StatusLine()
  local position = "%#StatusLine#" .. " %03l:%03c"

  local fileformat = vim.o.fileformat
  if fileformat == "unix" then
    fileformat = " LF"
  elseif fileformat == "mac" then
    fileformat = " CR"
  else
    fileformat = " CRLF"
  end
  fileformat = "%#StatusLine#" .. fileformat

  local fileencoding = nil
  if #vim.o.fileencoding > 0 then
    fileencoding = "%#StatusLine#" .. string.upper(vim.o.fileencoding)
  end

  local filetype = nil
  if string.len(vim.o.filetype) > 0 then
    local buffer_name = vim.api.nvim_buf_get_name(0)
    local basename = vim.fs.basename(buffer_name)
    local extension = vim.fn.fnamemodify(basename, ":e")
    local icon, color = require("nvim-web-devicons").get_icon_color(basename, extension)
    if icon ~= nil then
      vim.api.nvim_set_hl(
        0,
        "FileTypeIcon",
        { fg = color, bg = vim.api.nvim_get_hl(0, { name = "StatusLine" }).bg }
      )

      icon = "%#FileTypeIcon#" .. icon .. " "
    else
      icon = ""
    end
    filetype = icon .. "%#StatusLine#" .. vim.o.filetype
  end

  local readonly = nil
  if vim.o.readonly then
    local indicator = "󰍁 "
    readonly = "%#StatusLineStandoutText#" .. indicator
  end

  local reg_recording = nil
  local recording_register = vim.fn.reg_recording()
  if recording_register ~= "" then
    reg_recording = "%#StatusLineRecordingIndicator# %#StatusLine#REC@" .. recording_register
  end

  local search_info = nil
  local ok, czs = pcall(require, "czs")
  if ok then
    if czs.display_results() then
      local _, current, count = czs.output()
      search_info = "%#StatusLine# " .. string.format("%s/%s", current, count)
    end
  end

  local lsp_info = nil
  local language_server_count_for_current_buffer =
    #vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
  if language_server_count_for_current_buffer > 0 then
    lsp_info = "%#StatusLine# " .. language_server_count_for_current_buffer
  end

  local maximized = nil
  if IsMaximized then
    local indicator = " "
    maximized = "%#StatusLineStandoutText#" .. indicator
  end

  local diagnostic_count = {
    warning = GetDiagnosticCountForSeverity("warn"),
    error = GetDiagnosticCountForSeverity("error"),
    info = GetDiagnosticCountForSeverity("info"),
    hint = GetDiagnosticCountForSeverity("hint"),
  }
  local diagnostic_list = {}
  local error_count = diagnostic_count.error
  if error_count > 0 then
    local icon = " "
    local error = "%#StatusLineErrorText#" .. icon .. error_count
    table.insert(diagnostic_list, error)
  end
  local warning_count = diagnostic_count.warning
  if warning_count > 0 then
    local icon = " "
    local warning = "%#StatusLineWarningText#" .. icon .. warning_count
    table.insert(diagnostic_list, warning)
  end
  local info_count = diagnostic_count.info
  if info_count > 0 then
    local icon = " "
    local info = "%#StatusLineInfoText#" .. icon .. info_count
    table.insert(diagnostic_list, info)
  end
  local hint_count = diagnostic_count.hint
  if hint_count > 0 then
    local icon = " "
    local hint = "%#StatusLineHintText#" .. icon .. hint_count
    table.insert(diagnostic_list, hint)
  end
  if _G.mason_update_available_count and _G.mason_update_available_count > 0 then
    local mason_update_indicator = "%#StatusLineMasonUpdateIndicator# "
      .. _G.mason_update_available_count
    table.insert(diagnostic_list, mason_update_indicator)
  end
  local diagnostics = nil
  if #diagnostic_list > 0 then
    diagnostics = table.concat(diagnostic_list, " ")
  end

  local function is_pattern_in_buffer(pattern)
    return vim.fn.search(pattern, "nw", 0, 500) > 0
  end

  local mixed_indentation_indicator = nil
  -- Taken from here:
  -- https://github.com/vim-airline/vim-airline/blob/3b9e149e19ed58dee66e4842626751e329e1bd96/autoload/airline/extensions/whitespace.vim#L30
  if is_pattern_in_buffer([[\v(^\t+ +)|(^ +\t+)]]) then
    mixed_indentation_indicator = "%#StatusLineErrorText#[  mixed indent]"
  end

  local mixed_line_endings = nil
  local line_ending_types_found = 0
  if is_pattern_in_buffer([[\v\n]]) then
    line_ending_types_found = line_ending_types_found + 1
  end
  if is_pattern_in_buffer([[\v\r]]) then
    line_ending_types_found = line_ending_types_found + 1
  end
  if is_pattern_in_buffer([[\v\r\n]]) then
    line_ending_types_found = line_ending_types_found + 1
  end
  if line_ending_types_found > 1 then
    mixed_line_endings = "%#StatusLineErrorText#[ mixed line-endings]"
  end

  return make_statusline({
    diagnostics,
    mixed_indentation_indicator,
    mixed_line_endings,
    reg_recording,
  }, {
    maximized,
    search_info,
    lsp_info,
    readonly,
    filetype,
    fileformat,
    fileencoding,
    position,
  })
end

function GetDiagnosticCountForSeverity(severity)
  return #vim.diagnostic.get(0, { severity = severity })
end
-- }}}

function QuickfixStatusLine()
  return make_statusline(
    { [[%#StatusLine#%t%{exists('w:quickfix_title')? ' '.w:quickfix_title : ''}]] },
    { "%#StatusLine#Press gf for find&replace" }
  )
end

function FileExplorerStatusLine()
  return make_statusline(
    { "%#StatusLine#" .. vim.o.filetype },
    { "%#StatusLine#Press g? for help" }
  )
end

function OutlineStatusLine()
  return make_statusline({ "%#StatusLine#" .. vim.o.filetype }, { "%#StatusLine#Press ? for help" })
end

Plug("oncomouse/czs.nvim", {
  config = function()
    -- 'n' always searches forwards, 'N' always searches backwards I have this set in base.lua, but
    -- since I need to use these czs mappings I had to redefine them.
    vim.keymap.set(
      { "n", "x", "o" },
      "n",
      "['<Plug>(czs-move-N)', '<Plug>(czs-move-n)'][v:searchforward]",
      { expr = true, replace_keycodes = false }
    )
    vim.keymap.set(
      { "n", "x", "x" },
      "N",
      "['<Plug>(czs-move-n)', '<Plug>(czs-move-N)'][v:searchforward]",
      { expr = true, replace_keycodes = false }
    )
  end,
})
vim.g.czs_do_not_map = true
