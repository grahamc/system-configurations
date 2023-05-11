-- vim:foldmethod=marker
-- Exit if vim is not running in a terminal (also referred to as a tty). I detect this by
-- checking if the input to vim is coming from a terminal or vim is outputting to a terminal.
if not vim.fn.has('ttyin') and not vim.fn.has('ttyout') then
  return
end

-- TODO: The tty{in,out} check passes in vscode so I'm explicitly checking that it isn't running in vscode.
if vim.g.vscode ~= nil then
  return
end

-- Miscellaneous {{{
vim.o.confirm = true
vim.o.mouse = 'a'
vim.o.scrolloff = 999
vim.o.jumpoptions = 'stack'

-- persist undo history to disk
vim.o.undofile = true

local group_id = vim.api.nvim_create_augroup('General', {})
vim.api.nvim_create_autocmd(
  'FileType',
  {
    pattern = 'sh',
    callback = function()
      vim.opt_local.keywordprg = 'man'
    end,
    group = group_id,
  }
)
-- Highlight the word under the cursor
vim.api.nvim_create_autocmd(
  'CursorHold',
  {
    callback = function()
      vim.cmd(string.format(
        [[silent! 2match WordUnderCursor /\V\<%s\>/]],
        vim.fn.escape(vim.fn.expand([[<cword>]]), [[/\]])
      ))
    end,
    group = group_id,
  }
)
-- Don't highlight the word under the cursor for inactive windows
vim.api.nvim_create_autocmd(
  'WinLeave',
  {
    callback = function()
      vim.cmd('2match none')
    end,
    group = group_id,
  }
)
-- After a quickfix command is run, open the quickfix window , if there are results
vim.api.nvim_create_autocmd(
  'QuickFixCmdPost',
  {
    pattern = '[^l]*',
    callback = function()
      vim.cmd.cwindow()
    end,
    group = group_id,
  }
)
vim.api.nvim_create_autocmd(
  'QuickFixCmdPost',
  {
    pattern = 'l*',
    callback = function()
      vim.cmd.lwindow()
    end,
    group = group_id,
  }
)
-- Put focus back in quickfix window after opening an entry
vim.api.nvim_create_autocmd(
  'FileType',
  {
    pattern = 'qf',
    callback = function()
      vim.keymap.set('n', '<CR>', '<CR><C-W>p', {buffer = true})
    end,
    group = group_id,
  }
)
vim.api.nvim_create_autocmd(
  'OptionSet',
  {
    pattern = 'readonly',
    callback = function()
      if vim.v.option_new then
        vim.opt_local.colorcolumn = ''
      end
    end,
    group = group_id,
  }
)
vim.api.nvim_create_autocmd(
  'FileType',
  {
    pattern = {'qf', 'help'},
    callback = function()
      vim.opt_local.colorcolumn = ''
    end,
    group = group_id,
  }
)

vim.keymap.set('', '<C-x>', '<Cmd>xa<CR>')

-- suspend vim
vim.keymap.set({'n', 'i', 'x'}, '<C-z>', '<Cmd>suspend<CR>')

-- Decide which actions to take when the enter key is pressed.
local function get_enter_key_actions()
  local autopairs_keys = MPairs.autopairs_cr()
  -- If only the enter key is returned, that means we aren't inside a pair.
  local is_cursor_in_empty_pair = vim.inspect(autopairs_keys) ~= [["\r"]]
  if is_cursor_in_empty_pair then
    return autopairs_keys
  end

  return [[<CR>]]
end
vim.keymap.set('i', '<CR>', get_enter_key_actions, {expr = true})

vim.o.colorcolumn = '120'

vim.o.shell = 'sh'

vim.keymap.set('n', '<BS>', '<C-^>')

vim.o.ttimeout = true
vim.o.ttimeoutlen = 50

-- Delete comment character when joining commented lines
vim.opt.formatoptions:append('j')
vim.opt.formatoptions:append('r')

-- Open link on mouse click. Works on urls that wrap on to the following line.
_G.ClickLink = function()
  cfile = vim.fn.expand('<cfile>')
  is_url =
    cfile:match("https?://(([%w_.~!*:@&+$/?%%#-]-)(%w[-.%w]*%.)(%w%w%w?%w?)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))")
    or cfile:match("ftps?://(([%w_.~!*:@&+$/?%%#-]-)(%w[-.%w]*%.)(%w%w%w?%w?)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))")
  if is_url then
    vim.fn.jobstart({'open', cfile}, {detach = true})
  end
end
vim.keymap.set('n', '<C-LeftMouse>', '<LeftMouse><Cmd>lua ClickLink()<CR>')

vim.o.scroll = 1

vim.keymap.set('n', '|', '<Cmd>set list!<CR>', {silent = true})

vim.o.shortmess = 'filnxtToOFs'

-- I have a mapping in my terminal for <C-i> that sends F9 to get around the fact that TMUX considers <C-i> the
-- same as <Tab> right now since TMUX lost support for extended keys.
-- TODO: tmux issue: https://github.com/tmux/tmux/issues/2705#issuecomment-841133549
vim.keymap.set({"n"}, "<F9>", '<C-i>')

-- Use shift+u to redo the last undone change
vim.keymap.set({"n"}, "<S-u>", '<C-r>')
-- }}}

-- Utilities {{{
_G.unicode = function(hex)
  return vim.fn.execute(
    string.format(
      [[echon "\u%s"]],
      hex
    )
  )
end
function vim.get_visual_selection()
  local mode_char = vim.fn.mode()
  -- "\x16" is the code for ctrl+v i.e. visual-block mode
  local in_visual_mode = mode_char == 'v' or mode_char == 'V' or mode_char == "\x16"
  if not in_visual_mode then
    return ''
  end

  vim.cmd('noau normal! "vy"')
  local text = vim.fn.getreg('v')
  vim.fn.setreg('v', {})
  text = string.gsub(text, "\n", "")

  return text
end
-- }}}

-- Autosave {{{
_G.is_autosave_enabled = true
_G.is_autosave_job_queued = false
local group_id = vim.api.nvim_create_augroup('Autosave', {})
vim.api.nvim_create_autocmd(
  {"TextChanged", "TextChangedI",},
  {
    callback = function()
      if not is_autosave_enabled then
        return
      end

      if is_autosave_job_queued then
        return
      end

      is_autosave_job_queued = true
      vim.defer_fn(
        function()
          is_autosave_job_queued = false
          vim.cmd("silent! wall")
        end,
        500 -- time in milliseconds between saves
      )
    end,
    group = group_id,
  }
)
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
  -- TODO: Filter out floating windows or else it will throw an error when one editor and one floating window are open.
  if vim.fn.winnr('$') > 1 then
    vim.cmd.close()
    return
  end

  local last_tab = vim.fn.tabpagenr('#')
  vim.cmd.q()
  vim.cmd(string.format(
    [[silent! tabnext %s]],
    last_tab
  ))
end
vim.keymap.set(
  'n',
  '<C-q>',
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
      -- Don't equalize splits if the new window is floating, it won't get resized anyway.
      -- Don't equalize when vim is starting up or it will reset the window sizes from my session.
      if vim.api.nvim_win_get_config(0).relative ~= '' or vim.fn.has('vim_starting') then
        return
      end
      vim.cmd.wincmd('=')
    end,
    group = group_id,
  }
)
-- }}}

-- Tab pages {{{
vim.keymap.set('n', '<C-t>', function() vim.cmd('$tabnew') end, {silent = true})
vim.keymap.set({'n', 'i'}, '<F7>', vim.cmd.tabprevious, {silent = true})
vim.keymap.set({'n', 'i'}, '<F8>', vim.cmd.tabnext, {silent = true})

-- Switch tabs with <Leader><tab number>
for window_index=1,9 do
  vim.keymap.set('n', '<Leader>' .. window_index, function() vim.cmd('silent! tabnext ' .. tostring(window_index)) end)
end
-- }}}

-- Indentation {{{
vim.o.expandtab = true
vim.o.autoindent = true
-- vim.o.smartindent = true
vim.o.smarttab = true
-- Round indent to multiple of shiftwidth (applies to < and >)
vim.o.shiftround = true
local tab_width = 2
vim.o.tabstop = tab_width
vim.o.shiftwidth = tab_width
vim.o.softtabstop = tab_width
-- }}}

-- Folds {{{
vim.opt.fillchars:append('foldsep: ')
vim.opt.fillchars:append('fold: ')
vim.opt.fillchars:append('foldclose:›')
vim.opt.fillchars:append('foldopen:⌄')
vim.o.foldlevelstart = 99
vim.keymap.set('n', '<Tab>', 'za', {silent = true})

-- Setting this so that the fold column gets displayed
vim.o.foldenable = true

-- Set max number of nested folds when 'foldmethod' is 'syntax' or 'indent'
vim.o.foldnestmax = 1

-- Minimum number of lines a fold must have to be able to be closed
vim.o.foldminlines = 1

-- Fold visually selected lines. 'foldmethod' must be set to 'manual' for this work.
vim.keymap.set('x', 'Tab', 'zf')

-- Toggle opening and closing all folds
local function fold_toggle()
  if vim.o.foldlevel > 0 then
    return 'zM'
  else
    return 'zR'
  end
end
vim.keymap.set('n', '<S-Tab>', fold_toggle, {silent = true, expr =true})

-- auto-resize the fold column
-- 
-- TODO: When this issue is resolved, I can set foldcolumn to 1 and remove the digits that signify a nested fold.
-- issue: https://github.com/neovim/neovim/pull/17446
vim.o.foldcolumn = 'auto:9'

-- Jump to the top and bottom of the current fold
vim.keymap.set({'n', 'x'}, '[<Tab>', '[z')
vim.keymap.set({'n', 'x'}, ']<Tab>', ']z')

local function SetDefaultFoldMethod()
  foldmethod = vim.o.foldmethod
  isFoldmethodOverridable = foldmethod ~= 'marker'
    and foldmethod ~= 'diff'
    and foldmethod ~= 'expr'
  if isFoldmethodOverridable then
    vim.o.foldmethod = 'indent'
  end
end
local group_id = vim.api.nvim_create_augroup('SetDefaultFoldMethod', {})
vim.api.nvim_create_autocmd(
  'FileType',
  {
    callback = SetDefaultFoldMethod,
    group = group_id,
  }
)

_G.FoldText = function()
  local window_width = vim.fn.winwidth(0)
  local gutter_width = vim.fn.getwininfo(vim.fn.win_getid())[1].textoff
  local line_width = window_width - gutter_width

  local fold_line_count = (vim.v.foldend - vim.v.foldstart) + 1
  local fold_description = string.format('(%s)', fold_line_count)
  local fold_description_length = vim.fn.strdisplaywidth(fold_description)

  local separator_text = '⋯ '
  local separator_text_length = 2

  local line_text = vim.fn.getline(vim.v.foldstart)
  -- truncate if there isn't space for the fold description and separator text
  local max_line_text_length = line_width - (fold_description_length + separator_text_length)
  if vim.fn.strdisplaywidth(line_text) > max_line_text_length then
    local line_text = string.sub(line_text, 1, max_line_text_length)
  end

  return line_text .. separator_text .. fold_description
end
vim.o.foldtext = 'v:lua.FoldText()'
-- }}}

-- Autocomplete {{{
vim.o.complete = '.,w,b,u'
-- - show the completion menu even if there is only one suggestion
-- - when autocomplete gets triggered, no suggestion is selected
vim.o.completeopt = 'noselect'
vim.o.pumheight = 6
-- }}}

-- Command line {{{
-- on first wildchar press (<Tab>), show all matches and complete the longest common substring among them.
-- on subsequent wildchar presses, cycle through matches
vim.o.wildmode = 'longest:full,full'
vim.o.wildoptions = 'pum'
vim.o.cmdheight = 1
_G.smagic_abbrev = function()
  if vim.fn.getcmdtype() ~= ':' then
    return 's'
  end

  local cmdline = vim.fn.getcmdline()
  if cmdline == 's' or cmdline == [['<,'>s]] then
    return 'smagic'
  end

  return 's'
end
vim.cmd([[
  cnoreabbrev <expr> h getcmdtype() == ":" && getcmdline() == 'h' ? 'tab help' : 'h'
  " Autocommands get executed without smagic so I make sure that I explicitly specify it on the commandline
  " so if my autocommand has a substitute command it will use smagic.
  cnoreabbrev <expr> s v:lua.smagic_abbrev()
  cnoreabbrev <expr> %s getcmdtype() == ':' && getcmdline() == '%s' ? '%smagic' : '%s'
]])
vim.keymap.set('c', '<C-a>', '<C-b>', {remap = true})
-- }}}

-- Search {{{
vim.o.hlsearch = false
-- toggle search highlighting
vim.keymap.set('n', [[\]], '<Cmd>set hlsearch!<CR>', {silent = true})
-- }}}

-- Sessions {{{
vim.opt.sessionoptions:remove('blank')
vim.opt.sessionoptions:remove('options')
vim.opt.sessionoptions:append('tabpages')
vim.opt.sessionoptions:remove('folds')
_G.session_dir = vim.fn.stdpath('data') .. '/sessions'

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
  -- will always be the path to the vim executable and the second will be '--embed' so if no arguments were passed
  -- to neovim, the size of vim.v.argv will be two.
  local is_neovim_called_with_no_arguments = #vim.v.argv == 2
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
  pcall(vim.api.nvim_del_augroup_by_name, 'SaveSession')

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
  pcall(vim.api.nvim_del_augroup_by_name, 'SaveSession')

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
vim.o.breakat = ' ^I'
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

  local line = '%#StatusLine#Ln %l/%L'
  local column = '%#StatusLine#Col %c'
  local position = line .. ', ' .. column

  local filetype = nil
  if string.len(vim.o.filetype) > 0 then
    filetype = '%#StatusLine#' .. vim.o.filetype
  end

  local file_info = '%#StatusLine#%f%w%q'

  local fileformat = nil
  if vim.o.fileformat ~= 'unix' then
    fileformat = string.format('%%#StatusLineStandoutText#[%s]', vim.o.fileformat)
  end

  local readonly = nil
  if vim.o.readonly then
    indicator = unicode('f840')
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
    icon = unicode('f659') .. ' '
    local error = '%#StatusLineErrorText#' .. icon .. error_count
    table.insert(diagnostic_list, error)
  end
  local warning_count = diagnostic_count.warning
  if warning_count > 0 then
    icon = unicode('fad5') .. ' '
    local warning = '%#StatusLineWarningText#' .. icon  .. warning_count
    table.insert(diagnostic_list, warning)
  end
  local info_count = diagnostic_count.info
  if info_count > 0 then
    icon = unicode('f7fc') .. ' '
    local info = '%#StatusLineInfoText#' .. icon  .. info_count
    table.insert(diagnostic_list, info)
  end
  local hint_count = diagnostic_count.hint
  if hint_count > 0 then
    icon = unicode('f7fc') .. ' '
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

  local statusline_separator = '%#StatusLine# %= '
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
    buffer_name = buffer_name_highlight .. '  ' .. tab_index_highlight .. superscipt_tab_index .. buffer_name_highlight .. ' ' .. buffer_name .. buffer_name_highlight .. '   '

    local tab_marker = '%' .. tab_index .. 'T'

    local tab = tab_marker .. buffer_name .. '%#TabLineFill# '

    tabline = tabline .. tab
  end

  tabline = '%#TabLineFill#%=' .. tabline .. '%#TabLineFill#%='

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

    tabline = '%#ExplorerTabLine#' .. string.rep(' ', left_pad_length) .. title .. string.rep(' ', right_pad_length) .. '%#WinSeparator#' .. (vim.opt.fillchars:get().vert or '│') .. '%<' .. tabline
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
    source = true,
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
vim.keymap.set('n', '<S-l>', vim.diagnostic.open_float, {desc = 'Show diagnostics'})
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
      vim.keymap.set('n', 'zv', '<Cmd>SignifyHunkDiff<CR>')
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
      vim.keymap.set({'n', 'i'}, '<M-h>', '<Cmd>TmuxNavigateLeft<CR>', {silent = true})
      vim.keymap.set({'n', 'i'}, '<M-l>', '<Cmd>TmuxNavigateRight<CR>', {silent = true})
      vim.keymap.set({'n', 'i'}, '<M-j>', '<Cmd>TmuxNavigateDown<CR>', {silent = true})
      vim.keymap.set({'n', 'i'}, '<M-k>', '<Cmd>TmuxNavigateUp<CR>', {silent = true})
    end
  }
)
vim.g.tmux_navigator_no_mappings = 1
vim.g.tmux_navigator_preserve_zoom = 1
vim.g.tmux_navigator_disable_when_zoomed = 0

Plug('inkarkat/vim-CursorLineCurrentWindow')

Plug(
  'ethanholz/nvim-lastplace',
  {
    config = function()
      require('nvim-lastplace').setup({})
    end,
  }
)

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
              ["<C-j>"] = actions.preview_scrolling_down,
              ["<C-k>"] = actions.preview_scrolling_up,
              ["<C-h>"] = actions.select_horizontal,
            },
          },
          prompt_prefix = unicode('f002') .. '  ',
          sorting_strategy = 'ascending',
          layout_strategy = 'vertical',
          layout_config = {
            scroll_speed = 1,
            vertical = {
              height = .90,
              width = .90,
              mirror = true,
              prompt_position = 'top',
              preview_cutoff = 5,
              preview_height = resolve.resolve_height(.60),
            },
          },
          borderchars = {'─', ' ', ' ', ' ', '─', '─', ' ', ' ',},
          dynamic_preview_title = true,
          results_title = '(C-q: quickfix, C-t: new tab, C-{v,h}: vertical/horizontal split)',
        },
        pickers = {
          find_files = {
            hidden = true,
          },
          live_grep = {
            additional_args = {
              '--hidden',
              '--smart-case',
              '--follow',
            },
          },
        },
      })

      vim.cmd([[
        augroup TelescopeNvim
          autocmd!
          autocmd FileType TelescopePrompt setlocal nocursorline
        augroup END
      ]])

      local telescope_builtins = require('telescope.builtin')
      local function call_with_visual_selection(picker)
        local result = function()
          local visual_selection = vim.get_visual_selection()
          if #visual_selection > 0 then
            picker({default_text = visual_selection})
          else
            picker()
          end
        end

        return result
      end
      vim.keymap.set({'n', 'v'}, '<Leader>h', call_with_visual_selection(telescope_builtins.command_history))
      vim.keymap.set('n', '<Leader>b', '<Cmd>Telescope buffers<CR>')
      -- This is actually ctrl+/, see :help :map-special-keys
      vim.keymap.set('n', '<C-_>', '<Cmd>Telescope commands<CR>')
      vim.keymap.set({'n', 'v'}, '<Leader>k', call_with_visual_selection(telescope_builtins.help_tags))
      vim.keymap.set({'n', 'v'}, '<Leader>g', call_with_visual_selection(telescope_builtins.live_grep))
      vim.keymap.set('n', '<Leader>f', '<Cmd>Telescope find_files<CR>')
      vim.keymap.set('n', '<Leader>j', '<Cmd>Telescope jumplist<CR>')
      vim.keymap.set('n', '<Leader><Leader>', '<Cmd>Telescope resume<CR>')
      vim.keymap.set({'n', 'v'}, '<Leader>s', call_with_visual_selection(telescope_builtins.lsp_dynamic_workspace_symbols))
      vim.keymap.set('n', '<Leader>l', '<Cmd>Telescope diagnostics<CR>')
      vim.cmd([[
        command! Highlights Telescope highlights
        command! Autocommands Telescope autocommands
        command! Mappings Telescope keymaps
      ]])

      telescope.load_extension('fzf')
    end,
  }
)

Plug('nvim-telescope/telescope-fzf-native.nvim')

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
              height = 6,
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
    end,
  }
)

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

      _G.MaybeSetTreeSitterFoldmethod = function(_)
        foldmethod = vim.o.foldmethod
        is_foldmethod_overridable = foldmethod ~= 'manual'
          and foldmethod ~= 'marker'
          and foldmethod ~= 'diff'
        if require('nvim-treesitter.parsers').has_parser() and is_foldmethod_overridable then
          vim.o.foldmethod = 'expr'
          vim.o.foldexpr = 'nvim_treesitter#foldexpr()'
        end
      end
      -- TODO: I can't get `MaybeSetTreeSitterFoldmethod` to work without `timer_start`.
      vim.cmd([[
        augroup MyNvimTreeSitter
          autocmd!
          autocmd BufWinEnter * lua vim.fn.timer_start(0, MaybeSetTreeSitterFoldmethod)
        augroup END
      ]])
    end,
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

Plug('blankname/vim-fish')

Plug('windwp/nvim-ts-autotag')

Plug('JoosepAlviste/nvim-ts-context-commentstring')

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
          text = unicode('f834'),
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
          ['ltex'] = {
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
        hijack_cursor = true,
        sync_root_with_cwd = true,
        open_on_tab = true,
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
              corner = " ",
              edge = " ",
              item = " ",
              bottom = " ",
            },
          },
          icons = {
            show = {
              file = false,
              folder = false,
            },
            glyphs = {
              folder = {
                arrow_closed = '›',
                arrow_open = '⌄',
              },
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
          -- Set the default mappings
          local api = require('nvim-tree.api')
          api.config.mappings.default_on_attach(buffer_number)

          vim.keymap.set('n', 'h', '<BS>', {buffer = buffer_number, remap = true})
          vim.keymap.set('n', 'l', '<CR>', {buffer = buffer_number, remap = true})
          vim.keymap.set('n', '<Tab>', '<CR>', {buffer = buffer_number, remap = true})
        end,
      })
      vim.keymap.set("n", "<M-e>", '<cmd>NvimTreeFindFileToggle<cr>', {silent = true})

      -- nvim-tree has an augroup named 'NvimTree' so I have to use a different name
      local group_id = vim.api.nvim_create_augroup('__NvimTree', {})
      local function configure_nvim_tree_window()
        if vim.o.filetype ~= 'NvimTree' then
          return
        end

        vim.w.is_explorer = true
        vim.opt_local.winbar = '%#TabLineSel#%= Press %#NvimTreeWinBar#g?%#TabLineSel# for help%='
      end
      vim.api.nvim_create_autocmd(
        {'BufWinEnter',},
        {
          callback = configure_nvim_tree_window,
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

Plug('bydlw98/cmp-env')

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
        priority = 2,
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
      local nvim_lsp = { name = 'nvim_lsp', priority = 8, }
      local omni = { name = 'omni', priority = 3, }
      local path = {
        name = 'path',
        priority = 9,
        option = {
          label_trailing_slash = false,
        },
      }
      local tmux = {
        name = 'tmux',
        priority = 1,
        option = { all_panes = true, label = 'Tmux', },
      }
      local cmdline = { name = 'cmdline', priority = 9, }
      local cmdline_history = {
        name = 'cmdline_history',
        priority = 2,
        max_item_count = 2,
      }
      local lsp_signature = { name = 'nvim_lsp_signature_help', priority = 8, }
      local luasnip_source = {
        name = 'luasnip',
        priority = 6,
        option = {use_show_condition = false},
      }
      local env = {name = 'env', priority = 6,}

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
            vim_item.dup = 0
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
        -- The order of the sources controls which entry will be chosen if multiple sources return entries with the
        -- same names. Sources at the bottom of this list will be chosen over the sources above them.
        sources = cmp.config.sources(
          {
            lsp_signature,
            buffer,
            tmux,
            env,
            luasnip_source,
            omni,
            nvim_lsp,
            path,
          }
        ),
        sorting = {
          priority_weight = 100.0,
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
              vim_item.dup = 0
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
          width = 1,
          height = .95,
          icons = {
            package_installed = unicode('f632') .. '  ',
            package_pending = unicode('f251') .. '  ',
            package_uninstalled = unicode('f62f') .. '  ',
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
          autocmd FileType mason highlight clear WordUnderCursor
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

      local on_attach = function(client, buffer_number)
        capabilities = client.server_capabilities
        buffer_keymap = vim.api.nvim_buf_set_keymap
        keymap_opts = { noremap = true, silent = true }

        foldmethod = vim.o.foldmethod
        isFoldmethodOverridable = foldmethod ~= 'marker'
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

      cmp_lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()
      folding_capabilities = {
        textDocument = {
          foldingRange = {
            dynamicRegistration = false,
            lineFoldingOnly = true,
          },
        },
      }
      capabilities = vim.tbl_deep_extend(
        'error',
        cmp_lsp_capabilities,
        folding_capabilities
      )

      local default_server_config = {
        capabilities = capabilities,
        on_attach = on_attach,
      }

      local lspconfig = require('lspconfig')
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

        ["lua_ls"] = function()
          lspconfig.lua_ls.setup(
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
                      checkThirdParty = false,
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

Plug('b0o/SchemaStore.nvim')

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
          builtins.diagnostics.vale.with({
            -- NOTE: This should reflect all of the programming languages listed here:
            -- https://vale.sh/docs/topics/scoping/#code-1
            filetypes = {
              'c', 'cs', 'cpp', 'css', 'go', 'haskell', 'java', 'javascript', 'less', 'lua', 'perl', 'php',
              'python', 'r', 'ruby', 'sass', 'scala', 'swift',
            },
          }),
        },
      })
    end,
  }
)
-- }}}

-- Colorscheme {{{
Plug('nordtheme/vim')
vim.g.nord_bold = true
vim.g.nord_italic = true
vim.g.nord_italic_comments = true
vim.g.nord_underline = true
local function SetNordOverrides()
  vim.api.nvim_set_hl(0, 'MatchParen', {ctermfg = 'blue', ctermbg = 'NONE', underline = true,})
  -- Transparent vertical split
  vim.api.nvim_set_hl(0, 'WinSeparator', {ctermbg = 'NONE', ctermfg = 15,})
  -- statusline colors
  vim.api.nvim_set_hl(0, 'StatusLine', {ctermbg = 8, ctermfg = 'NONE',})
  vim.api.nvim_set_hl(0, 'StatusLineSeparator', {ctermfg = 8, ctermbg = 'NONE', reverse = true, bold = true,})
  vim.api.nvim_set_hl(0, 'StatusLineErrorText', {ctermfg = 1, ctermbg = 8,})
  vim.api.nvim_set_hl(0, 'StatusLineWarningText', {ctermfg = 3, ctermbg = 8,})
  vim.api.nvim_set_hl(0, 'StatusLineInfoText', {ctermfg = 4, ctermbg = 8,})
  vim.api.nvim_set_hl(0, 'StatusLineHintText', {ctermfg = 5, ctermbg = 8,})
  vim.api.nvim_set_hl(0, 'StatusLineStandoutText', {ctermfg = 3, ctermbg = 8,})
  vim.api.nvim_set_hl(0, 'CursorLine', {ctermfg = 'NONE', ctermbg = 'NONE', underline = true,})
  vim.api.nvim_set_hl(0, 'CursorLineNr', {link = 'CursorLine'})
  -- transparent background
  vim.api.nvim_set_hl(0, 'Normal', {ctermbg = 'NONE',})
  vim.api.nvim_set_hl(0, 'EndOfBuffer', {ctermbg = 'NONE',})
  -- relative line numbers
  vim.api.nvim_set_hl(0, 'LineNr', {ctermfg = 15,})
  vim.api.nvim_set_hl(0, 'LineNrAbove', {link = 'LineNr'})
  vim.api.nvim_set_hl(0, 'LineNrBelow', {link = 'LineNrAbove'})
  vim.api.nvim_set_hl(0, 'WordUnderCursor', {ctermbg = 8,})
  vim.api.nvim_set_hl(0, 'IncSearch', {link = 'Search'})
  vim.api.nvim_set_hl(0, 'TabLine', {ctermbg = 8, ctermfg = 15,})
  vim.api.nvim_set_hl(0, 'TabLineSel', {ctermbg = 8, ctermfg = 'NONE',})
  vim.api.nvim_set_hl(0, 'TabLineFill', {ctermbg = 8,})
  vim.api.nvim_set_hl(0, 'TabLineIndexSel', {ctermbg = 8, ctermfg = 6,})
  vim.api.nvim_set_hl(0, 'TabLineIndex', {link = 'TabLine'})
  vim.api.nvim_set_hl(0, 'Comment', {ctermfg = 15, ctermbg = 'NONE',})
  -- This variable contains a list of 16 colors that should be used as the color palette for terminals opened in vim.
  -- By unsetting this, I ensure that terminals opened in vim will use the colors from the color palette of the
  -- terminal in which vim is running
  vim.g.terminal_ansi_colors = nil
  -- Have vim only use the colors from the color palette of the terminal in which it runs
  vim.o.t_Co = 256
  vim.api.nvim_set_hl(0, 'Visual', {ctermbg = 3, ctermfg = 0,})
  -- Search hit
  vim.api.nvim_set_hl(0, 'Search', {ctermfg = 'DarkYellow', ctermbg = 'NONE', reverse = true,})
  -- Parentheses
  vim.api.nvim_set_hl(0, 'Delimiter', {ctermfg = 'NONE', ctermbg = 'NONE',})
  vim.api.nvim_set_hl(0, 'ErrorMsg', {ctermfg = 1, ctermbg = 'NONE',})
  vim.api.nvim_set_hl(0, 'WarningMsg', {ctermfg = 3, ctermbg = 'NONE',})
  vim.api.nvim_set_hl(0, 'Error', {ctermfg = 1, ctermbg = 'NONE', undercurl = true,})
  vim.api.nvim_set_hl(0, 'Warning', {ctermfg = 3, ctermbg = 'NONE', undercurl = true,})
  vim.api.nvim_set_hl(0, 'SpellBad', {link = 'Error'})
  vim.api.nvim_set_hl(0, 'NvimInternalError', {link = 'ErrorMsg'})
  vim.api.nvim_set_hl(0, 'Folded', {ctermfg = 15, ctermbg = 24,})
  vim.api.nvim_set_hl(0, 'FoldColumn', {ctermfg = 15, ctermbg = 'NONE',})
  vim.api.nvim_set_hl(0, 'SpecialKey', {ctermfg = 13, ctermbg = 'NONE',})
  vim.api.nvim_set_hl(0, 'NonText', {ctermfg = 15, ctermbg = 'NONE',})
  vim.api.nvim_set_hl(0, 'NvimTreeWinBar', {ctermfg = 6, ctermbg = 8,})
  vim.api.nvim_set_hl(0, 'ExplorerTabLine', {link = 'NvimTreeWinBar'})
  vim.api.nvim_set_hl(0, 'NerdTreeNormal', {ctermbg = 'NONE',})
  vim.api.nvim_set_hl(0, 'VirtColumn', {ctermfg = 24,})
  vim.api.nvim_set_hl(0, 'DiagnosticSignError', {ctermfg = 1, ctermbg = 'NONE',})
  vim.api.nvim_set_hl(0, 'DiagnosticSignWarn', {ctermfg = 3, ctermbg = 'NONE',})
  vim.api.nvim_set_hl(0, 'DiagnosticSignInfo', {ctermfg = 4, ctermbg = 'NONE',})
  vim.api.nvim_set_hl(0, 'DiagnosticSignHint', {ctermfg = 5, ctermbg = 'NONE',})
  vim.api.nvim_set_hl(0, 'DiagnosticUnderlineError', {link = 'Error'})
  vim.api.nvim_set_hl(0, 'DiagnosticUnderlineWarn', {link = 'Warning'})
  vim.api.nvim_set_hl(0, 'DiagnosticUnderlineInfo', {ctermfg = 4, ctermbg = 'NONE', undercurl = true,})
  vim.api.nvim_set_hl(0, 'DiagnosticUnderlineHint', {ctermfg = 5, ctermbg = 'NONE', undercurl = true,})
  vim.api.nvim_set_hl(0, 'DiagnosticInfo', {link = 'DiagnosticSignInfo'})
  vim.api.nvim_set_hl(0, 'DiagnosticHint', {link = 'DiagnosticSignHint'})
  vim.api.nvim_set_hl(0, 'CmpItemAbbrMatch', {ctermbg = 'NONE', ctermfg = 6,})
  vim.api.nvim_set_hl(0, 'CmpItemAbbrMatchFuzzy', {link = 'CmpItemAbbrMatch'})
  vim.api.nvim_set_hl(0, 'CmpItemKind', {ctermbg = 'NONE', ctermfg = 15,})
  vim.api.nvim_set_hl(0, 'CmpItemMenu', {link = 'CmpItemKind'})
  vim.api.nvim_set_hl(0, 'CmpNormal', {link = 'Float2Normal'})
  vim.api.nvim_set_hl(0, 'CmpDocumentationNormal', {link = 'Float3Normal'})
  vim.api.nvim_set_hl(0, 'CmpDocumentationBorder', {link = 'CmpDocumentationNormal'})
  vim.api.nvim_set_hl(0, 'CmpCursorLine', {ctermfg = 6, ctermbg = 'NONE', reverse = true,})
  -- autocomplete popupmenu
  vim.api.nvim_set_hl(0, 'PmenuSel', {ctermfg = 6, ctermbg = 'NONE', reverse = true,})
  vim.api.nvim_set_hl(0, 'Pmenu', {ctermfg = 'NONE', ctermbg = 24,})
  vim.api.nvim_set_hl(0, 'PmenuThumb', {ctermfg = 'NONE', ctermbg = 15,})
  vim.api.nvim_set_hl(0, 'PmenuSbar', {link = 'CmpNormal'})
  -- List of telescope highlight groups:
  -- https://github.com/nvim-telescope/telescope.nvim/blob/master/plugin/telescope.lua
  vim.api.nvim_set_hl(0, 'TelescopePromptNormal', {ctermbg = 24,})
  vim.api.nvim_set_hl(0, 'TelescopePromptBorder', {ctermbg = 24, ctermfg = 24,})
  vim.api.nvim_set_hl(0, 'TelescopePromptTitle', {ctermbg = 24, ctermfg = 6, reverse = true, bold = true,})
  vim.api.nvim_set_hl(0, 'TelescopePreviewNormal', {ctermbg = 16,})
  vim.api.nvim_set_hl(0, 'TelescopePreviewBorder', {ctermbg = 16, ctermfg = 15,})
  vim.api.nvim_set_hl(0, 'TelescopePreviewTitle', {ctermbg = 16, ctermfg = 15,})
  vim.api.nvim_set_hl(0, 'TelescopeResultsNormal', {ctermbg = 16,})
  vim.api.nvim_set_hl(0, 'TelescopeResultsBorder', {ctermbg = 16, ctermfg = 16,})
  vim.api.nvim_set_hl(0, 'TelescopeResultsTitle', {ctermbg = 16, ctermfg = 15, italic = true,})
  vim.api.nvim_set_hl(0, 'TelescopePromptPrefix', {ctermbg = 24, ctermfg = 6,})
  vim.api.nvim_set_hl(0, 'TelescopeMatching', {ctermbg = 'NONE', ctermfg = 6,})
  vim.api.nvim_set_hl(0, 'TelescopeSelection', {ctermbg = 24,})
  vim.api.nvim_set_hl(0, 'TelescopeSelectionCaret', {ctermbg = 24, ctermfg = 24,})
  vim.api.nvim_set_hl(0, 'TelescopePromptCounter', {ctermfg = 15,})
  vim.api.nvim_set_hl(0, 'MasonHeader', {ctermbg = 'NONE', ctermfg = 4, reverse = true, bold = true,})
  vim.api.nvim_set_hl(0, 'MasonHighlight', {ctermbg = 'NONE', ctermfg = 6,})
  vim.api.nvim_set_hl(0, 'MasonHighlightBlockBold', {ctermbg = 'NONE', ctermfg = 6, reverse = true, bold = true,})
  vim.api.nvim_set_hl(0, 'MasonMuted', {ctermbg = 'NONE', ctermfg = 'NONE',})
  vim.api.nvim_set_hl(0, 'MasonMutedBlock', {ctermbg = 'NONE', ctermfg = 15, reverse = true,})
  vim.api.nvim_set_hl(0, 'MasonError', {ctermbg = 'NONE', ctermfg = 1,})
  vim.api.nvim_set_hl(0, 'NormalFloat', {link = 'Float1Normal'})
  vim.api.nvim_set_hl(0, 'FloatBorder', {link = 'Float1Border'})
  vim.api.nvim_set_hl(0, 'LuaSnipNode', {ctermfg = 11,})
  vim.api.nvim_set_hl(0, 'WhichKeyFloat', {link = 'Float4Normal'})
  vim.api.nvim_set_hl(0, 'WhichKeyBorder', {link = 'Float4Border'})
  vim.api.nvim_set_hl(0, 'CodeActionSign', {ctermbg = 'NONE', ctermfg = 3,})
  vim.api.nvim_set_hl(0, 'LspFloatNormal', {link = 'Float2Normal'})
  vim.api.nvim_set_hl(0, 'LspFloatBorder', {link = 'Float2Border'})
  vim.api.nvim_set_hl(0, 'Float1Normal', {ctermbg = 32,})
  vim.api.nvim_set_hl(0, 'Float1Border', {link = 'Float1Normal'})
  vim.api.nvim_set_hl(0, 'Float2Normal', {ctermbg = 24,})
  vim.api.nvim_set_hl(0, 'Float2Border', {link = 'Float2Normal'})
  vim.api.nvim_set_hl(0, 'Float3Normal', {ctermbg = 8,})
  vim.api.nvim_set_hl(0, 'Float3Border', {link = 'Float3Normal'})
  vim.api.nvim_set_hl(0, 'Float4Normal', {ctermbg = 0,})
  vim.api.nvim_set_hl(0, 'Float4Border', {ctermbg = 0, ctermfg = 15,})
  vim.api.nvim_set_hl(0, 'FidgetTitle', {ctermbg = 'NONE', ctermfg = 15,italic = true,})
  vim.api.nvim_set_hl(0, 'FidgetTask', {ctermbg = 'NONE', ctermfg = 15, italic = true,})
  vim.api.nvim_set_hl(0, 'NvimTreeIndentMarker', {ctermfg = 15,})
  vim.api.nvim_set_hl(0, 'String', {ctermfg = 50,})
end
local group_id = vim.api.nvim_create_augroup('NordVim', {})
vim.api.nvim_create_autocmd(
  'ColorScheme',
  {
    pattern = 'nord',
    callback = SetNordOverrides,
    group = group_id,
  }
)
vim.api.nvim_create_autocmd(
  'User',
  {
    pattern = "PlugEndPost",
    callback = function()
      vim.cmd.colorscheme('nord')
    end,
    group = group_id,
    -- use nested so my colorscheme changes are loaded
    nested = true,
  }
)
-- }}}

-- Install Missing Plugins {{{
-- Install any plugins that have been registered in the plugfile.vim, but aren't installed
local group_id = vim.api.nvim_create_augroup('InstallMissingPlugins', {})
vim.api.nvim_create_autocmd(
  'User',
  {
    pattern = 'PlugEndPost',
    callback = function()
      local plugs = vim.g.plugs or {}
      -- Plugins registered in plugfile.vim will be in _G.registered_plugs
      local missing_plugins = {}
      for name, info in pairs(plugs) do
        local is_installed = vim.fn.isdirectory(info.dir)
        local is_registered = _G.registered_plugs[name] ~= nil
        if not is_installed and is_registered then
          missing_plugins[name] = info
        end
      end

      -- checking for empty table
      if next(missing_plugins) == nil then
        return
      end

      local missing_plugin_names={}
      for key,_ in pairs(missing_plugins) do
        table.insert(missing_plugin_names, key)
      end

      local install_prompt = string.format(
        "The following plugins are not installed:\n%s\nWould you like to install them?",
        table.concat(missing_plugin_names, ', ')
      )
      local should_install = vim.fn.confirm(install_prompt, [[yes\nno]]) == 1
      if should_install then
        vim.cmd(string.format(
          'PlugInstall --sync %s',
          table.concat(missing_plugin_names, ' ')
        ))
      end
    end,
    group = group_id,
  }
)
-- }}}

-- }}}
