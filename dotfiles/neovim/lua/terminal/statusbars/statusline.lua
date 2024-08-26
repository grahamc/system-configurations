-- vim:foldmethod=marker

vim.o.laststatus = 3
vim.o.statusline = "%!v:lua.StatusLine()"

-- statusline helpers {{{
local function get_mode_indicator()
  local normal = "NORMAL"
  local operator_pending = "OPERATOR-PENDING"
  local visual = "VISUAL"
  local visual_line = visual .. "-LINE"
  local visual_block = visual .. "-BLOCK"
  local visual_replace = visual .. "-REPLACE"
  local select = "SELECT"
  local select_line = select .. "-LINE"
  local select_block = select .. "-BLOCK"
  local insert = "INSERT"
  local replace = "REPLACE"
  local command = "COMMAND"
  local ex = "EX"
  local more = "MORE"
  local confirm = "CONFIRM"
  local shell = "SHELL"
  local terminal = "TERMINAL"
  local mode_map = {
    ["n"] = normal,
    ["no"] = operator_pending,
    ["nov"] = operator_pending,
    ["noV"] = operator_pending,
    ["no\22"] = operator_pending,
    ["niI"] = normal,
    ["niR"] = normal,
    ["niV"] = normal,
    ["nt"] = normal,
    ["ntT"] = normal,
    ["v"] = visual,
    ["vs"] = visual,
    ["V"] = visual_line,
    ["Vs"] = visual_line,
    ["\22"] = visual_block,
    ["\22s"] = visual_block,
    ["s"] = select,
    ["S"] = select_line,
    ["\19"] = select_block,
    ["i"] = insert,
    ["ic"] = insert,
    ["ix"] = insert,
    ["R"] = replace,
    ["Rc"] = replace,
    ["Rx"] = replace,
    ["Rv"] = visual_replace,
    ["Rvc"] = visual_replace,
    ["Rvx"] = visual_replace,
    ["c"] = command,
    ["cv"] = ex,
    ["ce"] = ex,
    ["r"] = replace,
    ["rm"] = more,
    ["r?"] = confirm,
    ["!"] = shell,
    ["t"] = terminal,
  }
  local mode = mode_map[vim.api.nvim_get_mode().mode]
  if mode == nil then
    mode = "?"
  end
  local mode_indicator = "%#StatusLinePowerlineOuter#"
    .. ""
    .. "%#status_line_mode#"
    .. " "
    .. mode

  return mode_indicator, 5 + #mode
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

local function make_statusline(left_items, right_items, left_sep, right_sep)
  local showcmd = "%#StatusLineShowcmd#%S"

  left_sep = left_sep or " ∙ "
  right_sep = right_sep or "  "

  local has_one_side = false
  if left_items == nil then
    left_items = {}
    has_one_side = true
  elseif right_items == nil then
    right_items = {}
    has_one_side = true
  end
  local statusline_separator = has_one_side and ""
    or "%#StatusLineFill# %=" .. showcmd .. "%#StatusLineFill#%= "

  left_items = filter_out_nils(left_items)
  right_items = filter_out_nils(right_items)
  local mode_indicator, mode_length = get_mode_indicator()

  local space_remaining = vim.o.columns - (mode_length + 2)
  local function has_space(index, item, sep_length)
    local length = #item:gsub("%%#.-#", ""):gsub("%%=", "")
    space_remaining = space_remaining - length
    if index > 1 then
      space_remaining = space_remaining - sep_length
    end
    return (space_remaining >= 0) or length == 0
  end
  local function make_table(acc, _, item)
    table.insert(acc, item)
    return acc
  end
  left_items = vim
    .iter(ipairs(left_items))
    :filter(function(index, item)
      return has_space(index, item, #left_sep)
    end)
    :fold({}, make_table)
  right_items = vim
    .iter(ipairs(right_items))
    :filter(function(index, item)
      return has_space(index, item, #right_sep)
    end)
    :fold({}, make_table)

  local left_side = mode_indicator
    .. (#left_items > 0 and " %#StatusLinePowerlineInner#%#StatusLinePowerlineOuter#" or "")
    .. table.concat(left_items, "%#StatusLineSeparator#" .. left_sep)
    .. (#left_items > 0 and "%#StatusLinePowerlineInner#" or " ")

  local right_side = table.concat(right_items, right_sep)

  local padding = "%#StatusLine# "

  local statusline = left_side
    .. statusline_separator
    .. right_side
    .. padding
    .. "%#StatusLinePowerlineOuter#"
    .. ""

  return statusline
end

local function make_mapping_statusline(mappings)
  local function make_mapping_string(mapping)
    local key_combination = mapping.key:gsub("<CR>", "󰌑 ")
    if mapping.mods ~= nil then
      local mods = vim
        .iter(mapping.mods)
        :map(function(mod)
          mod = ({
            C = "󰘴",
            M = "󰘵",
          })[mod]
          return mod .. " "
        end)
        :join("")
      key_combination = mods .. key_combination
    end
    return string.format(
      "%%#StatusLineMappingHintText#%s%%#StatusLine# %s",
      key_combination,
      mapping.description
    )
  end
  local maps = vim.iter(mappings):map(make_mapping_string):totable()
  table.insert(maps, 1, "%#StatusLine#%=")
  table.insert(maps, "%=")

  return make_statusline(nil, maps, nil, "  %=  ")
end
-- }}}

function StatusLine()
  local position = "%#StatusLine#" .. "%03l:%03c"

  local fileformat = nil
  if vim.o.fileformat == "mac" then
    fileformat = " CR"
  elseif vim.o.fileformat == "dos" then
    fileformat = " CRLF"
  end
  if fileformat ~= nil then
    fileformat = "%#StatusLineStandoutText#" .. fileformat
  end

  local fileencoding = nil
  if #vim.o.fileencoding > 0 and vim.o.fileencoding ~= "utf-8" then
    fileencoding = "%#StatusLineStandoutText#"
      .. string.upper(vim.o.fileencoding)
  end

  local filetype = nil
  if string.len(vim.o.filetype) > 0 then
    filetype = "%#StatusLine#" .. vim.o.filetype
  end

  local readonly = nil
  if vim.o.readonly then
    local indicator = "󰍁 "
    readonly = "%#StatusLineStandoutText#" .. indicator
  end

  local reg_recording = nil
  local recording_register = vim.fn.reg_recording()
  if recording_register ~= "" then
    reg_recording = "%#StatusLineRecordingIndicator# %#Normal#REC@"
      .. recording_register
  end

  local lsp_info = nil
  local language_server_count_for_current_buffer =
    #vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
  if language_server_count_for_current_buffer > 0 then
    lsp_info = "%#StatusLine# " .. language_server_count_for_current_buffer
  end

  local maximized = nil
  if IsMaximized then
    local indicator = " "
    maximized = "%#StatusLineStandoutText#" .. indicator
  end

  local diagnostic_count = {
    warning = vim.diagnostic.count(
      nil,
      { severity = vim.diagnostic.severity.WARN }
    )[vim.diagnostic.severity.WARN] or 0,
    error = vim.diagnostic.count(
      nil,
      { severity = vim.diagnostic.severity.ERROR }
    )[vim.diagnostic.severity.ERROR] or 0,
    info = vim.diagnostic.count(
      nil,
      { severity = vim.diagnostic.severity.INFO }
    )[vim.diagnostic.severity.INFO] or 0,
    hint = vim.diagnostic.count(
      nil,
      { severity = vim.diagnostic.severity.HINT }
    )[vim.diagnostic.severity.HINT] or 0,
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
  local diagnostics = nil
  if #diagnostic_list > 0 then
    diagnostics = table.concat(diagnostic_list, " ")
  end

  local function is_pattern_in_buffer(pattern)
    -- PERF
    if vim.fn.line("$") < 300 then
      return vim.fn.search(pattern, "nw", 0, 50) > 0
    else
      return false
    end
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

  local is_luasnip_loaded, luasnip = pcall(require, "luasnip")
  if is_luasnip_loaded and luasnip.get_active_snip() ~= nil then
    return make_mapping_statusline({
      { mods = { "C" }, key = "h", description = "Last node" },
      { mods = { "C" }, key = "l", description = "Next node or expand" },
      { mods = { "C" }, key = "c", description = "Select choice" },
    })
  elseif IsInsideDiagnosticFloat or IsInsideLspHoverOrSignatureHelp then
    return make_mapping_statusline({
      { key = "q", description = "Close float" },
    })
  elseif IsDiagnosticFloatOpen then
    return make_mapping_statusline({
      { key = "L", description = "Enter float" },
    })
  elseif IsLspHoverOpen then
    return make_mapping_statusline({
      { key = "K", description = "Enter float" },
    })
  elseif IsSignatureHelpOpen then
    return make_mapping_statusline({
      { mods = { "C" }, key = "k", description = "Enter float" },
    })
  else
    return make_statusline({
      readonly,
      diagnostics,
      mixed_indentation_indicator,
      mixed_line_endings,
      reg_recording,
    }, {
      maximized,
      lsp_info,
      filetype,
      fileformat,
      fileencoding,
      position,
    })
  end
end
