" vim:foldmethod=marker

" Exit if vim is not running in a terminal. I detect this by checking if the input
" to vim is coming from a terminal (also referred to as a tty).
if !has('ttyin')
  finish
endif

" Miscellaneous {{{
set confirm
set mouse=a
set display+=lastline
let &clipboard = 'unnamedplus'
set scrolloff=10
set jumpoptions=stack

" persist undo history to disk
set undofile

augroup Miscellaneous
  autocmd!
  autocmd BufEnter *
        \ if &ft ==# 'help' && (&columns * 10) / &lines > 31 | wincmd L | endif
  autocmd FileType sh setlocal keywordprg=man
  autocmd CursorHold * execute printf('silent! 2match WordUnderCursor /\V\<%s\>/', escape(expand('<cword>'), '/\'))
  autocmd WinLeave * 2match none
  " After a quickfix command is run, open the quickfix window , if there are results
  autocmd QuickFixCmdPost [^l]* cwindow
  autocmd QuickFixCmdPost l*    lwindow
  " Put focus back in quickfix window after opening an entry
  autocmd FileType qf nnoremap <buffer> <CR> <CR><C-W>p
  " highlight trailing whitespace
  autocmd ColorScheme * highlight! link ExtraWhitespace Warning | execute 'match ExtraWhitespace /\s\+$/'
  autocmd OptionSet readonly if v:option_new | setlocal colorcolumn= | endif
  autocmd FileType qf,help setlocal colorcolumn=
augroup END

nnoremap <silent> <Leader>w <Cmd>wa<CR>
nnoremap <Leader>x <Cmd>wqa<CR>

" TODO: When tmux is able to differentiate between tab and ctrl+i this mapping should be updated.
" tmux issue: https://github.com/tmux/tmux/issues/2705#issuecomment-841133549
"
" move forward in the jumplist
nnoremap <C-p> <C-i>

" suspend vim and start a new shell
nnoremap <C-z> <Cmd>suspend<CR>
inoremap <C-z> <Cmd>suspend<CR>
xnoremap <C-z> <Cmd>suspend<CR>

" Decide which actions to take when the enter key is pressed.
function! GetEnterKeyActions()
  let autopairs_keys = v:lua.MPairs.autopairs_cr()
  " If only the enter key is returned, that means we aren't inside a pair.
  let isCursorInEmptyPair = v:lua.vim.inspect(autopairs_keys) !=# '"\r"'
  if isCursorInEmptyPair
    return autopairs_keys
  endif

  return "\<CR>"
endfunction
inoremap <expr> <CR> GetEnterKeyActions()

set colorcolumn=120

set shell=sh

nnoremap <BS> <C-^>

augroup DarkFloats
  autocmd!
  autocmd FileType lspinfo,mason.nvim set winhighlight=NormalFloat:DarkFloatNormal
augroup END

set ttimeout ttimeoutlen=50

lua << EOF
-- Delete comment character when joining commented lines
vim.opt.formatoptions:append('j')
vim.opt.formatoptions:append('r')
EOF
" }}}

" Autoreload {{{
" neovim config files
let config_files = ['init.vim']
for profile in g:profiles
  let last_filename_segment = profile->split('/', 0)[-1]
  call add(config_files, last_filename_segment)
endfor

let config_file_pattern = config_files->join(',')
execute printf(
      \ 'autocmd! bufwritepost %s ++nested source $MYVIMRC | execute "colorscheme " . trim(execute("colorscheme"))',
      \ config_file_pattern
      \ )
" }}}

" Option overrides {{{
function! OverrideVimsDefaultFiletypePlugins()
  " Vim's default filetype plugins get run after filetype detection is
  " performed (i.e. ':filetype plugin on'). So in order to override
  " settings from vim's filetype plugins, the FileType autocommands
  " need to be registered after filetype detection.
  " Since this function gets called on the VimEnter event, we're
  " certain that filetype detection has already
  " happened because filetype detection gets triggered when the
  " plugin manager, vim-plug, finishes loading plugins.
  augroup OverrideFiletypePlugins
    autocmd!
    " Use vim help pages for keywordprg in vim files
    autocmd FileType vim setlocal keywordprg=:tab\ help
    autocmd FileType * setlocal textwidth=0
    autocmd FileType * setlocal wrapmargin=0
    autocmd FileType * setlocal formatoptions-=t formatoptions-=l
  augroup END
endfunction

augroup Overrides
  autocmd!
  autocmd VimEnter * call OverrideVimsDefaultFiletypePlugins()
augroup END
" }}}

" Utilities {{{
" Sets options to the specified new values and returns their old values.
" Useful for when you want to change an option and then restore its old value later on.
function! SetOptions(new_option_values)
  let old_option_values = {}

  for item in items(a:new_option_values)
    let option_name = item[0]
    let new_option_value = item[1]

    " store old value
    execute 'let old_option_value = ' . option_name
    let old_option_values[option_name] = old_option_value

    " set new value
    if type(new_option_value) == type("")
      " quote string values
      execute printf('let %s = "%s"', option_name, new_option_value)
    else
      execute printf('let %s = %s', option_name, new_option_value)
    endif
  endfor

  return old_option_values
endfunction

lua << EOF
_G.unicode = function(hex)
  return vim.fn.execute(
    string.format(
      [[echon "\u%s"]],
      hex
    )
  )
end
EOF
" }}}

lua << EOF
-- Windows {{{
-- open new horizontal and vertical panes to the right and bottom respectively
vim.o.splitright = true
vim.o.splitbelow = true
vim.keymap.set('n', '<Leader><Bar>', '<Cmd>vsplit<CR>')
vim.keymap.set('n', '<Leader>-', '<Cmd>split<CR>')

-- close a window, quit if last window
-- also when closing a tab, go to the previously opened tab
local function close()
  if vim.fn.winnr('$') > 1 then
    vim.cmd.close()
    return
  end

  local last_tab = vim.fn.tabpagenr('#')
  vim.cmd.execute([['q']])
  vim.cmd(string.format(
    [[
      silent! tabnext %s
    ]],
    last_tab
  ))
end
vim.keymap.set(
  'n',
  '<Leader>q',
  close,
  {
    silent = true,
  }
)

-- TODO: When tmux is able to differentiate between enter and ctrl+m this mapping should be updated.
-- tmux issue: https://github.com/tmux/tmux/issues/2705#issuecomment-841133549
--
-- maximize a window by opening it in a new tab
local function maximize()
  if vim.fn.winnr('$') == 1 then
    return
  end

  vim.cmd([[
    tab split
  ]])
end
vim.keymap.set('n', '<Leader>m', maximize)

local group_id = vim.api.nvim_create_augroup('Window', {})
-- Automatically resize all splits to make them equal when the vim window is resized or a new window is created/closed.
vim.api.nvim_create_autocmd(
  {'VimResized', 'WinNew', 'WinClosed', 'TabEnter',},
  {
    callback = function()
      vim.cmd.wincmd('=')
    end,
    group = group_id,
  }
)

local function per_window(callable)
  return function()
    -- I can't call a local function with 'windo' so I'll assign the function to a global variable.
    _G.per_window_function = callable

    local current_window_number = vim.fn.winnr()
    vim.cmd([[
      windo lua per_window_function()
    ]])
    vim.cmd(string.format(
      [[
        silent! %swincmd w
      ]],
      current_window_number
    ))
  end
end
local function set_tabline_margin()
  if vim.w.disable_tabline_margin then
    return
  end

  local window_id = vim.fn.win_getid()
  local is_tabline_visible = vim.o.showtabline == 2 or (vim.o.showtabline == 1 and vim.fn.tabpagenr('$') > 1)
  local is_window_bordering_tabline = vim.fn.screenpos(window_id, 1, 1).row <= 2
  if is_tabline_visible and is_window_bordering_tabline then
    vim.wo.winbar = '%#VertSplit#'
    vim.opt_local.fillchars:append(
      vim.tbl_extend(
        'force',
        vim.opt.fillchars:get(),
        vim.opt_local.fillchars:get(),
        {wbr = ' '}
      )
    )
  else
    vim.wo.winbar = ''

  end
end
local set_tabline_margin_per_window = per_window(set_tabline_margin)
vim.api.nvim_create_autocmd(
  {'WinEnter', 'TabNewEntered', 'VimEnter',},
  {
    callback = set_tabline_margin_per_window,
    group = group_id,
  }
)
-- }}}

-- Tab pages {{{
vim.keymap.set('n', '<Leader>t', function() vim.cmd('$tabnew') end, {silent = true})
vim.keymap.set('n', '<C-h>', vim.cmd.tabprevious, {silent = true})
vim.keymap.set('n', '<C-l>', vim.cmd.tabnext, {silent = true})

-- Switch tabs with <Leader><tab number>
for window_index=1,9 do
  vim.keymap.set('n', '<Leader>' .. window_index, function() vim.cmd('silent! tabnext ' .. tostring(window_index)) end)
end
-- }}}

-- Indentation {{{
vim.o.expandtab = true
vim.o.autoindent = true
vim.o.smartindent = true
vim.o.smarttab = true
-- Round indent to multiple of shiftwidth (applies to < and >)
vim.o.shiftround = true
local tab_width = 2
vim.o.tabstop = tab_width
vim.o.shiftwidth = tab_width
vim.o.softtabstop = tab_width
-- }}}
EOF

" Folds {{{
set fillchars+=foldsep:\ ,foldclose:›,foldopen:⌄,fold:\ 
" Setting this so that the fold column gets displayed
set foldenable
set foldlevelstart=99
" Set max number of nested folds when 'foldmethod' is 'syntax' or 'indent'
set foldnestmax=1
" Minimum number of lines a fold must have to be able to be closed
set foldminlines=1
" Fold visually selected lines. 'foldmethod' must be set to 'manual' for this work.
vnoremap <Tab> zf
" Toggle opening and closing all folds
nnoremap <silent> <expr> <S-Tab> &foldlevel ? 'zM' : 'zR'
" auto-resize the fold column
set foldcolumn=auto:9
" Jump to the top and bottom of the current fold, without adding to the jump list
nnoremap [<Tab> [z
nnoremap ]<Tab> ]z
xnoremap [<Tab> [z
xnoremap ]<Tab> ]z
nnoremap <silent> <Tab> za
augroup Fold
  autocmd!
  autocmd FileType * setlocal foldmethod=indent
augroup END

set foldtext=FoldText()
function! FoldText()
  let window_width = winwidth(0)
  let gutter_width = getwininfo(win_getid())[0].textoff
  let line_width = window_width - gutter_width

  let fold_line_count = (v:foldend - v:foldstart) + 1
  let fold_description = printf('(%s)', fold_line_count)
  let fold_description_length = strdisplaywidth(fold_description)

  let separator_text = '⋯ '
  let separator_text_length = 2

  let line_text = getline(v:foldstart)
  " truncate if there isn't space for the fold description and separator text
  let max_line_text_length = line_width - (fold_description_length + separator_text_length)
  if strdisplaywidth(line_text) > max_line_text_length
    let line_text = line_text[: max_line_text_length - 1]
  endif
  let line_text_length = strdisplaywidth(line_text)

  return line_text . separator_text . fold_description
endfunction
" }}}

lua << EOF
-- Autocomplete {{{
vim.o.complete = '.,w,b,u'
-- - show the completion menu even if there is only one suggestion
-- - when autocomplete gets triggered, no suggestion is selected
vim.o.completeopt = 'menu,menuone,noselect'
vim.o.pumheight = vim.o.scrolloff > 5 and vim.o.scrolloff - 2 or 5
-- }}}

-- Command line {{{
-- on first wildchar press (<Tab>), show all matches and complete the longest common substring among them.
-- on subsequent wildchar presses, cycle through matches
vim.o.wildmode = 'longest:full,full'
vim.o.wildoptions = 'pum'
vim.o.cmdheight = 1
vim.cmd([[
  cnoreabbrev <expr> h getcmdtype() == ":" && getcmdline() == 'h' ? 'tab help' : 'h'
]])
-- }}}

-- Search {{{
vim.o.hlsearch = false
-- show match position in command window, don't show 'Search hit BOTTOM/TOP'
vim.opt.shortmess:remove('S')
vim.opt.shortmess:append('s')
-- toggle search highlighting
vim.keymap.set('n', [[\]], '<Cmd>set hlsearch!<CR>', {silent = true})
-- }}}

-- Sessions {{{
vim.opt.sessionoptions:remove('blank')
vim.opt.sessionoptions:remove('options')
vim.opt.sessionoptions:append('tabpages')
vim.opt.sessionoptions:append('folds')
local session_dir = vim.g.data_path .. '/sessions'
vim.fn.mkdir(session_dir, 'p')

local function restore_or_create_session()
  -- We only want to restore/create a session if neovim was called with no arguments. The first element in vim.v.argv
  -- will always be the path to the vim executable so if no arguments were passed to neovim, the size of vim.v.argv
  -- will be one.
  local is_neovim_called_with_no_arguments = #vim.v.argv == 1
  if is_neovim_called_with_no_arguments then
    local session_name = string.gsub(os.getenv('PWD'), '/', '%%') .. '%vim'
    local session_full_path = session_dir .. '/' .. session_name
    local session_full_path_escaped = vim.fn.fnameescape(session_full_path)
    if vim.fn.filereadable(session_full_path) ~= 0 then
      vim.cmd.source(session_full_path_escaped)
    else
      vim.cmd({
        cmd = 'mksession',
        args = {session_full_path_escaped},
        bang = true,
      })
    end
    vim.g.session_active = true
  end
end

local function save_session()
  if vim.g.session_active and string.len(vim.v.this_session) > 0 then
    vim.cmd({
      cmd = 'mksession',
      args = {vim.fn.fnameescape(vim.v.this_session)},
      bang = true,
    })
  end
end

local group_id = vim.api.nvim_create_augroup('SaveAndRestoreSettings', {})
-- Restore session after vim starts.
vim.api.nvim_create_autocmd(
  {'VimEnter',},
  {
    callback = restore_or_create_session,
    group = group_id,
    -- The 'nested' option tells vim to fire events normally while this autocommand is executing. By default, no events
    -- are fired during the execution of an autocommand to prevent infinite loops.
    nested = true,
  }
)
-- save session before vim exits
vim.api.nvim_create_autocmd(
  {'VimLeavePre',},
  {
    callback = save_session,
    group = group_id,
  }
)
-- }}}

-- Aesthetics {{{

-- Miscellaneous {{{
vim.o.linebreak = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.cursorline = true
vim.o.cursorlineopt = 'number,screenline'
vim.o.showtabline = 1
vim.o.wrap = true
-- chars to represent tabs and spaces when 'setlist' is enabled
vim.o.listchars = 'tab:¬-,space:·'
vim.o.signcolumn = 'yes:2'
vim.opt.fillchars:append('eob: ')
-- }}}

-- Statusline {{{
_G.GetDiagnosticCountForSeverity = function(severity)
  return #vim.diagnostic.get(0, {severity = severity})
end
_G.StatusLine = function()
  local item_separator = '%#StatusLineSeparator# ∙ '

  local line = '%#StatusLine#Ln %l'
  local column = '%#StatusLine#Col %c'
  local position = line .. ', ' .. column

  local modified_indicator = ''
  if vim.fn.getbufvar(vim.fn.bufnr('%'), '&mod') ~= 0 then
    modified_indicator = '*'
  end
  local file_info = '%#StatusLine#%y %f' .. modified_indicator .. '%w%q'

  local fileformat = nil
  if vim.o.fileformat ~= 'unix' then
    fileformat = string.format('%%#StatusLineStandoutText#[%s]', vim.o.fileformat)
  end

  local readonly = nil
  if vim.o.readonly then
    local indicator = '[RO]'
    if is_nerdfont_enabled then
      indicator = unicode('f840')
    end

    readonly = '%#StatusLineStandoutText#' .. indicator
  end

  local diagnostic_count = {
    warning = GetDiagnosticCountForSeverity('warn'),
    error = GetDiagnosticCountForSeverity('error'),
    info = GetDiagnosticCountForSeverity('info'),
    hint = GetDiagnosticCountForSeverity('hint'),
  }
  local diagnostic_list = {}
  local error_count = diagnostic_count.error
  if error_count > 0 then
    local icon = 'ⓧ '
    if is_nerdfont_enabled then
      icon = unicode('f659') .. ' '
    end
    local error = '%#StatusLineErrorText#' .. icon .. error_count
    table.insert(diagnostic_list, error)
  end
  local warning_count = diagnostic_count.warning
  if warning_count > 0 then
    local icon = 'ⓦ '
    if is_nerdfont_enabled then
      icon = unicode('fad5') .. ' '
    end
    local warning = '%#StatusLineWarningText#' .. icon  .. warning_count
    table.insert(diagnostic_list, warning)
  end
  local info_count = diagnostic_count.info
  if info_count > 0 then
    local icon = 'ⓘ '
    if is_nerdfont_enabled then
      icon = unicode('f7fc') .. ' '
    end
    local info = '%#StatusLineInfoText#' .. icon  .. info_count
    table.insert(diagnostic_list, info)
  end
  local hint_count = diagnostic_count.hint
  if hint_count > 0 then
    local icon = 'ⓗ '
    if is_nerdfont_enabled then
      -- TODO: Find a good nerdfont symbol for hints
      icon = unicode('f7fc') .. ' '
    end
    local hint = '%#StatusLineHintText#' .. icon  .. hint_count
    table.insert(diagnostic_list, hint)
  end
  local diagnostics = nil
  if #diagnostic_list > 0 then
    diagnostics = table.concat(diagnostic_list, ' ')
  end

  local left_side_items = {file_info}
  if fileformat then
    table.insert(left_side_items, fileformat)
  end
  if readonly then
    table.insert(left_side_items, readonly)
  end
  local left_side = table.concat(left_side_items, ' ')

  local right_side_items = {position}
  if diagnostics then
    table.insert(right_side_items, diagnostics)
  end
  local right_side = table.concat(right_side_items, item_separator)

  local statusline_separator = '%#StatusLine#%=     '
  local padding = '%#StatusLine# '

  local statusline = padding .. left_side .. statusline_separator .. right_side .. padding

  return statusline
end

vim.o.laststatus = 3
vim.o.statusline = '%!v:lua.StatusLine()'
-- }}}

-- Tabline {{{
_G.superscript_numbers = {
  ["0"] = "⁰",
  ["1"] = "¹",
  ["2"] = "²",
  ["3"] = "³",
  ["4"] = "⁴",
  ["5"] = "⁵",
  ["6"] = "⁶",
  ["7"] = "⁷",
  ["8"] = "⁸",
  ["9"] = "⁹",
}

_G.Tabline = function()
  local tabline = ''

  local current_tab_index = vim.fn.tabpagenr()
  for tab_index=1,vim.fn.tabpagenr('$') do
    local is_current_tab = tab_index == current_tab_index

    local char_highlight = '%#TabLineChar#'
    if is_current_tab then
      char_highlight = '%#TabLineCharSel#'
    end

    local left_char = char_highlight .. ' '
    local right_char = left_char
    if is_current_tab then
      if is_nerdfont_enabled then
        left_char = char_highlight .. unicode('e0ba')
        right_char = char_highlight .. unicode('e0bc')
      else
        left_char = char_highlight .. unicode('2588')
        right_char = char_highlight .. unicode('2588')
      end
    end

    local tab_index_highlight = '%#TabLineIndex#'
    if is_current_tab then
      tab_index_highlight = '%#TabLineIndexSel#'
    end

    local window_number = vim.fn.tabpagewinnr(tab_index)
    local buffer_list = vim.fn.tabpagebuflist(tab_index)
    local buffer_number = buffer_list[window_number]
    local buffer_name = vim.fn.bufname(buffer_number)
    if buffer_name == '' then
      buffer_name = '[No Name]'
    else
      buffer_name = vim.fn.fnamemodify(buffer_name, ':t')
    end
    local buffer_name_highlight = '%#TabLine#'
    if is_current_tab then
      buffer_name_highlight = '%#TabLineSel#'
    end
    local superscipt_tab_index = ''
    for digit in tostring(tab_index):gmatch('.') do
      superscipt_tab_index = superscipt_tab_index .. superscript_numbers[digit]
    end
    buffer_name = buffer_name_highlight .. ' ' .. tab_index_highlight .. superscipt_tab_index .. buffer_name_highlight .. ' ' .. buffer_name .. buffer_name_highlight .. '  '

    local tab_marker = '%' .. tab_index .. 'T'

    local tab = tab_marker .. left_char .. buffer_name .. right_char

    tabline = tabline .. tab
  end

  tabline = '%#TabLineFill# ' .. tabline .. '%#TabLineFill#'

  if string.find(vim.fn.bufname(vim.fn.winbufnr(1)), 'NERD_tree_%d+') then
    local icon = unicode('25A0')
    local nerdtree_title = ' ' .. icon .. ' File Explorer'

    local nerdtree_title_length = string.len(nerdtree_title)
    local remaining_spaces_count = (vim.fn.winwidth(1) - nerdtree_title_length) + 2
    local left_pad_length = math.floor(remaining_spaces_count / 2)
    local right_pad_length = left_pad_length
    if remaining_spaces_count % 2 == 1 then
      right_pad_length = right_pad_length + 1
    end

    tabline = '%#NerdTreeTabLine#' .. string.rep(' ', left_pad_length) .. nerdtree_title .. string.rep(' ', right_pad_length) .. '%#VertSplit#' .. (vim.opt.fillchars:get().vert or '│') .. '%<' .. tabline
  end

  return tabline
end
vim.o.tabline = '%!v:lua.Tabline()'
-- }}}

-- Cursor {{{
local function set_cursor()
  -- Block cursor in normal mode, thin line in insert mode, and underline in replace mode
  vim.o.guicursor = 'n-v:block-blinkon0,i-c-ci-ve:ver25-blinkwait0-blinkon200-blinkoff200,r-cr-o:hor20-blinkwait0-blinkon200-blinkoff200'
end
set_cursor()

local function reset_cursor()
  -- reset terminal cursor to blinking bar
  vim.o.guicursor = 'a:ver25-blinkwait0-blinkon200-blinkoff200'
end

local group_id = vim.api.nvim_create_augroup('Cursor', {})
vim.api.nvim_create_autocmd(
  {'VimLeave', 'VimSuspend',},
  {
    callback = reset_cursor,
    group = group_id,
  }
)
vim.api.nvim_create_autocmd(
  {'VimResume',},
  {
    callback = set_cursor,
    group = group_id,
  }
)
-- }}}

-- }}}

-- LSP {{{
vim.diagnostic.config({
  virtual_text = false,
  signs = {
    -- Make it high enough to have priority over vim-signify
    priority = 11,
  },
  update_in_insert = true,
  -- With this enabled, sign priorities will become: hint=11, info=12, warn=13, error=14
  severity_sort = true,
  float = {
    source = "if_many",
    border = 'rounded',
    focusable = false,
  },
})

local bullet = '•'
local signs = { Error = bullet, Warn = bullet, Hint = bullet, Info = bullet }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl})
end

vim.keymap.set('n', 'ga', vim.lsp.buf.code_action, {desc = 'Choose code action'})
vim.keymap.set('v', 'ga', vim.lsp.buf.range_code_action, {desc = 'Choose code action'})
vim.keymap.set('n', 'gl', vim.diagnostic.open_float, {desc = 'Show diagnostics'})
vim.keymap.set('n', '[l', vim.diagnostic.goto_prev, {desc = "Go to previous diagnostic"})
vim.keymap.set('n', ']l', vim.diagnostic.goto_next, {desc = "Go to next diagnostic"})
vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, {desc = "Go to implementation"})
vim.keymap.set('n', 'gk', vim.lsp.buf.signature_help, {desc = "Show signature help"})
vim.keymap.set('n', 'gr', vim.lsp.buf.references, {desc = "Go to reference"})
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {desc = "Go to definition"})
vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, {desc = "Go to declaration"})
vim.keymap.set('n', 'gci', vim.lsp.buf.incoming_calls, {desc = "Show incoming calls"})
vim.keymap.set('n', 'gco', vim.lsp.buf.outgoing_calls, {desc = "Show outgoing calls"})
-- }}}

-- Plugins {{{

-- Miscellaneous {{{
-- Add icons to the gutter to represent version control changes (e.g. new lines, modified lines, etc.)
Plug(
  'mhinz/vim-signify',
  {
    config = function()
      vim.keymap.set('n', '<Leader>vk', '<Cmd>SignifyHunkDiff<CR>')
    end,
  }
)
vim.g.signify_sign_add = '│'
vim.g.signify_sign_change = '│'
vim.g.signify_sign_show_count = 0

Plug(
  'windwp/nvim-autopairs',
  {
    config = function()
      require("nvim-autopairs").setup({
        -- Before        Input         After
        -- ------------------------------------
        -- {|}           <CR>          {
        --                                 |
        --                             }
        -- ------------------------------------
        -- Disabling this mapping since I will add it through nvim-cmp.
        map_cr = false,
      })
    end
  }
)

-- Seamless movement between vim windows and tmux panes.
Plug(
  'christoomey/vim-tmux-navigator',
  {
    config = function()
      vim.keymap.set('n', '<M-h>', '<Cmd>TmuxNavigateLeft<CR>', {silent = true})
      vim.keymap.set('n', '<M-l>', '<Cmd>TmuxNavigateRight<CR>', {silent = true})
      vim.keymap.set('n', '<M-j>', '<Cmd>TmuxNavigateDown<CR>', {silent = true})
      vim.keymap.set('n', '<M-k>', '<Cmd>TmuxNavigateUp<CR>', {silent = true})
    end
  }
)
vim.g.tmux_navigator_no_mappings = 1

Plug('inkarkat/vim-CursorLineCurrentWindow')

Plug(
  'ethanholz/nvim-lastplace',
  {
    config = function()
      require('nvim-lastplace').setup({})
    end,
  }
)

Plug(
  'dstein64/vim-startuptime',
  {
    config = function()
      vim.cmd([[
        cnoreabbrev <expr> StartupTime getcmdtype() == ":" && getcmdline() == 'StartupTime' ? 'tab StartupTime' : 'StartupTime'
      ]])
    end,
  }
)
vim.g.startuptime_tries = 100

-- Opens the OS color picker and inserts the chosen color into the buffer.
Plug('KabbAmine/vCoolor.vim')
vim.g.vcoolor_disable_mappings = 1

-- To get the vim help pages for vim-plug itself, you need to add it as a plugin
Plug('junegunn/vim-plug')

-- TODO: Using this so that substitutions made by vim-abolish get highlighted as I type them.
-- Won't be necessary if vim-abolish adds support for neovim's `inccommand`.
-- issue for `inccommand` support: https://github.com/tpope/vim-abolish/issues/107
Plug('markonm/traces.vim')
vim.g.traces_abolish_integration = 1

-- Automatically add closing keywords (e.g. function/endfunction in vimscript)
Plug(
  'RRethy/nvim-treesitter-endwise',
  {
    config = function()
      -- this way endwise triggers on 'o'
      vim.keymap.set('n', 'o', 'A<CR>', {remap = true})
    end
  }
)

-- Use the ANSI OSC52 sequence to copy text to the system clipboard
Plug(
  'ojroques/nvim-osc52',
  {
    config = function()
      require('osc52').setup({ silent = true, })

      vim.cmd([[
        augroup Osc52
          autocmd!
          autocmd TextYankPost * if v:event.operator is 'y' && v:event.regname is '+' && (!empty($SSH_CLIENT) || !empty($SSH_TTY)) | lua require('osc52').copy_register('+') | endif
        augroup END
      ]])
    end,
  }
)

Plug(
  'lukas-reineke/virt-column.nvim',
  {
    config = function()
      require("virt-column").setup({ char = "│" })
      vim.cmd([[
        execute 'VirtColumnRefresh!'
        augroup VirtColumn
          autocmd!
          autocmd WinEnter,VimResized * VirtColumnRefresh!
        augroup END
      ]])
    end,
  }
)

-- lua library specfically for use in neovim
Plug('nvim-lua/plenary.nvim')

Plug(
  'iamcco/markdown-preview.nvim',
  {
    ['do'] = function()
      vim.fn['mkdp#util#install']()
    end,
  }
)

Plug(
  'nvim-telescope/telescope.nvim',
  {
    branch = '0.1.x',
    config = function()
      telescope = require('telescope')
      actions = require('telescope.actions')

      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ["<Esc>"] = actions.close,
              ["<Tab>"] = actions.move_selection_next,
              ["<S-Tab>"] = actions.move_selection_previous,
              ["<C-p>"] = actions.cycle_history_prev,
              ["<C-n>"] = actions.cycle_history_next,
            },
          },
          prompt_prefix = is_nerdfont_enabled and unicode('f002') .. '  ' or '> ',
        },
      })

      vim.cmd([[
        augroup TelescopeNvim
          autocmd!
          autocmd FileType TelescopePrompt setlocal nocursorline
        augroup END
      ]])

      vim.keymap.set('n', '<Leader>h', '<Cmd>Telescope command_history<CR>')
      vim.keymap.set('n', '<Leader>b', '<Cmd>Telescope buffers<CR>')
      vim.keymap.set('n', '<Leader>/', '<Cmd>Telescope commands<CR>')
      vim.keymap.set('n', '<Leader>k', '<Cmd>Telescope help_tags<CR>')
      vim.keymap.set('n', '<Leader>g', '<Cmd>Telescope live_grep<CR>')
      vim.keymap.set('n', '<Leader>f', '<Cmd>Telescope find_files<CR>')
      vim.keymap.set('n', '<Leader>j', '<Cmd>Telescope jumplist<CR>')
      vim.cmd([[
        command! HighlightTest Telescope highlights
        command! Autocmd Telescope autocommands
      ]])
    end,
  }
)

Plug(
  'stevearc/dressing.nvim',
  {
    config = function()
      require('dressing').setup({
        select = {
          telescope = {
            layout_config = {
              width = 0.6,
              height = 0.6,
            },
            layout_strategy = 'center',
            sorting_strategy = 'ascending',
          },
        },
      })
    end,
  }
)

-- Use folds provided by a language server
Plug('pierreglaser/folding-nvim')

Plug(
  'folke/which-key.nvim',
  {
    config = function()
      require('which-key').setup({
        popup_mappings = {
          scroll_down = '<c-j>',
          scroll_up = '<c-k>',
        },
        -- hide mapping boilerplate
        hidden = {"<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ ", "<Plug>", "<plug>"}, 
        layout = {
          height = {
            max = vim.o.scrolloff > 5 and vim.o.scrolloff - 2 or 8
          },
        },
        window = {
          border = 'rounded',
        },
      })
    end,
  }
)

Plug('gpanders/editorconfig.nvim')

Plug('tpope/vim-repeat')

Plug(
  'nvim-treesitter/nvim-treesitter',
  {
    config = function()
      require('nvim-treesitter.configs').setup({
        auto_install = false,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        incremental_selection = {
          enable = false,
        },
        indent = {
          enable = false,
        },
        matchup = {
          enable = true,
          disable_virtual_text = true,
          include_match_words = true,
        },
        endwise = {
          enable = true,
        },
        autotag = {
          enable = true,
        },
        context_commentstring = {
          enable = true,
          enable_autocmd = false,
        },
      })

      _G.MaybeSetTreeSitterFoldmethod = function()
        is_foldmethod_overridable = foldmethod ~= 'manual'
          and foldmethod ~= 'marker'
          and foldmethod ~= 'diff'
        if require('nvim-treesitter.parsers').has_parser() and is_foldmethod_overridable then
          vim.o.foldmethod = 'expr'
          vim.o.foldexpr = 'nvim_treesitter#foldexpr()'
        end
      end
      vim.cmd([[
        augroup NvimTreeSitter
          autocmd!
          autocmd FileType * lua MaybeSetTreeSitterFoldmethod()
          autocmd VimEnter * lua InstallMissingParsers()
        augroup END
      ]])

      -- Install missing parsers
      -- TODO: treesitter commands don't seem to be available until 'VimEnter' so I'll call this function then.
      _G.InstallMissingParsers = function()
        local install_info = vim.fn.execute('TSInstallInfo')
        local uninstalled_parsers_count = vim.fn.count(install_info, 'not installed')
        if uninstalled_parsers_count > 0 then
          local install_prompt = string.format(
            '%s Tree-sitter parsers are not installed, would you like to install them now?',
            uninstalled_parsers_count
          )
          if uninstalled_parsers_count > 20 then
            install_prompt = install_prompt .. ' (Warning: It might take a while.)'
          end

          local should_install = vim.fn.confirm(install_prompt, "yes\nno") == 1
          if should_install then
            vim.cmd('TSInstall all')
          else
            vim.cmd([[
              echomsg 'No problem, you can always do it later by running `:TSInstall all`.'
            ]])
          end
        end
      end
    end,
    ['do'] = vim.cmd.TSUpdateSync,
  }
)

Plug(
  'terrortylor/nvim-comment',
  {
    config = function()
      require('nvim_comment').setup({
        hook = function()
          require("ts_context_commentstring.internal").update_commentstring()
        end,
      })
    end,
  }
)

Plug('tpope/vim-sleuth')

Plug(
  'blankname/vim-fish',
  {
    config = function()
      vim.cmd([[
        augroup VimFish
          autocmd!
          autocmd FileType fish setlocal foldmethod=expr
        augroup END
      ]])
    end,
  }
)

Plug('windwp/nvim-ts-autotag')

Plug('JoosepAlviste/nvim-ts-context-commentstring')

-- This plugin does two things:
-- 1. fix 'CursorHold' and 'CursorHoldI' autocmd events
-- bug: https://github.com/neovim/neovim/issues/12587
-- 2. decouple 'updatetime' from 'CursorHold' and 'CursorHoldI'
Plug('antoinemadec/FixCursorHold.nvim')
vim.g.cursorhold_updatetime = 200

Plug(
  'kosayoda/nvim-lightbulb',
  {
    config = function()
      require('nvim-lightbulb').setup({
        autocmd = {enabled = true},
        -- Giving it a higher priority than diagnostics and vcs changes
        sign = {priority = 15},
      })
    end,
  }
)
-- }}}
EOF

" Prose {{{
Plug 'junegunn/goyo.vim'
  let g:goyo_width = '90%'

  function! s:goyo_enter()
    if executable('tmux') && strlen($TMUX)
      silent !tmux set status off
    endif
    let g:goyo_old_option_values = SetOptions({
          \ '&showmode': 0,
          \ '&showcmd': 0,
          \ '&cmdheight': 0,
          \ '&winbar': '',
            \})
    function! GoyoSetHighlights()
      highlight clear WordUnderCursor
      highlight CursorLine cterm=NONE
      highlight clear MatchParen
      highlight FoldColumn ctermbg=NONE ctermfg=15
    endfunction
    call GoyoSetHighlights()
    " In case the colorscheme gets set after I set highlights this will set them again
    autocmd Colorscheme <buffer> call GoyoSetHighlights()
    silent! DelimitMateSwitch
    setlocal scrolloff=0
    setlocal conceallevel=2
    setlocal concealcursor=nvic
    syn match listItem "^\s*[-*]\s\+" contains=listBullet
    syn match listBullet "[-*]" contained conceal cchar=•
    syn match headerUnderline "[-=][-=][-=][-=][-=][-=]*" contains=headerUnderlineDash
    syn match headerUnderlineDash "[-=]" contained conceal cchar=―
    syn match emDash "\s\+--\s\+" contains=emDashSingleDash
    syn match emDashSingleDash "-" contained conceal cchar=―
    nnoremap <buffer> <silent> p p
    vnoremap <buffer> <silent> p p
    setlocal breakindent
    let &breakindentopt = 'shift:' . &tabstop
    function! GetBulletAction()
      let line = getline('.')

      " Insert a newline before the bullet
      if line =~# '^\s*[-*]\s\+$'
        return "\<Esc>\<S-o>\<Esc>j\<S-a>"
      endif

      " Create a bullet on the next line
      if line =~# '^\s*[-*]\s\+.*'
        let bullet_character = line->stridx('-') != -1 ? "-" : "*"
        return "\<CR>" . bullet_character . "\<Space>"
      endif

      return "\<CR>"
    endfunction
    inoremap <buffer> <expr> <CR> GetBulletAction()
    setlocal foldlevel=0
    setlocal foldmethod=marker
    inoremap <buffer> <Tab> <C-t>
    inoremap <buffer> <S-Tab> <C-d>
  endfunction

  function! s:goyo_leave()
    if executable('tmux') && strlen($TMUX)
      silent !tmux set status on
    endif
    call SetOptions(g:goyo_old_option_values)
    silent! DelimitMateSwitch
    silent! SignifyEnableAll
  endfunction

  augroup Goyo
    autocmd!

    autocmd User GoyoEnter ++nested call <SID>goyo_enter()
    autocmd User GoyoLeave ++nested call <SID>goyo_leave()

    " If I'm about to exit vim without turning off goyo, then turn it off now.
    " 'nested' is used so that the 'GoyoLeave' event fires
    autocmd VimLeavePre * ++nested if exists('#goyo') | Goyo | endif

    " On window resize, if goyo is active, resize the window
    autocmd VimResized * if exists('#goyo') | exe "normal \<c-w>=" | endif

    " Auto activate for files ending in '.txt'
    autocmd VimEnter * if @% =~# '.txt$' | execute 'Goyo' | endif
  augroup END
" }}}

" File explorer {{{
Plug 'preservim/nerdtree', {'on': []}
  let g:NERDTreeMouseMode = 2
  let g:NERDTreeShowHidden = 1
  let g:NERDTreeStatusline = -1
  let g:NERDTreeMinimalUI=1
  let g:NERDTreeAutoDeleteBuffer=0
  let g:NERDTreeHijackNetrw=1
  function! NerdTreeToggle()
    " Lazyload NERDTree
    if !exists('s:loaded_nerdtree')
      call plug#load('nerdtree')
      let s:loaded_nerdtree = 1
    endif

    " NERDTree is open so close it.
    if g:NERDTree.IsOpen()
      silent execute 'NERDTreeToggle'
      return
    endif

    " If NERDTree can't find the current file, it prints an error and doesn't open NERDTree.
    " In which case, I'll call 'NERDTree' which opens NERDTree to the current directory.
    silent execute 'NERDTreeFind'
    if !g:NERDTree.IsOpen()
      silent execute 'NERDTree'
    endif
  endfunction
  nnoremap <silent> <M-e> <Cmd>call NerdTreeToggle()<CR>
  function! CloseIfOnlyNerdtreeLeft()
    if !exists('b:NERDTree')
      return
    endif
    if tabpagewinnr(tabpagenr(), '$') != 1
      return
    endif

    if tabpagenr('$') > 1
      tabclose
    else
      execute 'q'
    endif
  endfunction
  augroup NerdTree
    autocmd!
    " open/close directories with 'h' and 'l'
    autocmd FileType nerdtree nmap <buffer> l o
    autocmd FileType nerdtree nmap <buffer> h o
    autocmd FileType nerdtree setlocal winbar=%#Normal#%=\ Press\ %#NerdTreeWinBar#?%#Normal#\ for\ help%=
    autocmd FileType nerdtree setlocal winhighlight=Normal:NerdTreeNormal
    autocmd FileType nerdtree let w:disable_tabline_margin = v:true
    autocmd FileType nerdtree setlocal signcolumn=yes:1
    autocmd BufEnter * call CloseIfOnlyNerdtreeLeft()
  augroup END
" }}}

" Autocomplete {{{
Plug 'hrsh7th/nvim-cmp'
  function! SetupNvimCmp()
    lua << EOF
    local cmp = require("cmp")
    local luasnip = require('luasnip')

    -- sources
    local buffer = {
      name = 'buffer',
      option = {
        keyword_length = 2,
        get_bufnrs = function()
          local buf = vim.api.nvim_get_current_buf()
          local byte_size = vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
          if byte_size > 1024 * 1024 then -- 1 Megabyte max
            return {}
          end

          return { buf }
        end,
      },
    }
    local nvim_lsp = { name = 'nvim_lsp' }
    local omni = { name = 'omni' }
    local path = {
      name = 'path',
      option = {
        get_cwd = function(params)
          return vim.fn.getcwd()
        end,
      },
    }
    local tmux = {
      name = 'tmux',
      option = { all_panes = true },
    }
    local cmdline = { name = 'cmdline' }
    local cmdline_history = { name = 'cmdline_history' }
    local dictionary = {
      name = 'dictionary',
      keyword_length = 2,
    }
    local lsp_signature = { name = 'nvim_lsp_signature_help' }
    local luasnip_source = {
      name = 'luasnip',
      option = {use_show_condition = false},
    }

    -- views
    local wildmenu = {
      entries = {
        name = 'wildmenu',
        separator = '|',
      },
    }

    -- helpers
    local is_cursor_preceded_by_nonblank_character = function()
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match('%s') == nil
    end

    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      window = {
        documentation = {
          winhighlight = 'NormalFloat:CmpNormal,FloatBorder:CmpBorder',
          border = 'rounded',
        },
        completion = {
          winhighlight = 'NormalFloat:CmpNormal,FloatBorder:CmpBorder,CursorLine:CmpCursorLine',
          border = 'rounded',
        },
      },
      mapping = cmp.mapping.preset.insert({
        ['<C-a>'] = cmp.mapping.complete(),
        ['<CR>'] = function(fallback)
          -- TODO: Don't block <CR> if signature help is active
          -- https://github.com/hrsh7th/cmp-nvim-lsp-signature-help/issues/13
          if not cmp.visible()
              or not cmp.get_selected_entry()
              or cmp.get_selected_entry().source.name == 'nvim_lsp_signature_help'
              then
            fallback()
          else
            cmp.confirm({
              -- Replace word if completing in the middle of a word
              behavior = cmp.ConfirmBehavior.Replace,
              -- Don't select first item on CR if nothing was selected
              select = false,
            })
          end
        end,
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif is_cursor_preceded_by_nonblank_character() then
            cmp.complete()
          else
            fallback()
          end
        end, { 'i', 's' }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          else
            fallback()
          end
        end, { 'i', 's' }),
        ['<C-k>'] = cmp.mapping.scroll_docs(-4),
        ['<C-j>'] = cmp.mapping.scroll_docs(4),
        ["<C-h>"] = cmp.mapping(function(fallback)
          if luasnip.jumpable(-1) then
            luasnip.jump(-1)
          end
        end, { 'i', 's' }),
        ["<C-l>"] = cmp.mapping(function(fallback)
          if luasnip.jumpable(1) then
            luasnip.jump(1)
          end
        end, { 'i', 's' }),
      }),
      sources = cmp.config.sources(
        {
          luasnip_source,
          nvim_lsp,
          buffer,
          omni,
          path,
          tmux,
          dictionary,
          lsp_signature,
        }
      )
    })

    cmp.setup.cmdline(
      '/',
      {
        view = wildmenu,
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          buffer,
          cmdline_history,
        }
      }
    )
    cmp.setup.cmdline(
      ':',
      {
        view = wildmenu,
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources(
          {
            path,
            cmdline,
            buffer,
            cmdline_history,
          }
        )
      }
    )
    cmp.setup.cmdline(
      '?',
      {
        view = wildmenu,
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources(
          {
            buffer,
            cmdline_history,
          }
        )
      }
    )
EOF
  endfunction
  autocmd VimEnter * call SetupNvimCmp()

Plug 'hrsh7th/cmp-omni'

Plug 'hrsh7th/cmp-cmdline'

Plug 'dmitmel/cmp-cmdline-history'

Plug 'andersevenrud/cmp-tmux'

Plug 'hrsh7th/cmp-buffer'

Plug 'hrsh7th/cmp-nvim-lsp'

Plug 'hrsh7th/cmp-path'

Plug 'uga-rosa/cmp-dictionary'
  function! SetupCmpDictionary()
    lua << EOF
    require("cmp_dictionary").setup({
      dic = {
        ['*'] = { '/usr/share/dict/words' },
      },
    })
EOF

    call timer_start(0, { -> execute('CmpDictionaryUpdate')})
  endfunction
  autocmd VimEnter * call SetupCmpDictionary()

Plug 'hrsh7th/cmp-nvim-lsp-signature-help'

Plug 'L3MON4D3/LuaSnip'
  function! SetupLuaSnip()
    lua << EOF
    require('luasnip').config.set_config({
      history = true,
      delete_check_events = "TextChanged",
    })
    vim.cmd([[
      call timer_start(0, { -> v:lua.require('luasnip.loaders.from_vscode').load()})
    ]])
EOF
  endfunction
  autocmd VimEnter * call SetupLuaSnip()

Plug 'saadparwaiz1/cmp_luasnip'

Plug 'rafamadriz/friendly-snippets'
" }}}

" Tool Manager {{{
Plug 'williamboman/mason.nvim'
  function! SetupMason()
    lua << EOF
    require("mason").setup({
      ui = {
        icons = {
          package_installed = is_nerdfont_enabled and unicode('f632') .. '  ' or '●',
          package_pending = is_nerdfont_enabled and unicode('f251') .. '  ' or '⧖',
          package_uninstalled = is_nerdfont_enabled and unicode('f62f') .. '  ' or '○'
        },
        keymaps = {
          toggle_package_expand = "<Tab>",
        },
      },
      log_level = vim.log.levels.DEBUG,
    })

    vim.cmd([[
      augroup MasonNvim
        autocmd!
        autocmd FileType mason.nvim highlight clear WordUnderCursor
      augroup END
    ]])
EOF
  endfunction
  autocmd VimEnter * call SetupMason()

Plug 'williamboman/mason-lspconfig.nvim'
  function! SetupMasonLspConfig()
    lua << EOF
    require("mason-lspconfig").setup()

    local lspconfig = require('lspconfig')

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)
    capabilities.textDocument.foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    }

    local on_attach = function(client, buffer_number)
      capabilities = client.server_capabilities
      buffer_keymap = vim.api.nvim_buf_set_keymap
      keymap_opts = { noremap = true, silent = true }

      foldmethod = vim.o.foldmethod
      isFoldmethodOverridable = foldmethod ~= 'manual'
        and foldmethod ~= 'marker'
        and foldmethod ~= 'diff'
        and foldmethod ~= 'expr'
      if capabilities.foldingRangeProvider and isFoldmethodOverridable then
        require('folding').on_attach()
      end

      filetype = vim.o.filetype
      isKeywordprgOverridable = filetype ~= 'vim' and filetype ~= 'sh'
      if capabilities.hoverProvider and isKeywordprgOverridable then
        buffer_keymap(buffer_number, "n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", keymap_opts)

        -- Change border of documentation hover window, See https://github.com/neovim/neovim/pull/13998.
        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
          vim.lsp.handlers.hover,
          {
            border = "rounded",
            focusable = false,
          }
        )
      end
    end

    local default_server_config = {
      capabilities = capabilities,
      on_attach = on_attach,
    }

    require("mason-lspconfig").setup_handlers({
      -- Default handler to be called for each installed server that doesn't have a dedicated handler.
      function (server_name)
        lspconfig[server_name].setup(default_server_config)
      end,

      ["jsonls"] = function()
        lspconfig.jsonls.setup(
          vim.tbl_deep_extend(
            'force',
            default_server_config,
            {
              settings = {
                json = {
                  schemas = require('schemastore').json.schemas(),
                  validate = { enable = true },
                },
              },
            }
          )
        )
      end,
 
      ["sumneko_lua"] = function()
        lspconfig.sumneko_lua.setup(
          vim.tbl_deep_extend(
            'force',
            default_server_config,
            {
              settings = {
                Lua = {
                  runtime = {
                    -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                    version = 'LuaJIT',
                  },
                  diagnostics = {
                    -- Get the language server to recognize the `vim` global
                    globals = {'vim'},
                  },
                  workspace = {
                    -- Make the server aware of Neovim runtime files
                    library = vim.api.nvim_get_runtime_file("", true),
                  },
                  telemetry = {
                    -- Do not send telemetry data containing a randomized but unique identifier
                    enable = false,
                  },
                },
              },
            }
          )
        )
      end,
    })
EOF
  endfunction
  autocmd VimEnter * call SetupMasonLspConfig()

Plug 'neovim/nvim-lspconfig'
  function! SetupNvimLspconfig()
    LspStart
    autocmd WinEnter * LspStart
  endfunction
  autocmd VimEnter * call SetupNvimLspconfig()

Plug 'b0o/schemastore.nvim'
" }}}

" CLI -> LSP {{{
" A language server that acts as a bridge between neovim's language server client and commandline tools that don't
" support the language server protocol. It does this by transforming the output of a commandline tool into the
" format specified by the language server protocol.
Plug 'jose-elias-alvarez/null-ls.nvim'
  function! SetupNullLs()
    lua << EOF
    local null_ls = require('null-ls')
    local builtins = null_ls.builtins
    null_ls.setup({
      sources = {
        builtins.diagnostics.shellcheck.with({
          filetypes = { 'sh', 'bash' }
        }),
        builtins.diagnostics.fish,
        builtins.diagnostics.markdownlint,
      }
    })
EOF
  endfunction
  autocmd VimEnter * call SetupNullLs()
" }}}

" Colorscheme {{{
Plug 'arcticicestudio/nord-vim'
  let g:nord_bold = 1
  let g:nord_italic = 1
  let g:nord_italic_comments = 1
  let g:nord_underline = 1
  function! SetNordOverrides()
    highlight MatchParen ctermfg=blue cterm=underline ctermbg=NONE
    " Transparent vertical split
    highlight VertSplit ctermbg=NONE ctermfg=8
    " statusline colors
    highlight StatusLine ctermbg=8 ctermfg=NONE
    highlight StatusLineSeparator ctermfg=8 ctermbg=NONE cterm=reverse,bold
    highlight StatusLineErrorText ctermfg=1 ctermbg=8
    highlight StatusLineWarningText ctermfg=3 ctermbg=8
    highlight StatusLineInfoText ctermfg=4 ctermbg=8
    highlight StatusLineHintText ctermfg=5 ctermbg=8
    highlight StatusLineStandoutText ctermfg=3 ctermbg=8
    " autocomplete popupmenu
    highlight PmenuSel ctermfg=14 ctermbg=NONE cterm=reverse
    highlight Pmenu ctermfg=NONE ctermbg=24
    highlight PmenuThumb ctermfg=NONE ctermbg=15
    highlight PmenuSbar ctermbg=8
    highlight CursorLine ctermfg=NONE ctermbg=NONE cterm=underline
    " transparent background
    highlight Normal ctermbg=NONE
    highlight EndOfBuffer ctermbg=NONE
    " relative line numbers
    highlight LineNr ctermfg=15
    highlight LineNrAbove ctermfg=15
    highlight! link LineNrBelow LineNrAbove
    highlight WordUnderCursor ctermbg=8
    highlight! link IncSearch Search
    highlight TabLine ctermbg=NONE ctermfg=15
    highlight TabLineSel ctermbg=8 ctermfg=NONE
    highlight TabLineFill ctermbg=NONE
    highlight TabLineCharSel ctermbg=NONE ctermfg=8
    highlight! link TabLineChar TabLineCharSel
    highlight TabLineIndexSel ctermbg=8 ctermfg=14
    highlight! link TabLineIndex TabLine
    highlight TabLineMaximizedIndicator ctermbg=8 ctermfg=3
    highlight Comment ctermfg=15 ctermbg=NONE
    " This variable contains a list of 16 colors that should be used as the color palette for terminals opened in vim.
    " By unsetting this, I ensure that terminals opened in vim will use the colors from the color palette of the
    " terminal in which vim is running
    if exists('g:terminal_ansi_colors') | unlet g:terminal_ansi_colors | endif
    " Have vim only use the colors from the 16 color palette of the terminal in which it runs
    set t_Co=256
    highlight Visual ctermbg=8
    " Search hit
    highlight Search ctermfg=DarkYellow ctermbg=NONE cterm=reverse
    " Parentheses
    highlight Delimiter ctermfg=NONE ctermbg=NONE
    highlight ErrorMsg ctermfg=1 ctermbg=NONE
    highlight WarningMsg ctermfg=3 ctermbg=NONE
    highlight Error ctermfg=1 ctermbg=NONE cterm=undercurl
    highlight Warning ctermfg=3 ctermbg=NONE cterm=undercurl
    highlight! link SpellBad Error
    highlight! link NvimInternalError ErrorMsg
    highlight Folded ctermfg=15 ctermbg=NONE cterm=NONE
    highlight FoldColumn ctermfg=15 ctermbg=NONE
    highlight SpecialKey ctermfg=13 ctermbg=NONE
    highlight NonText ctermfg=15 ctermbg=NONE
    highlight NerdTreeWinBar ctermfg=13 ctermbg=NONE
    highlight NerdTreeTabLine ctermfg=13 ctermbg=NONE
    highlight NerdTreeNormal ctermbg=NONE
    highlight! link VirtColumn VertSplit
    highlight DiagnosticSignError ctermfg=1 ctermbg=NONE
    highlight DiagnosticSignWarn ctermfg=3 ctermbg=NONE
    highlight DiagnosticSignInfo ctermfg=4 ctermbg=NONE
    highlight DiagnosticSignHint ctermfg=5 ctermbg=NONE
    highlight! link DiagnosticUnderlineError Error
    highlight! link DiagnosticUnderlineWarn Warning
    highlight DiagnosticUnderlineInfo ctermfg=4 ctermbg=NONE cterm=undercurl
    highlight DiagnosticUnderlineHint ctermfg=5 ctermbg=NONE cterm=undercurl
    highlight! CmpItemAbbrMatch ctermbg=NONE ctermfg=14
    highlight! link CmpItemAbbrMatchFuzzy CmpItemAbbrMatch
    highlight! CmpItemKind ctermbg=NONE ctermfg=15
    highlight! link CmpItemMenu CmpItemKind
    highlight CmpNormal ctermbg=NONE ctermfg=NONE
    highlight CmpBorder ctermbg=NONE ctermfg=15
    highlight! link CmpDocumentationNormal CmpNormal
    highlight! link CmpDocumentationBorder CmpBorder
    highlight CmpCursorLine ctermfg=14 ctermbg=NONE cterm=reverse
    highlight! TelescopeBorder ctermbg=16 ctermfg=16
    highlight! TelescopePromptTitle ctermbg=24 ctermfg=5 cterm=reverse,bold,nocombine
    highlight! TelescopeMatching ctermbg=NONE ctermfg=6
    highlight! TelescopeSelectionCaret ctermbg=8 ctermfg=8
    highlight! TelescopeNormal ctermbg=16
    highlight! TelescopePromptNormal ctermbg=24
    highlight! TelescopePromptBorder ctermbg=24 ctermfg=24
    highlight! TelescopePromptPrefix ctermbg=24 ctermfg=5
    highlight MasonHeader ctermbg=NONE ctermfg=4 cterm=reverse,bold
    highlight MasonHighlight ctermbg=NONE ctermfg=6
    highlight MasonHighlightBlockBold ctermbg=NONE ctermfg=6 cterm=reverse,bold
    highlight MasonMuted ctermbg=NONE ctermfg=NONE
    highlight MasonMutedBlock ctermbg=NONE ctermfg=15 cterm=reverse
    highlight MasonError ctermbg=NONE ctermfg=1
    highlight NormalFloat ctermbg=32
    highlight LuaSnipNode ctermfg=11
    highlight NormalFloat ctermbg=NONE ctermfg=NONE
    highlight FloatBorder ctermbg=NONE ctermfg=15
    highlight WhichKeyFloat ctermbg=0
    highlight DarkFloatNormal ctermbg=32 ctermfg=NONE
  endfunction
  augroup NordVim
    autocmd!
    autocmd ColorScheme nord call SetNordOverrides()
    " The highlight I use for the word under the cursor and text selected in visual mode is the same.
    " This will disable the highlighting for the word under the cursor while I'm in visual mode.
    function! DisableWordUnderCursorHighlight()
      if mode(1) =~# '\v^(v|)'
        highlight WordUnderCursor ctermbg=NONE
        " When I leave visual mode, enable WordUnderCursor highlighting
        autocmd ModeChanged * ++once if mode(1) !~# '\v^(v|)' | highlight WordUnderCursor ctermbg=8 | endif
      endif
    endfunction
    autocmd ModeChanged * call DisableWordUnderCursorHighlight()
    " use nested so my colorscheme changes are loaded
    autocmd User PlugEndPost ++nested lua pcall(function() vim.cmd.colorscheme('nord') end)
  augroup END
" }}}

" Plugin Management {{{
" Helpers
let g:snapshot_file = g:data_path . '/vim-plug-snapshot.vim'
function! CreateSnapshotSync()
  execute printf('PlugSnapshot! %s', g:snapshot_file)

  " Edit the snapshot file so that it updates plugins synchronously
  execute "silent! !sed --in-place --follow-symlinks 's/PlugUpdate\\!/PlugUpdate\\! --sync/g' " . g:snapshot_file
endfunction
command! PlugSnapshot call CreateSnapshotSync()
function! UpdateAndSnapshotSync()
  PlugUpdate --sync
  call CreateSnapshotSync()
endfunction
command! PlugUpdate call UpdateAndSnapshotSync()
function! PlugRestore()
  if !filereadable(g:snapshot_file)
    echoerr printf("Restore failed. Unable to read the snapshot file '%s'", g:snapshot_file)
    return
  endif
  execute printf('source %s', g:snapshot_file)
endfunction
command! PlugRestore call PlugRestore()

" Install any plugins that have been registered, but aren't installed
function! InstallMissingPlugins()
  let plugs = get(g:, 'plugs', {})
  let missing_plugins = filter(deepcopy(plugs), {plugin_name, plugin_info -> !isdirectory(plugin_info.dir)})
  if empty(missing_plugins)
    return
  endif

  let install_prompt = "The following plugins are not installed:\n" . join(keys(missing_plugins), ", ") . "\nWould you like to install them?"
  let should_install = confirm(install_prompt, "yes\nno") == 1
  if should_install
    if filereadable(g:snapshot_file)
      " Sourcing the snapshot will set plugins to the commit specified in the snapshot
      " and install any missing ones.
      execute printf('source %s', g:snapshot_file)

      " Any plugins that don't have a commit specified must not be in the snapshot.
      " In which case, we'll make a new snapshot.
      let plugins_without_commit = filter(deepcopy(plugs), {plugin_name, plugin_info -> !has_key(plugin_info, 'commit')})
      if !empty(plugins_without_commit)
        call CreateSnapshotSync()
      endif
    else
      PlugInstall --sync
    endif
  endif
endfunction

augroup PostPluginLoadOperations
  autocmd!
  autocmd User PlugEndPost call InstallMissingPlugins()
augroup END
" }}}

" }}}
