-- vim:foldmethod=marker

-- lush.nvim Banner {{{
--
-- Built with,
--
--        ,gggg,
--       d8" "8I                         ,dPYb,
--       88  ,dP                         IP'`Yb
--    8888888P"                          I8  8I
--       88                              I8  8'
--       88        gg      gg    ,g,     I8 dPgg,
--  ,aa,_88        I8      8I   ,8'8,    I8dP" "8I
-- dP" "88P        I8,    ,8I  ,8'  Yb   I8P    I8
-- Yb,_,d88b,,_   ,d8b,  ,d8b,,8'_   8) ,d8     I8,
--  "Y8P"  "Y888888P'"Y88P"`Y8P' "YY8P8P88P     `Y8
--
-- https://github.com/rktjmp/lush.nvim
-- }}}

-- This variable contains a list of 16 colors that should be used as the color palette for terminals
-- opened in vim. By unsetting this, I ensure that terminals opened in vim will use the colors from
-- the color palette of the terminal in which vim is running
vim.g.terminal_ansi_colors = nil

local lush = require("lush")
local hsl = lush.hsl
-- LSP/Linters mistakenly show `undefined global` errors in the spec, they may support an annotation
-- like the following. Consult your server documentation.
---@diagnostic disable: undefined-global
local theme = lush(function(injected_functions)
  local sym = injected_functions.sym
  return {
    -- An empty definition `{}` will clear all styling, leaving elements looking like the 'Normal'
    -- group.  To be able to link to a group, it must already be defined, so you may have to reorder
    -- items as you go.

    -- terminal palette {{{
    background { bg = hsl("#1d2129") },
    -- If you're in the lush live preview (:Lushify) the color below will be invisible.
    t_0 { fg = hsl("#1d2129") },
    t_1 { fg = hsl("#BF616A") },
    t_2 { fg = hsl("#A3BE8C") },
    t_3 { fg = hsl("#EBCB8B") },
    t_4 { fg = hsl("#81A1C1") },
    t_5 { fg = hsl("#B48EAD") },
    t_6 { fg = hsl("#88C0D0") },
    t_7 { fg = hsl("#D8DEE9") },
    t_8 { fg = hsl("#78849b") },
    t_9 { fg = hsl("#BF616A") },
    t_10 { fg = hsl("#A3BE8C") },
    t_11 { fg = hsl("#d08770") },
    t_12 { fg = hsl("#81A1C1") },
    t_13 { fg = hsl("#B48EAD") },
    t_14 { fg = hsl("#8FBCBB") },
    t_15 { fg = hsl("#78849b") },
    -- }}}

    -- modes {{{
    Normal { bg = "NONE", fg = hsl("#d8dee9") }, -- Normal text
    NormalNC {}, -- normal text in non-current windows
    Visual { t_3, reverse = true }, -- Visual mode selection
    VisualNOS {}, -- Visual mode selection when vim is "Not Owning the Selection".
    -- }}}

    -- search {{{
    Search { Visual }, -- Last search pattern highlighting (see 'hlsearch'). Also used for similar items that need to stand out.
    CurSearch { Search }, -- Highlighting a search pattern under the cursor (see 'hlsearch')
    IncSearch { Search }, -- 'incsearch' highlighting; also used for the text replaced with ":s///c"
    -- }}}

    -- diagnostics {{{
    ErrorMsg { t_1 }, -- Error messages on the command line
    WarningMsg { t_3 }, -- Warning messages
    Error { ErrorMsg, undercurl = true }, -- Any erroneous construct
    Warning { WarningMsg, undercurl = true }, -- (I added this)
    -- }}}

    -- float {{{
    NormalFloat { bg = background.bg.darken(35) }, -- Normal text in floating windows.
    FloatBorder { NormalFloat, fg = background.bg.li(8) }, -- Border of floating windows.
    FloatTitle { NormalFloat, fg = t_6.fg }, -- Title of floating windows.
    -- }}}

    -- syntax groups {{{
    -- Common vim syntax groups used for all kinds of code and markup.
    -- Commented-out groups should chain up to their preferred (*) group
    -- by default.
    --
    -- See :h group-name
    --
    -- Uncomment and edit if you want more specific syntax highlighting.

    Comment { fg = t_15.fg, italic = true }, -- Any comment

    Statement { t_4 }, -- (*) Any statement
    -- Conditional    { }, --   if, then, else, endif, switch, etc.
    -- Repeat         { }, --   for, do, while, etc.
    -- Label          { }, --   case, default, etc.
    -- Operator       { }, --   "sizeof", "+", "*", etc.
    -- Keyword        { }, --   any other keyword
    -- Exception      { }, --   try, catch, throw

    Identifier {}, -- (*) Any variable name
    -- Function       { }, --   Function name (also: methods for classes)

    PreProc { Statement }, -- (*) Generic Preprocessor
    -- Include        { }, --   Preprocessor #include
    -- Define         { }, --   Preprocessor #define
    -- Macro          { }, --   Same as Define
    -- PreCondit      { }, --   Preprocessor #if, #else, #endif, etc.

    Type { Statement }, -- (*) int, long, char, etc.
    -- StorageClass   { }, --   static, register, volatile, etc.
    -- Structure      { }, --   struct, union, enum, etc.
    -- Typedef        { }, --   A typedef

    Special {}, -- (*) Any special symbol
    -- SpecialChar    { }, --   Special character in a constant
    -- Tag            { }, --   You can use CTRL-] on this
    -- Delimiter      { }, --   Character that needs attention
    -- SpecialComment { }, --   Special things inside a comment (e.g. '\n')
    -- Debug          { }, --   Debugging statements

    Constant { t_2 }, -- (*) Any constant
    String { t_2 }, --   A string constant: "this is a string"
    -- Character      { }, --   A character constant: 'c', '\n'
    -- Number         { }, --   A number constant: 234, 0xff
    -- Boolean        { }, --   A boolean constant: TRUE, false
    -- Float          { }, --   A floating point constant: 2.3e10
    -- }}}

    -- diffs {{{
    DiffAdd { bg = t_2.fg.da(60) }, -- Diff mode: Added line |diff.txt|
    DiffChange { bg = t_3.fg.da(60) }, -- Diff mode: Changed line |diff.txt|
    DiffDelete { bg = t_1.fg.da(60) }, -- Diff mode: Deleted line |diff.txt|
    DiffText { bg = t_3.fg.da(50) }, -- Diff mode: Changed text within a changed line |diff.txt|
    diffAdded { DiffAdd },
    diffRemoved { DiffDelete },
    diffChanged { DiffChange },
    -- }}}

    -- line numbers {{{
    LineNr { fg = t_15.fg }, -- Line number for ":number" and ":#" commands, and when 'number' or 'relativenumber' option is set.
    LineNrAbove { LineNr }, -- Line number for when the 'relativenumber' option is set, above the cursor line
    LineNrBelow { LineNrAbove }, -- Line number for when the 'relativenumber' option is set, below the cursor line
    -- }}}

    -- cursorline {{{
    CursorLine { underline = true, sp = "fg" }, -- Screen-line at the cursor, when 'cursorline' is set. Low-priority if foreground (ctermfg OR guifg) is not set.
    CursorLineNr { bold = true }, -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.
    -- CursorLineFold { }, -- Like FoldColumn when 'cursorline' is set for the cursor line
    -- CursorLineSign { }, -- Like SignColumn when 'cursorline' is set for the cursor line
    -- }}}

    -- statusline {{{
    StatusLine { bg = background.bg.lighten(6) }, -- Status line of current window
    StatusLineFill { StatusLine, fg = StatusLine.bg },
    StatusLineSeparator { StatusLine, fg = background.bg, bold = true },
    StatusLineErrorText { StatusLine, fg = Error.fg },
    StatusLineWarningText { StatusLine, fg = Warning.fg },
    StatusLineStandoutText { StatusLineWarningText },
    StatusLineInfoText { StatusLine, fg = Statement.fg },
    StatusLineHintText { StatusLine, fg = t_5.fg },
    StatusLineNC { StatusLine }, -- Status lines of not-current windows. Note: If this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.
    StatusLineRecordingIndicator { StatusLine, fg = ErrorMsg.fg },
    StatusLineShowcmd { StatusLine, fg = FloatTitle.fg },
    StatusLineMasonUpdateIndicator { StatusLine, fg = String.fg },
    StatusLinePowerlineOuter { fg = StatusLine.bg },
    StatusLinePowerlineInner { StatusLine, fg = background.bg },
    StatusLineModeNormal { StatusLine, bold = true },
    StatusLineModeVisual { StatusLine, fg = Visual.bg, bold = true },
    StatusLineModeInsert { StatusLine, fg = t_6.fg, bold = true },
    StatusLineModeTerminal { StatusLine, fg = t_2.fg, bold = true },
    StatusLineModeOther { StatusLine, fg = t_4.fg, bold = true },
    -- }}}

    -- tabline {{{
    -- The `TabLine*` highlights are the so the tabline looks blank before bufferline populates it so
    -- it needs the same background color as bufferline. The foreground needs to match the background
    -- so you can't see the text from the original tabline function.
    TabLine { fg = background.bg }, -- Tab pages line, not active tab page label
    TabLineFill { TabLine }, -- Tab pages line, where there are no labels
    TabLineSel { TabLine }, -- Tab pages line, active tab page label
    -- }}}

    SpecialKey { t_5 }, -- Unprintable characters: text displayed differently from what it really is. But not 'listchars' whitespace. |hl-Whitespace|
    Conceal { t_15 }, -- Placeholder characters substituted for concealed text (see 'conceallevel')
    Directory { Statement }, -- Directory names (and other special names in listings)
    EndOfBuffer {}, -- Filler lines (~) after the end of the buffer. By default, this is highlighted like |hl-NonText|.
    Folded { bg = background.bg.lighten(3) }, -- Line used for closed folds
    FoldColumn { fg = t_15.fg }, -- 'foldcolumn'
    SignColumn {}, -- Column where |signs| are displayed
    Substitute { Search }, -- |:substitute| replacement text highlighting
    MatchParen { t_5, bold = true, underline = true }, -- Character under the cursor or just before it, if it is a paired bracket, and its match. |pi_paren.txt|
    ModeMsg {}, -- 'showmode' message (e.g., "-- INSERT -- ")
    MsgArea { StatusLine }, -- Area for messages and cmdline
    MsgSeparator {}, -- Separator for scrolled messages, `msgsep` flag of 'display'
    MoreMsg {}, -- |more-prompt|
    NonText { fg = background.bg.lighten(20) }, -- '@' at the end of the window, characters from 'showbreak' and other characters that do not really exist in the text (e.g., ">" displayed when a double-wide character doesn't fit at the end of the line). See also |hl-EndOfBuffer|.
    Question {}, -- |hit-enter| prompt and yes/no questions
    QuickFixLine { bg = background.bg.lighten(10) }, -- Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
    SpellBad { Error }, -- Word that is not recognized by the spellchecker. |spell| Combined with the highlighting used otherwise.
    SpellCap { Warning }, -- Word that should start with a capital. |spell| Combined with the highlighting used otherwise.
    Title { Normal }, -- Titles for output from ":set all", ":autocmd" etc.
    Whitespace { fg = background.bg.lighten(30) }, -- "nbsp", "space", "tab" and "trail" in 'listchars'
    Winseparator { fg = background.bg.lighten(30) }, -- Separator between window splits. Inherts from |hl-VertSplit| by default, which it will replace eventually.
    ColorColumn { Winseparator },
    WinBar { bold = true, italic = true }, -- Window bar of current window
    WinBarNC { WinBar }, -- Window bar of not-current windows
    NvimInternalError { ErrorMsg },
    BufferLineTabLeftBorder { fg = StatusLine.bg, reverse = true },
    GitBlameVirtualText { Comment, bold = true },
    WhichKeyFloat { NormalFloat },
    WhichKeyBorder { FloatBorder },
    LuaSnipNode { fg = hsl("#d08770") },
    CodeActionSign { t_3 },
    NvimTreeIndentMarker { fg = Comment.fg },
    NullLsInfoBorder { FloatBorder },
    WidgetFill { fg = t_15.fg },
    Underlined {}, -- Text that stands out, HTML links
    Ignore { fg = background.bg }, -- Left blank, hidden |hl-Ignore| (NOTE: May be invisible here in template)
    Todo { t_3 }, -- Anything that needs extra attention; mostly the keywords TODO FIXME and XXX

    -- nvim-cmp {{{
    -- TODO: figure out interaction with pmenu
    CmpGhostText { GitBlameVirtualText },
    CmpNormal { bg = background.bg.lighten(5) },
    CmpItemKind { fg = CmpNormal.bg.li(55) },
    CmpItemMenu { CmpItemKind },
    CmpDocumentationNormal { CmpNormal },
    CmpDocumentationBorder { CmpDocumentationNormal, fg = CmpDocumentationNormal.bg.li(20) },
    CmpItemAbbrMatch { fg = FloatTitle.fg },
    CmpItemAbbrMatchFuzzy { CmpItemAbbrMatch },
    CmpCursorLine { CmpItemAbbrMatch, reverse = true },
    -- }}}

    -- pmenu (autocomplete) {{{
    Pmenu { CmpNormal }, -- Popup menu: Normal item.
    PmenuSel { bg = FloatTitle.fg, fg = background.bg }, -- Popup menu: Selected item.
    PmenuKind { CmpItemKind }, -- Popup menu: Normal item "kind"
    PmenuKindSel { PmenuSel }, -- Popup menu: Selected item "kind"
    PmenuExtra { PmenuKind }, -- Popup menu: Normal item "extra text"
    PmenuExtraSel { PmenuKindSel }, -- Popup menu: Selected item "extra text"
    PmenuSbar { Pmenu }, -- Popup menu: Scrollbar.
    PmenuThumb { bg = PmenuSbar.bg.li(30) }, -- Popup menu: Thumb of the scrollbar.
    -- }}}

    -- mason.nvim {{{
    MasonHeader { Statement, bold = true, reverse = true },
    MasonHeaderSecondary { MasonHeader },
    MasonHighlight { fg = FloatTitle.fg },
    MasonHighlightBlockBold { MasonHighlight, bold = true, reverse = true },
    MasonHighlightBlock { MasonHighlightBlockBold },
    MasonMuted {},
    MasonMutedBlock { fg = background.bg.li(40), reverse = true },
    MasonMutedBlockBold { MasonMutedBlock },
    MasonError { ErrorMsg },
    MasonNormal { bg = "NONE", nocombine = true },
    -- }}}

    -- fidget.nvim {{{
    FidgetNormal { Comment, bold = true },
    FidgetAccent { FidgetNormal, fg = Normal.fg },
    FidgetIcon { FidgetNormal, fg = t_5.fg },
    -- }}}

    -- vim-signify {{{
    SignifyAdd { fg = t_2.fg },
    SignifyDelete { fg = t_1.fg },
    SignifyChange { fg = t_3.fg },
    -- }}}

    -- mini.nvim {{{
    MiniIndentscopeSymbol { fg = t_15.fg },
    MiniJump2dSpot { fg = t_3.fg },
    MiniJump2dSpotUnique { MiniJump2dSpot },
    MiniJump2dSpotAhead { MiniJump2dSpot },
    MiniJump2dDim { fg = t_15.fg },
    MiniCursorword { bg = background.bg.lighten(6) },
    -- }}}

    -- nvim-telescope {{{
    -- List of telescope highlight groups:
    -- https://github.com/nvim-telescope/telescope.nvim/blob/master/plugin/telescope.lua
    TelescopePromptNormal { bg = background.bg.lighten(5) },
    TelescopePromptBorder { TelescopePromptNormal, fg = TelescopePromptNormal.bg },
    TelescopePromptTitle { FloatTitle, reverse = true, bold = true },
    TelescopePromptCounter { TelescopePromptNormal, fg = TelescopePromptNormal.bg.li(40) },
    TelescopePromptPrefix { TelescopePromptNormal, fg = FloatTitle.fg },
    TelescopeResultsNormal { NormalFloat },
    TelescopeResultsBorder { TelescopeResultsNormal, fg = TelescopeResultsNormal.bg },
    TelescopePreviewNormal { TelescopeResultsNormal },
    TelescopePreviewBorder { TelescopePreviewNormal, fg = TelescopePromptNormal.bg },
    TelescopeMatching { fg = FloatTitle.fg },
    TelescopeSelection { bg = TelescopeResultsNormal.bg.li(10) },
    TelescopeSelectionCaret { TelescopeSelection },
    -- }}}

    -- nvim-notify {{{
    NotifyBackground { background },
    NotifyERRORTitle { fg = t_1.fg },
    NotifyERRORBorder { NotifyERRORTitle },
    NotifyERRORIcon { NotifyERRORTitle },
    NotifyWARNTitle { fg = t_3.fg },
    NotifyWARNBorder { NotifyWARNTitle },
    NotifyWARNIcon { NotifyWARNTitle },
    NotifyINFOTitle { fg = t_4.fg },
    NotifyINFOBorder { NotifyINFOTitle },
    NotifyINFOIcon { NotifyINFOTitle },
    NotifyDEBUGTitle { fg = t_15.fg },
    NotifyDEBUGBorder { NotifyDEBUGTitle },
    NotifyDEBUGIcon { NotifyDEBUGTitle },
    NotifyTRACETitle { fg = t_5.fg },
    NotifyTRACEBorder { NotifyTRACETitle },
    NotifyTRACEIcon { NotifyTRACETitle },
    -- }}}

    -- nvim-navic {{{
    NavicIconsFile { WinBar, fg = String.fg },
    NavicIconsModule { WinBar, fg = Statement.fg },
    NavicIconsNamespace { WinBar, fg = t_5.fg },
    NavicIconsPackage { WinBar, fg = FloatTitle.fg },
    NavicIconsClass { WinBar, fg = t_10.fg },
    NavicIconsMethod { WinBar, fg = t_11.fg },
    NavicIconsProperty { WinBar, fg = t_12.fg },
    NavicIconsField { WinBar, fg = t_13.fg },
    NavicIconsConstructor { WinBar, fg = t_14.fg },
    NavicIconsEnum { WinBar, fg = String.fg },
    NavicIconsInterface { WinBar, fg = Statement.fg },
    NavicIconsFunction { WinBar, fg = t_5.fg },
    NavicIconsVariable { WinBar, fg = FloatTitle.fg },
    NavicIconsConstant { WinBar, fg = t_10.fg },
    NavicIconsString { WinBar, fg = t_11.fg },
    NavicIconsNumber { WinBar, fg = t_12.fg },
    NavicIconsBoolean { WinBar, fg = t_13.fg },
    NavicIconsArray { WinBar, fg = t_14.fg },
    NavicIconsObject { WinBar, fg = String.fg },
    NavicIconsKey { WinBar, fg = Statement.fg },
    NavicIconsNull { WinBar, fg = t_5.fg },
    NavicIconsEnumMember { WinBar, fg = FloatTitle.fg },
    NavicIconsStruct { WinBar, fg = t_10.fg },
    NavicIconsEvent { WinBar, fg = t_11.fg },
    NavicIconsOperator { WinBar, fg = t_12.fg },
    NavicIconsTypeParameter { WinBar, fg = t_13.fg },
    NavicText { WinBar },
    NavicSeparator { WinBar, fg = Comment.fg },
    -- }}}

    -- LSP {{{
    -- These groups are for the native LSP client and diagnostic system. Some
    -- other LSP clients may use these groups, or use their own. Consult your
    -- LSP client's documentation.

    -- See :h lsp-highlight, some groups may not be listed, submit a PR fix to lush-template!
    --
    -- LspReferenceText            { } , -- Used for highlighting "text" references
    -- LspReferenceRead            { } , -- Used for highlighting "read" references
    -- LspReferenceWrite           { } , -- Used for highlighting "write" references
    -- LspCodeLens                 { } , -- Used to color the virtual text of the codelens. See |nvim_buf_set_extmark()|.
    -- LspCodeLensSeparator        { } , -- Used to color the seperator between two or more code lens.
    -- LspSignatureActiveParameter { } , -- Used to highlight the active parameter in the signature help. See |vim.lsp.handlers.signature_help()|.

    -- See :h diagnostic-highlights, some groups may not be listed, submit a PR fix to lush-template!
    --
    DiagnosticError { ErrorMsg }, -- Used as the base highlight group. Other Diagnostic highlights link to this by default (except Underline)
    DiagnosticWarn { WarningMsg }, -- Used as the base highlight group. Other Diagnostic highlights link to this by default (except Underline)
    DiagnosticInfo { Statement }, -- Used as the base highlight group. Other Diagnostic highlights link to this by default (except Underline)
    DiagnosticHint { t_5 }, -- Used as the base highlight group. Other Diagnostic highlights link to this by default (except Underline)
    DiagnosticOk { t_2 }, -- Used as the base highlight group. Other Diagnostic highlights link to this by default (except Underline)
    DiagnosticVirtualTextError { fg = Error.fg, italic = true, bold = true }, -- Used for "Error" diagnostic virtual text.
    DiagnosticVirtualTextWarn { fg = Warning.fg, italic = true, bold = true }, -- Used for "Warn" diagnostic virtual text.
    DiagnosticVirtualTextInfo { DiagnosticInfo, italic = true, bold = true }, -- Used for "Info" diagnostic virtual text.
    DiagnosticVirtualTextHint { DiagnosticHint, italic = true, bold = true }, -- Used for "Hint" diagnostic virtual text.
    DiagnosticVirtualTextOk { DiagnosticOk, italic = true, bold = true }, -- Used for "Ok" diagnostic virtual text.
    DiagnosticUnderlineError { Error }, -- Used to underline "Error" diagnostics.
    DiagnosticUnderlineWarn { Warning }, -- Used to underline "Warn" diagnostics.
    DiagnosticUnderlineInfo { DiagnosticInfo, undercurl = true }, -- Used to underline "Info" diagnostics.
    DiagnosticUnderlineHint { DiagnosticHint, undercurl = true }, -- Used to underline "Hint" diagnostics.
    DiagnosticUnderlineOk { DiagnosticOk, undercurl = true }, -- Used to underline "Ok" diagnostics.
    DiagnosticFloatingError { DiagnosticError }, -- Used to color "Error" diagnostic messages in diagnostics float. See |vim.diagnostic.open_float()|
    DiagnosticFloatingWarn { DiagnosticWarn }, -- Used to color "Warn" diagnostic messages in diagnostics float.
    DiagnosticFloatingInfo { DiagnosticInfo }, -- Used to color "Info" diagnostic messages in diagnostics float.
    DiagnosticFloatingHint { DiagnosticHint }, -- Used to color "Hint" diagnostic messages in diagnostics float.
    DiagnosticFloatingOk { DiagnosticOk }, -- Used to color "Ok" diagnostic messages in diagnostics float.
    DiagnosticSignError { DiagnosticError }, -- Used for "Error" signs in sign column.
    DiagnosticSignWarn { DiagnosticWarn }, -- Used for "Warn" signs in sign column.
    DiagnosticSignInfo { DiagnosticInfo }, -- Used for "Info" signs in sign column.
    DiagnosticSignHint { DiagnosticHint }, -- Used for "Hint" signs in sign column.
    DiagnosticSignOk { DiagnosticOk }, -- Used for "Ok" signs in sign column.
    LspInfoBorder { FloatBorder },
    -- }}}

    -- Tree-Sitter {{{
    --
    -- See :h treesitter-highlight-groups, some groups may not be listed,
    -- submit a PR fix to lush-template!
    --
    -- Tree-Sitter groups are defined with an "@" symbol, which must be
    -- specially handled to be valid lua code, we do this via the special
    -- sym function. The following are all valid ways to call the sym function,
    -- for more details see https://www.lua.org/pil/5.html
    --
    -- sym("@text.literal")
    -- sym('@text.literal')
    -- sym"@text.literal"
    -- sym'@text.literal'
    --
    -- For more information see https://github.com/rktjmp/lush.nvim/issues/109

    sym"@text.literal" { Comment }, -- Comment
    sym"@text.reference" { Identifier }, -- Identifier
    sym"@text.title" { Identifier }, -- Title
    sym"@text.uri" {}, -- Underlined
    sym"@text.underline" {}, -- Underlined
    sym"@text.todo" { Todo }, -- Todo
    sym"@comment" { Comment }, -- Comment
    sym"@punctuation" { Special }, -- Delimiter
    sym"@constant" { Constant }, -- Constant
    sym"@constant.builtin" { Special }, -- Special
    sym"@constant.macro" { Statement }, -- Define
    sym"@define" { sym "@constant.macro" }, -- Define
    sym"@macro" { sym "@constant.macro" }, -- Macro
    sym"@string" { String }, -- String
    sym"@string.escape" { Special }, -- SpecialChar
    sym"@string.special" { Special }, -- SpecialChar
    sym"@character" { String }, -- Character
    sym"@character.special" { Special }, -- SpecialChar
    sym"@number" { Constant }, -- Number
    sym"@boolean" { Constant }, -- Boolean
    sym"@float" { Constant }, -- Float
    sym"@function" { Identifier }, -- Function
    sym"@function.builtin" { Special }, -- Special
    sym"@function.macro" { sym "@constant.macro" }, -- Macro
    sym"@parameter" { Identifier }, -- Identifier
    sym"@method" { Statement }, -- Function
    sym"@field" { Identifier }, -- Identifier
    sym"@property" { Identifier }, -- Identifier
    sym"@constructor" { Special }, -- Special
    sym"@conditional" { Statement }, -- Conditional
    sym"@repeat" { Statement }, -- Repeat
    sym"@label" { Statement }, -- Label
    sym"@operator" { Statement }, -- Operator
    sym"@keyword" { Statement }, -- Keyword
    sym"@exception" { Statement }, -- Exception
    sym"@variable" { Identifier }, -- Identifier
    sym"@type" { Statement }, -- Type
    sym"@type.definition" { Statement }, -- Typedef
    sym"@storageclass" { Statement }, -- StorageClass
    sym"@structure" { Statement }, -- Structure
    sym"@namespace" { Identifier }, -- Identifier
    sym"@include" { Statement }, -- Include
    sym"@preproc"({ Statement }), -- PreProc
    sym"@debug"({ Special }), -- Debug
    sym"@tag"({ Special }), -- Tag
    -- }}}
  }
end)

-- Return our parsed theme for extension or use elsewhere.
return theme

-- vi:nowrap
