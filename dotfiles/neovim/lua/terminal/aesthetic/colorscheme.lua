Plug("nordtheme/vim", {
  -- I need this config to be applied earlier so you don't see a flash of the default color scheme
  -- and then mine.
  sync = true,
  config = function()
    vim.cmd.colorscheme("nord")
  end,
})
vim.g.nord_bold = true
vim.g.nord_underline = true
function SetNordOverrides()
  vim.api.nvim_set_hl(0, "MatchParen", { ctermfg = "blue", ctermbg = "NONE", underline = true })
  -- Transparent vertical split
  vim.api.nvim_set_hl(0, "WinSeparator", { ctermbg = "NONE", ctermfg = 15 })
  -- statusline colors
  vim.api.nvim_set_hl(0, "StatusLine", { ctermbg = 51, ctermfg = "NONE" })
  vim.api.nvim_set_hl(
    0,
    "StatusLineSeparator",
    { ctermfg = 51, ctermbg = "NONE", reverse = true, bold = true }
  )
  vim.api.nvim_set_hl(0, "StatusLineErrorText", { ctermfg = 1, ctermbg = 51 })
  vim.api.nvim_set_hl(0, "StatusLineWarningText", { ctermfg = 3, ctermbg = 51 })
  vim.api.nvim_set_hl(0, "StatusLineInfoText", { ctermfg = 4, ctermbg = 51 })
  vim.api.nvim_set_hl(0, "StatusLineHintText", { ctermfg = 5, ctermbg = 51 })
  vim.api.nvim_set_hl(0, "StatusLineStandoutText", { ctermfg = 3, ctermbg = 51 })
  vim.cmd([[
    " Clearing the highlight first since highlights don't get overriden with the vimscript API, they
    " get combined.
    hi clear CursorLine
    hi CursorLine guisp='foreground' cterm=underline ctermbg='NONE'
  ]])
  vim.api.nvim_set_hl(0, "CursorLineNr", { bold = true })
  -- transparent background
  vim.api.nvim_set_hl(0, "Normal", { ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "EndOfBuffer", { ctermbg = "NONE" })
  -- relative line numbers
  vim.api.nvim_set_hl(0, "LineNr", { ctermfg = 15 })
  vim.api.nvim_set_hl(0, "LineNrAbove", { link = "LineNr" })
  vim.api.nvim_set_hl(0, "LineNrBelow", { link = "LineNrAbove" })
  vim.api.nvim_set_hl(0, "MiniCursorword", { ctermbg = 51 })
  vim.api.nvim_set_hl(0, "IncSearch", { link = "Search" })
  vim.api.nvim_set_hl(0, "TabLineBorder", { ctermbg = "NONE", ctermfg = 51 })
  vim.api.nvim_set_hl(0, "TabLineBorder2", { ctermbg = 51, ctermfg = 0 })
  -- The `TabLine*` highlights are the so the tabline looks blank before bufferline populates it so
  -- it needs the same background color as bufferline. The foreground needs to match the background
  -- so you can't see the text from the original tabline function.
  vim.api.nvim_set_hl(0, "TabLine", { ctermbg = 0, ctermfg = 0 })
  vim.api.nvim_set_hl(0, "TabLineFill", { link = "TabLine" })
  vim.api.nvim_set_hl(0, "TabLineSel", { link = "TabLine" })
  vim.api.nvim_set_hl(0, "Comment", { ctermfg = 15, ctermbg = "NONE", italic = true })
  -- This variable contains a list of 16 colors that should be used as the color palette for
  -- terminals opened in vim. By unsetting this, I ensure that terminals opened in vim will use the
  -- colors from the color palette of the terminal in which vim is running
  vim.g.terminal_ansi_colors = nil
  -- Have vim only use the colors from the color palette of the terminal in which it runs
  vim.o.t_Co = 256
  vim.api.nvim_set_hl(0, "Visual", { ctermbg = 3, ctermfg = 0 })
  -- Search hit
  vim.api.nvim_set_hl(0, "Search", { ctermfg = "DarkYellow", ctermbg = "NONE", reverse = true })
  -- Parentheses
  vim.api.nvim_set_hl(0, "Delimiter", { ctermfg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "ErrorMsg", { ctermfg = 1, ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "WarningMsg", { ctermfg = 3, ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "Error", { ctermfg = 1, ctermbg = "NONE", undercurl = true })
  vim.api.nvim_set_hl(0, "Warning", { ctermfg = 3, ctermbg = "NONE", undercurl = true })
  vim.api.nvim_set_hl(0, "SpellBad", { link = "Error" })
  vim.api.nvim_set_hl(0, "NvimInternalError", { link = "ErrorMsg" })
  vim.api.nvim_set_hl(0, "Folded", { ctermfg = 15, ctermbg = 53 })
  vim.api.nvim_set_hl(0, "FoldColumn", { ctermfg = 15, ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "SpecialKey", { ctermfg = 13, ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "NonText", { ctermfg = 51, ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "Whitespace", { ctermfg = 15, ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "DiagnosticSignError", { ctermfg = 1, ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "DiagnosticSignWarn", { ctermfg = 3, ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "DiagnosticSignInfo", { ctermfg = 4, ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "DiagnosticSignHint", { ctermfg = 5, ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { ctermfg = 1, italic = true, bold = true })
  vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { ctermfg = 3, italic = true, bold = true })
  vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", { ctermfg = 4, italic = true, bold = true })
  vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { ctermfg = 5, italic = true, bold = true })
  vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { link = "Error" })
  vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { link = "Warning" })
  vim.api.nvim_set_hl(
    0,
    "DiagnosticUnderlineInfo",
    { ctermfg = 4, ctermbg = "NONE", undercurl = true }
  )
  vim.api.nvim_set_hl(
    0,
    "DiagnosticUnderlineHint",
    { ctermfg = 5, ctermbg = "NONE", undercurl = true }
  )
  vim.api.nvim_set_hl(0, "DiagnosticInfo", { link = "DiagnosticSignInfo" })
  vim.api.nvim_set_hl(0, "DiagnosticHint", { link = "DiagnosticSignHint" })
  vim.api.nvim_set_hl(0, "CmpItemAbbrMatch", { ctermbg = "NONE", ctermfg = 6 })
  vim.api.nvim_set_hl(0, "CmpItemAbbrMatchFuzzy", { link = "CmpItemAbbrMatch" })
  vim.api.nvim_set_hl(0, "CmpItemKind", { ctermbg = "NONE", ctermfg = 15 })
  vim.api.nvim_set_hl(0, "CmpItemMenu", { link = "CmpItemKind" })
  vim.api.nvim_set_hl(0, "CmpNormal", { link = "CmpDocumentationNormal" })
  vim.api.nvim_set_hl(0, "CmpDocumentationNormal", { ctermbg = 51 })
  vim.api.nvim_set_hl(0, "CmpDocumentationBorder", { ctermbg = 51, ctermfg = 52 })
  vim.api.nvim_set_hl(0, "CmpCursorLine", { ctermfg = 6, ctermbg = "NONE", reverse = true })
  vim.api.nvim_set_hl(0, "CmpGhostText", { link = "GitBlameVirtualText" })
  -- autocomplete popupmenu
  vim.api.nvim_set_hl(0, "PmenuSel", { ctermfg = 6, ctermbg = "NONE", reverse = true })
  vim.api.nvim_set_hl(0, "Pmenu", { ctermfg = "NONE", ctermbg = 24 })
  vim.api.nvim_set_hl(0, "PmenuThumb", { ctermfg = "NONE", ctermbg = 15 })
  vim.api.nvim_set_hl(0, "PmenuSbar", { link = "CmpNormal" })
  -- List of telescope highlight groups:
  -- https://github.com/nvim-telescope/telescope.nvim/blob/master/plugin/telescope.lua
  local telescope_bg_prompt = 53
  local telescope_bg = 16
  vim.api.nvim_set_hl(0, "TelescopePromptNormal", { ctermbg = telescope_bg_prompt })
  vim.api.nvim_set_hl(
    0,
    "TelescopePromptBorder",
    { ctermbg = telescope_bg_prompt, ctermfg = telescope_bg_prompt }
  )
  vim.api.nvim_set_hl(
    0,
    "TelescopePromptTitle",
    { ctermbg = 6, ctermfg = telescope_bg, bold = true }
  )
  vim.api.nvim_set_hl(0, "TelescopePromptCounter", { ctermfg = 15 })
  vim.api.nvim_set_hl(0, "TelescopePromptPrefix", { ctermbg = telescope_bg_prompt, ctermfg = 6 })
  vim.api.nvim_set_hl(0, "TelescopePreviewNormal", { link = "TelescopeResultsNormal" })
  vim.api.nvim_set_hl(
    0,
    "TelescopePreviewBorder",
    { ctermbg = telescope_bg, ctermfg = telescope_bg_prompt }
  )
  vim.api.nvim_set_hl(
    0,
    "TelescopePreviewTitle",
    { ctermbg = 6, ctermfg = telescope_bg, bold = true }
  )
  vim.api.nvim_set_hl(0, "TelescopeResultsNormal", { ctermbg = telescope_bg })
  vim.api.nvim_set_hl(
    0,
    "TelescopeResultsBorder",
    { ctermbg = telescope_bg, ctermfg = telescope_bg }
  )
  vim.api.nvim_set_hl(0, "TelescopeResultsTitle", { link = "TelescopeResultsBorder" })
  vim.api.nvim_set_hl(0, "TelescopeMatching", { ctermbg = "NONE", ctermfg = 6 })
  vim.api.nvim_set_hl(0, "TelescopeSelection", { ctermbg = telescope_bg_prompt, bold = true })
  vim.api.nvim_set_hl(0, "TelescopeSelectionCaret", { link = "TelescopeSelection" })
  vim.api.nvim_set_hl(
    0,
    "MasonHeader",
    { ctermbg = "NONE", ctermfg = 4, reverse = true, bold = true }
  )
  vim.api.nvim_set_hl(0, "MasonHighlight", { ctermbg = "NONE", ctermfg = 6 })
  vim.api.nvim_set_hl(
    0,
    "MasonHighlightBlockBold",
    { ctermbg = "NONE", ctermfg = 6, reverse = true, bold = true }
  )
  vim.api.nvim_set_hl(0, "MasonMuted", { ctermbg = "NONE", ctermfg = "NONE" })
  vim.api.nvim_set_hl(0, "MasonMutedBlock", { ctermbg = "NONE", ctermfg = 15, reverse = true })
  vim.api.nvim_set_hl(0, "MasonError", { ctermbg = "NONE", ctermfg = 1 })
  vim.api.nvim_set_hl(0, "MasonNormal", { link = "Float4Normal" })
  vim.api.nvim_set_hl(0, "NormalFloat", { link = "Float1Normal" })
  vim.api.nvim_set_hl(0, "FloatBorder", { link = "Float1Border" })
  vim.api.nvim_set_hl(0, "LuaSnipNode", { ctermfg = 11 })
  vim.api.nvim_set_hl(0, "WhichKeyFloat", { link = "Float1Normal" })
  vim.api.nvim_set_hl(0, "WhichKeyBorder", { link = "Float1Border" })
  vim.api.nvim_set_hl(0, "CodeActionSign", { ctermbg = "NONE", ctermfg = 3 })
  vim.api.nvim_set_hl(0, "LspInfoBorder", { ctermbg = 16, ctermfg = 52 })
  vim.api.nvim_set_hl(0, "Float1Normal", { ctermbg = 16 })
  vim.api.nvim_set_hl(0, "Float1Border", { ctermbg = 16, ctermfg = 52 })
  vim.api.nvim_set_hl(0, "Float2Normal", { ctermbg = 24 })
  vim.api.nvim_set_hl(0, "Float2Border", { link = "Float2Normal" })
  vim.api.nvim_set_hl(0, "Float3Normal", { ctermbg = 51 })
  vim.api.nvim_set_hl(0, "Float3Border", { link = "Float3Normal" })
  vim.api.nvim_set_hl(0, "Float4Normal", { ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "Float4Border", { ctermbg = "NONE", ctermfg = 15 })
  vim.api.nvim_set_hl(0, "StatusLineRecordingIndicator", { ctermbg = 51, ctermfg = 1 })
  vim.api.nvim_set_hl(0, "StatusLineShowcmd", { ctermbg = 51, ctermfg = 6 })
  vim.api.nvim_set_hl(0, "StatusLineMasonUpdateIndicator", { ctermbg = 51, ctermfg = 2 })
  vim.api.nvim_set_hl(0, "StatusLinePowerlineOuter", { ctermbg = "NONE", ctermfg = 51 })
  vim.api.nvim_set_hl(0, "NvimTreeIndentMarker", { ctermfg = 15 })
  vim.api.nvim_set_hl(0, "MsgArea", { link = "StatusLine" })
  vim.api.nvim_set_hl(0, "FidgetAccent", { ctermbg = "NONE", ctermfg = 7, italic = true })
  vim.api.nvim_set_hl(0, "FidgetNormal", { ctermbg = "NONE", ctermfg = 15, italic = true })
  vim.api.nvim_set_hl(0, "FidgetIcon", { ctermbg = "NONE", ctermfg = 5, italic = true })
  vim.api.nvim_set_hl(0, "NavicIconsFile", { ctermfg = 2 })
  vim.api.nvim_set_hl(0, "NavicIconsModule", { ctermfg = 4 })
  vim.api.nvim_set_hl(0, "NavicIconsNamespace", { ctermfg = 5 })
  vim.api.nvim_set_hl(0, "NavicIconsPackage", { ctermfg = 6 })
  vim.api.nvim_set_hl(0, "NavicIconsClass", { ctermfg = 10 })
  vim.api.nvim_set_hl(0, "NavicIconsMethod", { ctermfg = 11 })
  vim.api.nvim_set_hl(0, "NavicIconsProperty", { ctermfg = 12 })
  vim.api.nvim_set_hl(0, "NavicIconsField", { ctermfg = 13 })
  vim.api.nvim_set_hl(0, "NavicIconsConstructor", { ctermfg = 14 })
  vim.api.nvim_set_hl(0, "NavicIconsEnum", { ctermfg = 2 })
  vim.api.nvim_set_hl(0, "NavicIconsInterface", { ctermfg = 4 })
  vim.api.nvim_set_hl(0, "NavicIconsFunction", { ctermfg = 5 })
  vim.api.nvim_set_hl(0, "NavicIconsVariable", { ctermfg = 6 })
  vim.api.nvim_set_hl(0, "NavicIconsConstant", { ctermfg = 10 })
  vim.api.nvim_set_hl(0, "NavicIconsString", { ctermfg = 11 })
  vim.api.nvim_set_hl(0, "NavicIconsNumber", { ctermfg = 12 })
  vim.api.nvim_set_hl(0, "NavicIconsBoolean", { ctermfg = 13 })
  vim.api.nvim_set_hl(0, "NavicIconsArray", { ctermfg = 14 })
  vim.api.nvim_set_hl(0, "NavicIconsObject", { ctermfg = 2 })
  vim.api.nvim_set_hl(0, "NavicIconsKey", { ctermfg = 4 })
  vim.api.nvim_set_hl(0, "NavicIconsNull", { ctermfg = 5 })
  vim.api.nvim_set_hl(0, "NavicIconsEnumMember", { ctermfg = 6 })
  vim.api.nvim_set_hl(0, "NavicIconsStruct", { ctermfg = 10 })
  vim.api.nvim_set_hl(0, "NavicIconsEvent", { ctermfg = 11 })
  vim.api.nvim_set_hl(0, "NavicIconsOperator", { ctermfg = 12 })
  vim.api.nvim_set_hl(0, "NavicIconsTypeParameter", { ctermfg = 13 })
  vim.api.nvim_set_hl(0, "NavicText", { italic = true, bold = true })
  vim.api.nvim_set_hl(0, "NavicSeparator", { ctermfg = 15 })
  vim.api.nvim_set_hl(0, "SignifyAdd", { ctermfg = 2 })
  vim.api.nvim_set_hl(0, "SignifyDelete", { ctermfg = 1 })
  vim.api.nvim_set_hl(0, "SignifyChange", { ctermfg = 3 })
  vim.api.nvim_set_hl(0, "QuickFixLine", { ctermfg = "NONE", ctermbg = 51 })
  vim.api.nvim_set_hl(0, "GitBlameVirtualText", { ctermfg = 15, italic = true, bold = true })
  vim.api.nvim_set_hl(0, "Underlined", {})
  vim.api.nvim_set_hl(0, "NullLsInfoBorder", { link = "FloatBorder" })
  vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { ctermbg = "NONE", ctermfg = 15 })
  vim.api.nvim_set_hl(0, "MiniJump2dSpot", { ctermbg = "NONE", ctermfg = 3 })
  vim.api.nvim_set_hl(0, "MiniJump2dSpotUnique", { link = "MiniJump2dSpot" })
  vim.api.nvim_set_hl(0, "MiniJump2dSpotAhead", { link = "MiniJump2dSpot" })
  vim.api.nvim_set_hl(0, "MiniJump2dDim", { ctermbg = "NONE", ctermfg = 15 })
  vim.api.nvim_set_hl(0, "WidgetFill", { ctermbg = "NONE", ctermfg = 15 })

  local level_highlights = {
    { level = "ERROR", color = 1 },
    { level = "WARN", color = 3 },
    { level = "INFO", color = 4 },
    { level = "DEBUG", color = 15 },
    { level = "TRACE", color = 5 },
  }
  for _, highlight in pairs(level_highlights) do
    local level = highlight.level
    local color = highlight.color
    vim.api.nvim_set_hl(
      0,
      string.format("Notify%sBorder", level),
      { ctermbg = "NONE", ctermfg = color }
    )
    vim.api.nvim_set_hl(
      0,
      string.format("Notify%sIcon", level),
      { ctermbg = "NONE", ctermfg = color }
    )
    vim.api.nvim_set_hl(
      0,
      string.format("Notify%sTitle", level),
      { ctermbg = "NONE", ctermfg = color }
    )
    -- I wanted to set ctermfg to NONE, but when I did, it wouldn't override nvim-notify's default
    -- highlight.
    vim.api.nvim_set_hl(0, string.format("Notify%sBody", level), { ctermbg = "NONE", ctermfg = 7 })
  end

  local mode_highlights = {
    { mode = "Normal", color = "NONE" },
    { mode = "Visual", color = 3 },
    { mode = "Insert", color = 6 },
    { mode = "Terminal", color = 2 },
    { mode = "Other", color = 4 },
  }
  for _, highlight in pairs(mode_highlights) do
    local mode = highlight.mode
    local color = highlight.color
    vim.api.nvim_set_hl(
      0,
      string.format("StatusLineMode%s", mode),
      { ctermbg = 51, ctermfg = color, bold = true }
    )
    vim.api.nvim_set_hl(
      0,
      string.format("StatusLineMode%sPowerlineOuter", mode),
      { ctermbg = "NONE", ctermfg = 51 }
    )
    vim.api.nvim_set_hl(
      0,
      string.format("StatusLineMode%sPowerlineInner", mode),
      { ctermbg = 51, ctermfg = 0 }
    )
  end
end
local nord_vim_group_id = vim.api.nvim_create_augroup("NordVim", {})
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "nord",
  callback = SetNordOverrides,
  group = nord_vim_group_id,
})
