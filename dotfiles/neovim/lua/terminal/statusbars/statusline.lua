-- vim:foldmethod=marker

-- settings {{{
vim.o.laststatus = 3
vim.o.statusline = "%!v:lua.StatusLine()"
local statusline_group = vim.api.nvim_create_augroup("Statuslines", {})
vim.api.nvim_create_autocmd({ "FileType" }, {
  group = statusline_group,
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "gf", ":cdo s///e<left><left><left>", { buffer = true })
    vim.wo.statusline = "%!v:lua.StatusLine()"
  end,
})
vim.api.nvim_create_autocmd({ "BufEnter" }, {
  group = statusline_group,
  callback = function()
    if vim.o.filetype == "NvimTree" then
      vim.opt_local.statusline = "%!v:lua.FileExplorerStatusLine()"
    elseif vim.o.filetype == "aerial" then
      vim.opt_local.statusline = "%!v:lua.OutlineStatusLine()"
    end
  end,
})
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = statusline_group,
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    local filetype = vim.bo[buf].filetype
    local win = vim.fn.bufwinid(buf)
    if filetype == "dapui_scopes" then
      vim.api.nvim_set_option_value("statusline", "%!v:lua.DapuiScopesStatusLine()", { win = win })
    elseif filetype == "dapui_stacks" then
      vim.api.nvim_set_option_value("statusline", "%!v:lua.DapuiStacksStatusLine()", { win = win })
    elseif filetype == "dapui_watches" then
      vim.api.nvim_set_option_value("statusline", "%!v:lua.DapuiWatchesStatusLine()", { win = win })
    elseif filetype == "dapui_breakpoints" then
      vim.api.nvim_set_option_value(
        "statusline",
        "%!v:lua.DapuiBreakpointsStatusLine()",
        { win = win }
      )
    elseif filetype == "dap-repl" then
      vim.api.nvim_set_option_value("statusline", "%!v:lua.DapuiReplStatusLine()", { win = win })
    end
  end,
})
vim.api.nvim_create_autocmd({ "FileType" }, {
  group = statusline_group,
  pattern = "TelescopePrompt",
  callback = function()
    if IsMenufactureOpen then
      IsMenufactureOpen = false
      vim.opt_local.statusline = "%!v:lua.TelescopeStatusLine(v:true)"
    else
      vim.opt_local.statusline = "%!v:lua.TelescopeStatusLine()"
    end
  end,
})
-- }}}

-- statusline helpers {{{
local function get_mode_indicator()
  local normal = " "
  local operator_pending = "O-PENDING"
  local visual = " "
  local visual_line = visual .. " LINE"
  local visual_block = visual .. " BLOCK"
  local visual_replace = visual .. " REPLACE"
  local select = " "
  local select_line = select .. " LINE"
  local select_block = select .. " BLOCK"
  local insert = " "
  local replace = " "
  local command = " "
  local ex = "EX"
  local more = "MORE"
  local confirm = "CONFIRM"
  local shell = "SHELL"
  local terminal = " "
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
  local function make_highlight_name(name)
    return "%#" .. string.format("StatusLineMode%s", name) .. "#"
  end
  local mode_highlight = make_highlight_name("Other")
  if vim.startswith(mode, visual) then
    mode_highlight = make_highlight_name("Visual")
  elseif vim.startswith(mode, insert) then
    mode_highlight = make_highlight_name("Insert")
  elseif vim.startswith(mode, normal) then
    mode_highlight = make_highlight_name("Normal")
  elseif vim.startswith(mode, terminal) then
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

  local left_side = mode_indicator .. table.concat(left_items, "%#StatusLineSeparator#" .. left_sep)

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
      "%%#StatusLineHintText#%s%%#StatusLine# %s",
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

-- main statusline {{{
function StatusLine()
  local position = "%#StatusLine#" .. " %03l:%03c"

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
    fileencoding = "%#StatusLineStandoutText#" .. string.upper(vim.o.fileencoding)
  end

  local filetype = nil
  if string.len(vim.o.filetype) > 0 then
    local buffer_name = vim.api.nvim_buf_get_name(0)
    local basename = vim.fs.basename(buffer_name)
    local extension = vim.fn.fnamemodify(basename, ":e")
    local devicons = require("nvim-web-devicons")
    local icon, color = devicons.get_icon_color(basename, extension)
    if icon == nil then
      icon, color = devicons.get_icon_color_by_filetype(vim.bo.filetype)
    end
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
      search_info = "%#StatusLine# " .. string.format("%s/%s", current, count)
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
    warning = vim.diagnostic.count(nil, { severity = vim.diagnostic.severity.WARN })[vim.diagnostic.severity.WARN]
      or 0,
    error = vim.diagnostic.count(nil, { severity = vim.diagnostic.severity.ERROR })[vim.diagnostic.severity.ERROR]
      or 0,
    info = vim.diagnostic.count(nil, { severity = vim.diagnostic.severity.INFO })[vim.diagnostic.severity.INFO]
      or 0,
    hint = vim.diagnostic.count(nil, { severity = vim.diagnostic.severity.HINT })[vim.diagnostic.severity.HINT]
      or 0,
  }
  local diagnostic_list = {}
  local error_count = diagnostic_count.error
  if error_count > 0 then
    local icon = " "
    local error = "%#StatusLineErrorText#" .. icon .. error_count
    table.insert(diagnostic_list, error)
  end
  local warning_count = diagnostic_count.warning
  if warning_count > 0 then
    local icon = " "
    local warning = "%#StatusLineWarningText#" .. icon .. warning_count
    table.insert(diagnostic_list, warning)
  end
  local info_count = diagnostic_count.info
  if info_count > 0 then
    local icon = " "
    local info = "%#StatusLineInfoText#" .. icon .. info_count
    table.insert(diagnostic_list, info)
  end
  local hint_count = diagnostic_count.hint
  if hint_count > 0 then
    local icon = " "
    local hint = "%#StatusLineHintText#" .. icon .. hint_count
    table.insert(diagnostic_list, hint)
  end
  if _G.mason_update_available_count and _G.mason_update_available_count > 0 then
    local mason_update_indicator = "%#StatusLineMasonUpdateIndicator# "
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

  local debug_indicator = nil
  if #require("dap").status() > 0 then
    debug_indicator = "%#StatusLineDebugIndicator# "
  end

  local luasnip = require("luasnip")
  if luasnip.get_active_snip() ~= nil then
    return make_mapping_statusline({
      { mods = { "C" }, key = "h", description = "Last node" },
      { mods = { "C" }, key = "l", description = "Next node or expand" },
      { mods = { "C" }, key = "c", description = "Select choice" },
    })
  elseif IsCmpDocsOpen then
    return make_mapping_statusline({
      { mods = { "C" }, key = "j/k", description = "Scroll docs down/up" },
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
  elseif vim.bo.filetype == "qf" then
    return make_mapping_statusline({
      { key = "gf", description = "find&replace" },
    })
  else
    return make_statusline({
      diagnostics,
      mixed_indentation_indicator,
      mixed_line_endings,
      reg_recording,
    }, {
      maximized,
      search_info,
      debug_indicator,
      lsp_info,
      readonly,
      filetype,
      fileformat,
      fileencoding,
      position,
    })
  end
end

Plug("oncomouse/czs.nvim", {
  config = function()
    -- 'n' always searches forwards, 'N' always searches backwards I have this set in base.lua, but
    -- since I need to use these czs mappings I had to redefine them.
    vim.keymap.set(
      { "n" },
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
-- }}}

-- file explorer statusline {{{
function FileExplorerStatusLine()
  return make_mapping_statusline({
    { key = "g?", description = "help" },
  })
end
-- }}}

-- symbol outline statusline {{{
function OutlineStatusLine()
  return make_mapping_statusline({
    { key = "?", description = "help" },
  })
end
-- }}}

-- dapui statuslines {{{
--
-- TODO: Consider upstreaming since there's a related feature request:
-- https://github.com/rcarriga/nvim-dap-ui/issues/267
function DapuiScopesStatusLine()
  return make_mapping_statusline({
    { key = "e", description = "edit var" },
    { key = "<Tab>", description = "expand/collapse children" },
    { key = "r", description = "send var to REPL" },
  })
end

function DapuiStacksStatusLine()
  return make_mapping_statusline({
    { key = "o", description = "jump to place in stack frame" },
    { key = "t", description = "toggle subtle frames" },
  })
end

function DapuiWatchesStatusLine()
  return make_mapping_statusline({
    { key = "e", description = "edit expression or child var" },
    { key = "<Tab>", description = "toggle child vars" },
    { key = "r", description = "send expression to REPL" },
    { key = "d", description = "remove watch" },
  })
end

function DapuiBreakpointsStatusLine()
  return make_mapping_statusline({
    { key = "o", description = "jump to breakpoint" },
    { key = "t", description = "toggle breakpoint" },
  })
end

function DapuiReplStatusLine()
  return make_mapping_statusline({
    { mods = { "C" }, key = "uiop", description = "step back/into/out/over" },
    { key = "<CR>", description = "play" },
    { mods = { "C" }, key = "c", description = "terminate" },
    { mods = { "C" }, key = "d", description = "disconnect" },
    { mods = { "C" }, key = "r", description = "run last" },
  })
end
-- }}}

-- telescope statusline {{{
function TelescopeStatusLine(is_menufacture_open)
  local mappings = {
    { mods = { "C" }, key = "q", description = "Quickfix" },
    { mods = { "M" }, key = "<CR>", description = "Multi-select" },
    { mods = { "C" }, key = "j/k", description = "Scroll preview" },
  }
  if is_menufacture_open then
    table.insert(mappings, { mods = { "C" }, key = "f", description = "Filter" })
  end
  return make_mapping_statusline(mappings)
end
-- }}}
