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
set scrolloff=999
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

set ttimeout ttimeoutlen=50

lua << EOF
-- Delete comment character when joining commented lines
vim.opt.formatoptions:append('j')
vim.opt.formatoptions:append('r')
EOF
" }}}

" Autoreload {{{
" neovim config files
let config_files = [$MYVIMRC->split('/', 0)[-1]]
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

lua << EOF
-- Utilities {{{
_G.unicode = function(hex)
  return vim.fn.execute(
    string.format(
      [[echon "\u%s"]],
      hex
    )
  )
end

_G.tabdo = function(_function)
  -- I can't call a local function with 'tabdo' so I'll assign the function to a global variable.
  _G.tabdo_function = _function

  local current_tab_number = vim.fn.tabpagenr()
  local previous_tab_number = vim.fn.tabpagenr('#')
  vim.cmd([[
    tabdo lua tabdo_function()
  ]])
  vim.cmd(string.format(
    [[
      silent! tabnext %s
      silent! tabnext %s
    ]],
    previous_tab_number,
    current_tab_number
  ))
end
-- }}}

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
" 
" TODO: When this issue is resolved, I can set foldcolumn to 1 and remove the digits that signify a nested fold.
" issue: https://github.com/neovim/neovim/pull/17446
set foldcolumn=auto:9
" Jump to the top and bottom of the current fold, without adding to the jump list
nnoremap [<Tab> [z
nnoremap ]<Tab> ]z
xnoremap [<Tab> [z
xnoremap ]<Tab> ]z
nnoremap <silent> <Tab> za
augroup Fold
  autocmd!
  " autocmd FileType * setlocal foldmethod=indent
augroup END
lua << EOF
EOF

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
vim.o.pumheight = 6
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
_G.session_dir = vim.g.data_path .. '/sessions'

local function save_session()
  local has_active_session = string.len(vim.v.this_session) > 0
  if has_active_session then
    vim.cmd({
      cmd = 'mksession',
      args = {vim.fn.fnameescape(vim.v.this_session)},
      bang = true,
    })
  end
end

local function restore_or_create_session()
  -- We only want to restore/create a session if neovim was called with no arguments. The first element in vim.v.argv
  -- will always be the path to the vim executable so if no arguments were passed to neovim, the size of vim.v.argv
  -- will be one.
  local is_neovim_called_with_no_arguments = #vim.v.argv == 1
  if is_neovim_called_with_no_arguments then
    local session_name = string.gsub(os.getenv('PWD'), '/', '%%') .. '%vim'
    vim.fn.mkdir(session_dir, 'p')
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

    local group_id = vim.api.nvim_create_augroup('SaveSession', {})

    -- Save the session whenever the window layout or active window changes
    vim.api.nvim_create_autocmd(
      {'BufEnter',},
      {
        callback = save_session,
        group = group_id,
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
  end
end

-- Restore/create session after vim starts.
local group_id = vim.api.nvim_create_augroup('RestoreOrCreateSession', {})
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

local function delete_current_session()
  local session = vim.v.this_session

  local has_active_session = string.len(session) > 0
  if not has_active_session then
    vim.cmd.echoerr([['ERROR: No session is currently active.']])
    return
  end

  -- Stop saving the current session
  vim.api.nvim_del_augroup_by_name('SaveSession')

  local exit_code = vim.fn.delete(session)
  if exit_code == -1 then
    vim.cmd.echoerr(string.format(
      [["Failed to delete current session '%s'."]],
      session
    ))
  end
end
local function delete_all_sessions()
  -- Stop saving the current session, if there is one.
  local has_active_session = string.len(vim.v.this_session) > 0
  if has_active_session then
    vim.api.nvim_del_augroup_by_name('SaveSession')
  end

  if not vim.fn.isdirectory(session_dir) then
    vim.cmd.echoerr(string.format(
      [["Unable to delete all sessions, '%s' is not a directory."]],
      session_dir
    ))
    return
  end

  local sessions = vim.fn.split(vim.fn.globpath(session_dir, '*'), '\n')
  for _, session in ipairs(sessions) do
    local exit_code = vim.fn.delete(session)
    if exit_code == -1 then
      vim.cmd.echoerr(string.format(
        [["Failed to delete session '%s'. Aborting the rest of the operation..."]],
        session
      ))
      return
    end
  end
end
vim.api.nvim_create_user_command('DeleteCurrentSession', delete_current_session, {desc = 'Delete the current session'})
vim.api.nvim_create_user_command('DeleteAllSessions', delete_all_sessions, {desc = 'Delete all sessions'})
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

  local filetype = nil
  if string.len(vim.o.filetype) > 0 then
    filetype = '%#StatusLine#' .. vim.o.filetype
  end

  local modified_indicator = ''
  if vim.fn.getbufvar(vim.fn.bufnr('%'), '&mod') ~= 0 then
    modified_indicator = '*'
  end
  local file_info = '%#StatusLine#%f' .. modified_indicator .. '%w%q'

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

  local left_side_items = {}
  if filetype then
    table.insert(left_side_items, filetype)
  end
  table.insert(left_side_items, file_info)
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
  "¹",
  "²",
  "³",
  "⁴",
  "⁵",
  "⁶",
  "⁷",
  "⁸",
  "⁹",
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
    local superscipt_tab_index = '⁺'
    if tab_index <= 9 then
      superscipt_tab_index = superscript_numbers[tab_index]
    end
    buffer_name = buffer_name_highlight .. ' ' .. tab_index_highlight .. superscipt_tab_index .. buffer_name_highlight .. ' ' .. buffer_name .. buffer_name_highlight .. '  '

    local tab_marker = '%' .. tab_index .. 'T'

    local tab = tab_marker .. left_char .. buffer_name .. right_char

    tabline = tabline .. tab
  end

  tabline = '%#TabLineFill# ' .. tabline .. '%#TabLineFill#'

  local is_explorer_open = vim.fn.getwinvar(1, 'is_explorer', false)
  if is_explorer_open then
    local icon = unicode('25A0')
    local title = ' ' .. icon .. ' File Explorer'
  
    local title_length = string.len(title)
    local remaining_spaces_count = (vim.fn.winwidth(1) - title_length) + 2
    local left_pad_length = math.floor(remaining_spaces_count / 2)
    local right_pad_length = left_pad_length
    if remaining_spaces_count % 2 == 1 then
      right_pad_length = right_pad_length + 1
    end
  
    tabline = '%#ExplorerTabLine#' .. string.rep(' ', left_pad_length) .. title .. string.rep(' ', right_pad_length) .. '%#VertSplit#' .. (vim.opt.fillchars:get().vert or '│') .. '%<' .. tabline
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
  -- Reset terminal cursor to blinking bar.
  -- TODO: This won't be necessary once neovim starts doing this automatically.
  -- Issue: https://github.com/neovim/neovim/issues/4396
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
    focusable = false,
    format = function(diagnostic)
      local result = diagnostic.message

      local code = diagnostic.code
      if code ~= nil then
        result = result .. string.format(' [%s]', code)
      end

      return result
    end,
  },
})

local bullet = '•'
local signs = { Error = bullet, Warn = bullet, Hint = bullet, Info = bullet }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl})
end

vim.keymap.set({'n', 'v'}, 'ga', vim.lsp.buf.code_action, {desc = 'Choose code action'})
vim.keymap.set('n', 'gl', vim.diagnostic.open_float, {desc = 'Show diagnostics'})
vim.keymap.set('n', '[l', vim.diagnostic.goto_prev, {desc = "Go to previous diagnostic"})
vim.keymap.set('n', ']l', vim.diagnostic.goto_next, {desc = "Go to next diagnostic"})
vim.keymap.set('n', 'gi', function() require('telescope.builtin').lsp_implementations() end, {desc = "Go to implementation"})
vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, {desc = "Show signature help"})
vim.keymap.set('n', 'gr', function() require('telescope.builtin').lsp_references() end, {desc = "Go to reference"})
vim.keymap.set('n', 'gt', function() require('telescope.builtin').lsp_type_definitions() end, {desc = "Go to type definition"})
vim.keymap.set('n', 'gd', function() require('telescope.builtin').lsp_definitions() end, {desc = "Go to definition"})
vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, {desc = "Go to declaration"})
vim.keymap.set('n', 'ghi', function() require('telescope.builtin').lsp_incoming_calls() end, {desc = "Show incoming calls"})
vim.keymap.set('n', 'gho', function() require('telescope.builtin').lsp_outgoing_calls() end, {desc = "Show outgoing calls"})
vim.keymap.set('n', 'gn', vim.lsp.buf.rename, {desc = "Rename"})

-- Create highlight groups for border and background
-- Set border
--
-- TODO: When this issue is resolved, there will be an option to configure the border.
-- issue: https://github.com/neovim/nvim-lspconfig/issues/2068
local border = {
  {" ", "LspFloatBorder"},
}
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts = opts or {}
  opts.border = opts.border or border
  local original_return_value = {orig_util_open_floating_preview(contents, syntax, opts, ...)}
  local window_number = original_return_value[2]
  vim.fn.setwinvar(window_number, '&winhighlight', 'NormalFloat:LspFloatNormal')
  return unpack(original_return_value)
end
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

      local group_id = vim.api.nvim_create_augroup('MyVirtColumn', {})
      vim.api.nvim_create_autocmd(
        {'BufWinEnter', 'VimResized',},
        {
          callback = function() vim.cmd.VirtColumnRefresh() end,
          group = group_id,
        }
      )
    end,
  }
)

-- lua library specfically for use in neovim
Plug('nvim-lua/plenary.nvim')

Plug(
  'iamcco/markdown-preview.nvim',
  {
    -- TODO: This won't work until this bug in neovim is fixed.
    -- issue: https://github.com/neovim/neovim/issues/18822
    ['do'] = ":call mkdp#util#install()",
    -- Add 'vim-plug' to the filetype list so that the plugin will be loaded before vim-plug runs the 'do' command.
    -- This is necessary since the 'do' command calls a function from this plugin.
    -- source: https://github.com/iamcco/markdown-preview.nvim/issues/50
    ['for'] = {'markdown', 'vim-plug'},
  }
)

Plug(
  'nvim-telescope/telescope.nvim',
  {
    branch = '0.1.x',
    config = function()
      telescope = require('telescope')
      actions = require('telescope.actions')
      resolve = require('telescope.config.resolve')

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
          sorting_strategy = 'ascending',
          layout_strategy = 'vertical',
          layout_config = {
            vertical = {
              height = .90,
              width = .90,
              mirror = true,
              prompt_position = 'top',
              preview_cutoff = 5,
              preview_height = resolve.resolve_height(.60),
            },
          },
        },
        pickers = {

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
        command! Highlights Telescope highlights
        command! Autocommands Telescope autocommands
        command! Mappings Telescope keymaps
      ]])
    end,
  }
)

Plug(
  'stevearc/dressing.nvim',
  {
    config = function()
      require('dressing').setup({
        input = {enabled = false,},
        select = {
          telescope = require("telescope.themes").get_cursor({
            border = false,
            layout_config = {
              height = 4,
            },
          }),
          get_config = function(options)
            if options.kind == 'mason.ui.language-filter' then
              return {
                telescope = {
                  layout_strategy = 'center',
                  border = true,
                  layout_config = {
                    width = 0.6,
                    height = 0.6,
                  },
                },
              }
            end
          end,
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
            max = math.floor(vim.o.lines * .25),
          },
        },
        window = {
          border = 'rounded',
        },
      })

      -- Add a highlight group for the border
      local group_id = vim.api.nvim_create_augroup('WhichKeyNvim', {})
      vim.api.nvim_create_autocmd(
        {'FileType',},
        {
          pattern = {'WhichKey'},
          callback = function()
            vim.opt_local.winhighlight:append(',FloatBorder:WhichKeyBorder')
            vim.api.nvim_create_autocmd(
              {'OptionSet'},
              {
                group = group_id,
                pattern = {'winhighlight'},
                once = true,
                callback = function()
                  vim.opt_local.winhighlight:append(',FloatBorder:WhichKeyBorder')
                end,
              }
            )
          end,
          group = group_id,
        }
      )
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
        foldmethod = vim.o.foldmethod
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
      --
      -- TODO: treesitter commands don't seem to be available until 'VimEnter' so I'll call this function then.
      -- I think this bug in neovim might be the reason for this.
      -- issue: https://github.com/neovim/neovim/issues/18822
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
    ['do'] = ':lua vim.cmd.TSUpdateSync()',
  }
)

Plug(
  'terrortylor/nvim-comment',
  {
    config = function()
      require('nvim_comment').setup({
        comment_empty = false,
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

      vim.fn.sign_define(
        'LightBulbSign',
        {
          text = is_nerdfont_enabled and unicode('f834') or '💡',
          texthl = 'CodeActionSign',
        }
      )
    end,
  }
)

Plug(
  'j-hui/fidget.nvim',
  {
    config = function()
      local margin = ' '
      local border = ' ┃'
      require('fidget').setup({
        text = {
          spinner = 'dots',
        },
        window = {
          blend = 0,
          zindex = 99,
        },
        fmt = {
          fidget = function(fidget_name, spinner)
            return string.format('%s%s %s%s', margin, spinner, fidget_name, border)
          end,
          task = function(task_name, message, percentage)
            return string.format(
              '%s%s%s%s%s',
              margin,
              message,
              percentage and string.format(' (%s%%)', percentage) or '',
              task_name and string.format(' [%s]', task_name) or '',
              border
            )
          end,
        },
        sources = {
          ['null-ls'] = {
            ignore = true,
          },
        },
      })
    end,
  }
)
-- }}}

-- File Explorer {{{
Plug(
  'kyazdani42/nvim-tree.lua',
  {
    config = function()
      require('nvim-tree').setup({
        create_in_closed_folder = true,
        hijack_cursor = true,
        sync_root_with_cwd = true,
        update_focused_file = {
          enable = true,
        },
        git = {
          enable = false,
        },
        view = {
          signcolumn = 'yes',
        },
        renderer = {
          indent_markers = {
            enable = true,
            icons = {
              corner = '│',
            },
          },
          icons = {
            show = {
              file = false,
              folder = false,
            },
          },
        },
        actions = {
          change_dir = {
            enable = false,
          },
          open_file = {
            window_picker = {
              enable = false,
            },
          },
        },
        on_attach = function(buffer_number)
          local inject_node = require("nvim-tree.utils").inject_node
          vim.keymap.set('n', 'h', '<BS>', {buffer = buffer_number, remap = true})
          vim.keymap.set('n', 'l', '<CR>', {buffer = buffer_number, remap = true})
          vim.keymap.set('n', '<Tab>', '<CR>', {buffer = buffer_number, remap = true})
        end,
      })

      -- TODO: Remove my code for opening nvim-tree in all tabs once it gets added to the plugin.
      -- issue: https://github.com/kyazdani42/nvim-tree.lua/issues/1493
      local function close_tree()
        tabdo(require('nvim-tree.api').tree.close)

        -- Stop opening the tree when a new tab is made
        vim.api.nvim_del_augroup_by_name('MyNvimTreeNewTab')
      end
      local function open_tree()
        local current_tab = vim.fn.tabpagenr()
        local function open_tree_and_go_to_previous_window()
          require('nvim-tree.api').tree.open()

          -- For all tabs besides the current one, I don't want to change the active window to the tree.
          if vim.fn.tabpagenr() ~= current_tab then
            vim.cmd.wincmd('p')
          end
        end
        tabdo(open_tree_and_go_to_previous_window)

        -- So the current tab has the right file focused
        vim.cmd.wincmd('p')
        vim.cmd.wincmd('p')

        -- Open the tree when a new tab is made
        local group_id = vim.api.nvim_create_augroup('MyNvimTreeNewTab', {})
        vim.api.nvim_create_autocmd(
          {'TabNewEntered',},
          {
            callback = open_tree_and_go_to_previous_window,
            group = group_id,
            -- So that the 'BufWinEnter' event will fire when we create the new tree window and it will get configured.
            nested = true,
          }
        )
      end
      local function toggle_tree()
        local is_tree_visible = require('nvim-tree.view').is_visible()
        if is_tree_visible then
          close_tree()
        else
          open_tree()
        end
      end
      vim.keymap.set("n", "<M-e>", toggle_tree, {silent = true})

      -- nvim-tree has an augroup named 'NvimTree' so I have to use a different name
      local group_id = vim.api.nvim_create_augroup('__NvimTree', {})
      local function configure_nvim_tree_window()
        if vim.o.filetype ~= 'NvimTree' then
          return
        end

        vim.w.is_explorer = true
        vim.opt_local.winbar = '%#Normal#%= Press %#NvimTreeWinBar#g?%#Normal# for help%='
      end
      vim.api.nvim_create_autocmd(
        {'BufWinEnter',},
        {
          callback = configure_nvim_tree_window,
          group = group_id,
        }
      )
      local function get_window_count()
        local window_count = 0
        for window_number=1,vim.fn.winnr('$') do
          local window_id = vim.fn.win_getid(window_number)
          local is_floating_window = vim.api.nvim_win_get_config(window_id).relative ~= ''
          if not is_floating_window then
            window_count = window_count + 1
          end
        end

        return window_count
      end
      local function close_if_only_nvim_tree_left()
        local window_count = get_window_count()
        local will_be_last_window_in_tab = window_count == 2
        if not will_be_last_window_in_tab then
          return
        end

        local function close_if_nvim_tree()
          if vim.o.filetype ~= 'NvimTree' then
            return
          end

          local is_last_window = get_window_count() == 1
          if not is_last_window then
            return
          end

          local is_last_tab = vim.fn.tabpagenr('$') == 1
          if is_last_tab then
            vim.cmd.q()
          else
            vim.cmd.tabclose()
          end
        end

        vim.api.nvim_create_autocmd(
          {'WinEnter',},
          {
            callback = close_if_nvim_tree,
            once = true,
          }
        )
      end
      vim.api.nvim_create_autocmd(
        {'WinClosed',},
        {
          callback = close_if_only_nvim_tree_left,
          group = group_id,
        }
      )
    end,
  }
)
-- }}}

-- Autocomplete {{{
Plug('hrsh7th/cmp-omni')

Plug('hrsh7th/cmp-cmdline')

Plug('dmitmel/cmp-cmdline-history')

Plug('andersevenrud/cmp-tmux')

Plug('hrsh7th/cmp-buffer')

Plug('hrsh7th/cmp-nvim-lsp')

Plug('hrsh7th/cmp-path')

Plug('hrsh7th/cmp-nvim-lsp-signature-help')

Plug(
  'uga-rosa/cmp-dictionary',
  {
    -- TODO: This plugin updates dictionaries on BufEnter. This BufEnter autocommand is registered in the setup function.
    -- Since this operation is slow I want to run it in the background, but the 'async' option provided by the plugin
    -- still results in noticeable lag when the first buffer is opened. To prevent this lag, I call setup() after I've
    -- already updated the dictionaries in the background. This way when the BufEnter autocommand runs, the dictionaries
    -- are already cached. Ideally, there would be an option to disable this autocommand.
    config = function()
      local function callback(_)
        require("cmp_dictionary").update()

        require("cmp_dictionary").setup({
          dic = {
            ['*'] = { '/usr/share/dict/words' },
          },
          first_case_insensitive = true,
        })
      end
      vim.fn.timer_start(0, callback)
    end,
  }
)

Plug(
  'L3MON4D3/LuaSnip',
  {
    config = function()
      require('luasnip').config.set_config({
        history = true,
        delete_check_events = "TextChanged",
      })
      local function callback(_)
        require('luasnip.loaders.from_vscode').load()
      end
      vim.fn.timer_start(0, callback)
    end
  }
)

Plug('saadparwaiz1/cmp_luasnip')

Plug('rafamadriz/friendly-snippets')

Plug(
  'hrsh7th/nvim-cmp',
  {
    config = function()
      local cmp = require("cmp")
      local luasnip = require('luasnip')
      local cmp_buffer = require('cmp_buffer')

      -- sources
      local buffer = {
        name = 'buffer',
        option = {
          keyword_length = 2,
          get_bufnrs = function()
            local filtered_buffer_numbers = {}
            local all_buffer_numbers = vim.api.nvim_list_bufs()
            for _, buffer_number in ipairs(all_buffer_numbers) do
              local is_buffer_loaded = vim.api.nvim_buf_is_loaded(buffer_number)
              -- 5 megabyte max
              local is_buffer_under_max_size =
                vim.api.nvim_buf_get_offset(buffer_number, vim.api.nvim_buf_line_count(buffer_number)) < 1024 * 1024 * 5

              if is_buffer_loaded and is_buffer_under_max_size then
                table.insert(filtered_buffer_numbers, buffer_number)
              end
            end

            return filtered_buffer_numbers
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
        option = { all_panes = true, label = 'Tmux', },
      }
      local cmdline = { name = 'cmdline' }
      local cmdline_history = {
        name = 'cmdline_history',
        max_item_count = 2,
      }
      local dictionary = {
        name = 'dictionary',
        keyword_length = 2,
        keyword_pattern = [[\a\+]],
      }
      local lsp_signature = { name = 'nvim_lsp_signature_help' }
      local luasnip_source = {
        name = 'luasnip',
        option = {use_show_condition = false},
      }

      -- helpers
      local is_cursor_preceded_by_nonblank_character = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match('%s') == nil
      end
      local cmdline_search_config = {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          buffer,
          cmdline_history,
        }
      }

      cmp.setup({
        formatting = {
          fields = {'abbr', 'kind'},
          format = function(entry, vim_item)
            vim_item.menu = nil
            return vim_item
          end,
        },
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        window = {
          documentation = {
            winhighlight = 'NormalFloat:CmpDocumentationNormal,FloatBorder:CmpDocumentationBorder',
            border = 'solid',
          },
          completion = {
            winhighlight = 'NormalFloat:CmpNormal,Pmenu:CmpNormal,CursorLine:CmpCursorLine,PmenuSbar:CmpScrollbar',
            border = 'none',
            side_padding = 1,
            col_offset = 4,
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
            lsp_signature,
          },
          {
            dictionary,
          }
        ),
        sorting = {
          comparators = {
            function(...)
              return cmp_buffer:compare_locality(...)
            end,
          },
        },
      })

      cmp.setup.cmdline('/', cmdline_search_config)
      cmp.setup.cmdline('?', cmdline_search_config)
      cmp.setup.cmdline(
        ':',
        {
          formatting = {
            fields = {'abbr', 'menu'},
            format = function(entry, vim_item)
              vim_item.menu = ({
                cmdline = 'Commandline',
                cmdline_history = 'History',
                buffer = 'Buffer',
                path = 'Path',
              })[entry.source.name]
              return vim_item
            end,
          },
          mapping = cmp.mapping.preset.cmdline(),
          sources = cmp.config.sources(
            {
              cmdline,
              cmdline_history,
              path,
              buffer,
            }
          )
        }
      )
    end
  }
)
-- }}}

-- Tool Manager {{{
Plug(
  'williamboman/mason.nvim',
  {
    config = function()
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
    end,
  }
)

Plug(
  'williamboman/mason-lspconfig.nvim',
  {
    config = function()
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

        ["lemminx"] = function()
          lspconfig.lemminx.setup(
            vim.tbl_deep_extend(
              'force',
              default_server_config,
              {
                settings = {
                  xml = {
                    catalogs = {'/etc/xml/catalog'},
                  },
                },
              }
            )
          )
        end,
      })
    end,
  }
)

Plug('neovim/nvim-lspconfig')

Plug('b0o/schemastore.nvim')

-- }}}

-- CLI -> LSP {{{
-- A language server that acts as a bridge between neovim's language server client and commandline tools that don't
-- support the language server protocol. It does this by transforming the output of a commandline tool into the
-- format specified by the language server protocol.
Plug(
  'jose-elias-alvarez/null-ls.nvim',
  {
    config = function()
      local null_ls = require('null-ls')
      local builtins = null_ls.builtins
      null_ls.setup({
        sources = {
          builtins.diagnostics.shellcheck.with({
            filetypes = { 'sh', 'bash' },
          }),
          builtins.code_actions.shellcheck.with({
            filetypes = { 'sh', 'bash' },
          }),
          builtins.diagnostics.fish,
          builtins.diagnostics.markdownlint,
        },
      })
    end,
  }
)
-- }}}
EOF

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
    highlight CursorLine ctermfg=NONE ctermbg=NONE cterm=underline
    " transparent background
    highlight Normal ctermbg=NONE
    highlight EndOfBuffer ctermbg=NONE
    " relative line numbers
    highlight LineNr ctermfg=15
    highlight! link LineNrAbove LineNr
    highlight! link LineNrBelow LineNrAbove
    highlight WordUnderCursor ctermbg=8
    highlight! link IncSearch Search
    highlight TabLine ctermbg=NONE ctermfg=15
    highlight TabLineSel ctermbg=8 ctermfg=NONE
    highlight TabLineFill ctermbg=NONE
    highlight TabLineCharSel ctermbg=NONE ctermfg=8
    highlight! link TabLineChar TabLineCharSel
    highlight TabLineIndexSel ctermbg=8 ctermfg=6
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
    highlight Folded ctermfg=15 ctermbg=24 cterm=NONE
    highlight FoldColumn ctermfg=15 ctermbg=NONE
    highlight SpecialKey ctermfg=13 ctermbg=NONE
    highlight NonText ctermfg=15 ctermbg=NONE
    highlight NvimTreeWinBar ctermfg=13 ctermbg=NONE
    highlight ExplorerTabLine ctermfg=13 ctermbg=NONE
    highlight NerdTreeNormal ctermbg=NONE
    highlight VirtColumn ctermfg=24
    highlight DiagnosticSignError ctermfg=1 ctermbg=NONE
    highlight DiagnosticSignWarn ctermfg=3 ctermbg=NONE
    highlight DiagnosticSignInfo ctermfg=4 ctermbg=NONE
    highlight DiagnosticSignHint ctermfg=5 ctermbg=NONE
    highlight! link DiagnosticUnderlineError Error
    highlight! link DiagnosticUnderlineWarn Warning
    highlight DiagnosticUnderlineInfo ctermfg=4 ctermbg=NONE cterm=undercurl
    highlight DiagnosticUnderlineHint ctermfg=5 ctermbg=NONE cterm=undercurl
    highlight! link DiagnosticInfo DiagnosticSignInfo
    highlight! link DiagnosticHint DiagnosticSignHint
    highlight! CmpItemAbbrMatch ctermbg=NONE ctermfg=6
    highlight! link CmpItemAbbrMatchFuzzy CmpItemAbbrMatch
    highlight! CmpItemKind ctermbg=NONE ctermfg=15
    highlight! link CmpItemMenu CmpItemKind
    highlight! link CmpNormal Float2Normal
    highlight! link CmpDocumentationNormal Float3Normal
    highlight! link CmpDocumentationBorder CmpDocumentationNormal
    highlight CmpCursorLine ctermfg=6 ctermbg=NONE cterm=reverse
    " autocomplete popupmenu
    highlight PmenuSel ctermfg=6 ctermbg=NONE cterm=reverse
    highlight Pmenu ctermfg=NONE ctermbg=24
    highlight PmenuThumb ctermfg=NONE ctermbg=15
    highlight! link PmenuSbar CmpNormal
    " List of telescope highlight groups:
    " https://github.com/nvim-telescope/telescope.nvim/blob/master/plugin/telescope.lua
    highlight! TelescopePromptNormal ctermbg=24 cterm=underline
    highlight! TelescopePromptBorder ctermbg=24 ctermfg=24
    highlight! TelescopePromptTitle ctermbg=24 ctermfg=5 cterm=reverse,bold,nocombine
    highlight! TelescopePreviewNormal ctermbg=16
    highlight! TelescopePreviewBorder ctermbg=16 ctermfg=16
    highlight! TelescopePreviewTitle ctermbg=16 ctermfg=16
    highlight! TelescopeResultsNormal ctermbg=24
    highlight! TelescopeResultsBorder ctermbg=24 ctermfg=24
    highlight! TelescopeResultsTitle ctermbg=24 ctermfg=24
    highlight! TelescopePromptPrefix ctermbg=24 ctermfg=5 cterm=none,nocombine
    highlight! TelescopeMatching ctermbg=NONE ctermfg=6
    highlight! TelescopeSelectionCaret ctermbg=8 ctermfg=8
    highlight TelescopePromptCounter ctermfg=15 cterm=none,nocombine
    highlight MasonHeader ctermbg=NONE ctermfg=4 cterm=reverse,bold
    highlight MasonHighlight ctermbg=NONE ctermfg=6
    highlight MasonHighlightBlockBold ctermbg=NONE ctermfg=6 cterm=reverse,bold
    highlight MasonMuted ctermbg=NONE ctermfg=NONE
    highlight MasonMutedBlock ctermbg=NONE ctermfg=15 cterm=reverse
    highlight MasonError ctermbg=NONE ctermfg=1
    highlight! link NormalFloat Float1Normal
    highlight! link FloatBorder Float1Border
    highlight LuaSnipNode ctermfg=11
    highlight! link WhichKeyFloat Float4Normal
    highlight! link WhichKeyBorder Float4Border
    highlight CodeActionSign ctermbg=NONE ctermfg=3
    highlight! link LspFloatNormal Float2Normal
    highlight! link LspFloatBorder Float2Border
    highlight Float1Normal ctermbg=32
    highlight! link Float1Border Float1Normal
    highlight Float2Normal ctermbg=24
    highlight! link Float2Border Float2Normal
    highlight Float3Normal ctermbg=8
    highlight! link Float3Border Float3Normal
    highlight Float4Normal ctermbg=0
    highlight Float4Border ctermbg=0 ctermfg=15
    highlight FidgetTitle ctermbg=0 ctermfg=15 cterm=italic
    highlight FidgetTask ctermbg=0 ctermfg=15 cterm=italic
    highlight NvimTreeIndentMarker ctermfg=15
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
command! MyPlugSnapshot call CreateSnapshotSync()
function! UpdateAndSnapshotSync()
  let g:plug_window = 'enew'

  PlugUpgrade

  if exists(':TSDisable')
    TSDisable highlight
  endif
  0tabnew
  PlugUpdate --sync
  PlugDiff
  if exists(':TSEnable')
    TSEnable highlight
  endif

  0tabnew
  call CreateSnapshotSync()
endfunction
command! MyPlugUpdate call UpdateAndSnapshotSync()
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
