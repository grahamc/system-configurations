-- vim:foldmethod=marker
-- Exit if vim is not running in a terminal (also referred to as a tty). I detect this by
-- checking if the input to vim is coming from a terminal or vim is outputting to a terminal.
local has_ttyin = vim.fn.has('ttyin') == 1
local has_ttyout = vim.fn.has('ttyout') == 1
if not has_ttyin and not has_ttyout then
  return
end

-- Miscellaneous {{{
vim.o.confirm = true
vim.o.mouse = 'a'
vim.o.scrolloff = 999
vim.o.jumpoptions = 'stack'
vim.o.mousemoveevent = true

-- persist undo history to disk
vim.o.undofile = true

local general_group_id = vim.api.nvim_create_augroup('General', {})
vim.api.nvim_create_autocmd(
  'FileType',
  {
    pattern = 'sh',
    callback = function()
      vim.opt_local.keywordprg = 'man'
    end,
    group = general_group_id,
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
    group = general_group_id,
  }
)
-- Don't highlight the word under the cursor for inactive windows
vim.api.nvim_create_autocmd(
  'WinLeave',
  {
    callback = function()
      vim.cmd('2match none')
    end,
    group = general_group_id,
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
    group = general_group_id,
  }
)
vim.api.nvim_create_autocmd(
  'QuickFixCmdPost',
  {
    pattern = 'l*',
    callback = function()
      vim.cmd.lwindow()
    end,
    group = general_group_id,
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
    group = general_group_id,
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
    group = general_group_id,
  }
)
vim.api.nvim_create_autocmd(
  'FileType',
  {
    pattern = {'qf', 'help'},
    callback = function()
      vim.opt_local.colorcolumn = ''
    end,
    group = general_group_id,
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
  local cfile = vim.fn.expand('<cfile>')
  local is_url =
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

vim.api.nvim_create_autocmd(
  'Filetype',
  {
    pattern = {'text', 'markdown', 'html', 'xhtml',},
    group = vim.api.nvim_create_augroup('NoLineLengthForMarkup', {}),
    callback = function()
      vim.opt_local.colorcolumn = '0'
    end,
  }
)
-- }}}

-- Utilities {{{
_G.unicode = function(hex)
  local hex_length = #hex
  local unicode_format_specifier = hex_length > 4 and 'U' or 'u'
  return vim.fn.execute(
    string.format(
      [[echon "\%s%s"]],
      unicode_format_specifier,
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
vim.api.nvim_create_autocmd(
  {"TextChanged", "TextChangedI",},
  {
    callback = function()
      if not is_autosave_enabled then
        return
      end

      if _G.is_autosave_job_queued then
        return
      end

      _G.is_autosave_job_queued = true
      vim.defer_fn(
        function()
          _G.is_autosave_job_queued = false
          vim.cmd("silent! wall")
        end,
        500 -- time in milliseconds between saves
      )
    end,
    group = vim.api.nvim_create_augroup('Autosave', {}),
  }
)
-- }}}

-- Windows {{{
-- open new horizontal and vertical panes to the right and bottom respectively
vim.o.splitright = true
vim.o.splitbelow = true
vim.keymap.set('n', '<Leader><Bar>', '<Cmd>vsplit<CR>')
vim.keymap.set('n', '<Leader>-', '<Cmd>split<CR>')

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

-- Automatically resize all splits to make them equal when the vim window is resized or a new window is created/closed.
vim.api.nvim_create_autocmd(
  {'VimResized', 'WinNew', 'WinClosed', 'TabEnter',},
  {
    callback = function()
      -- Don't equalize splits if the new window is floating, it won't get resized anyway.
      -- Don't equalize when vim is starting up or it will reset the window sizes from my session.
      local is_vim_starting = vim.fn.has('vim_starting') == 1
      if vim.api.nvim_win_get_config(0).relative ~= '' or is_vim_starting then
        return
      end
      vim.cmd.wincmd('=')
    end,
    group = vim.api.nvim_create_augroup('Window', {}),
  }
)

local toggle_cursor_line_group_id = vim.api.nvim_create_augroup('ToggleCursorlineWithWindowFocus', {})
vim.api.nvim_create_autocmd(
  {'FocusGained'},
  {
    callback = function() vim.o.cursorline = true end,
    group = toggle_cursor_line_group_id,
  }
)
vim.api.nvim_create_autocmd(
  {'FocusLost',},
  {
    callback = function() vim.o.cursorline = false end,
    group = toggle_cursor_line_group_id,
  }
)
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
vim.keymap.set('n', '<Tab>', function() vim.cmd([[silent! normal! za]]) end)

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
vim.o.foldcolumn = '0'

-- Jump to the top and bottom of the current fold
vim.keymap.set({'n', 'x'}, '[<Tab>', '[z')
vim.keymap.set({'n', 'x'}, ']<Tab>', ']z')

local function SetDefaultFoldMethod()
  local foldmethod = vim.o.foldmethod
  local isFoldmethodOverridable = foldmethod ~= 'marker'
    and foldmethod ~= 'diff'
    and foldmethod ~= 'expr'
  if isFoldmethodOverridable then
    vim.o.foldmethod = 'indent'
  end
end
vim.api.nvim_create_autocmd(
  'FileType',
  {
    callback = SetDefaultFoldMethod,
    group = vim.api.nvim_create_augroup('SetDefaultFoldMethod', {}),
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
    line_text = string.sub(line_text, 1, max_line_text_length)
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
vim.o.cmdheight = 0
vim.o.showcmdloc = 'statusline'
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
  -- We only want to restore/create a session if:
  --  1. neovim was called with no arguments. The first element in vim.v.argv will always be the path to the vim
  -- executable and the second will be '--embed' so if no arguments were passed to neovim, the size of vim.v.argv
  -- will be two.
  --  2. neovim's stdin is a terminal. If neovim's stdin isn't the terminal, then that means content is being
  -- piped in and we should load that instead.
  local is_neovim_called_with_no_arguments = #vim.v.argv == 2
  if is_neovim_called_with_no_arguments and has_ttyin then
    local session_name = string.gsub(vim.fn.getcwd(), '/', '%%') .. '%vim'
    vim.fn.mkdir(session_dir, 'p')
    local session_full_path = session_dir .. '/' .. session_name
    local session_full_path_escaped = vim.fn.fnameescape(session_full_path)
    if vim.fn.filereadable(session_full_path) ~= 0 then
      vim.cmd('silent source ' .. session_full_path_escaped)
    else
      vim.cmd({
        cmd = 'mksession',
        args = {session_full_path_escaped},
        bang = true,
      })
    end

    local save_session_group_id = vim.api.nvim_create_augroup('SaveSession', {})

    -- Save the session whenever the window layout or active window changes
    vim.api.nvim_create_autocmd(
      {'BufEnter',},
      {
        callback = save_session,
        group = save_session_group_id,
      }
    )

    -- save session before vim exits
    vim.api.nvim_create_autocmd(
      {'VimLeavePre',},
      {
        callback = save_session,
        group = save_session_group_id,
      }
    )
  end
end

-- Restore/create session after vim starts.
vim.api.nvim_create_autocmd(
  {'VimEnter',},
  {
    callback = restore_or_create_session,
    group = vim.api.nvim_create_augroup('RestoreOrCreateSession', {}),
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
vim.o.showtabline = 2
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

  local position = '%#StatusLine#' .. unicode('e612') .. ' %l:%c'

  local filetype = nil
  if string.len(vim.o.filetype) > 0 then
    filetype = '%#StatusLine#' .. vim.o.filetype
  end

  local fileformat = nil
  if vim.o.fileformat ~= 'unix' then
    fileformat = string.format('%%#StatusLineStandoutText#[%s]', vim.o.fileformat)
  end

  local readonly = nil
  if vim.o.readonly then
    local indicator = unicode('f0341')
    readonly = '%#StatusLineStandoutText#' .. indicator
  end

  local reg_recording = vim.fn.reg_recording()
  if reg_recording ~= '' then
    reg_recording = '%#StatusLine# ' .. '%#StatusLineRecordingIndicator#' .. unicode('f044a') .. ' %#StatusLine#REC@' .. reg_recording
  else
    reg_recording = nil
  end

  local search_info = nil
  local ok, czs = pcall(require, 'czs')
  if ok then
    if czs.display_results() then
      local _, current, count = czs.output()
      search_info = '%#StatusLine# ' .. unicode('f002') .. ' ' .. string.format("%s/%s", current, count)
    end
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
    local icon = unicode('f0159') .. ' '
    local error = '%#StatusLineErrorText#' .. icon .. error_count
    table.insert(diagnostic_list, error)
  end
  local warning_count = diagnostic_count.warning
  if warning_count > 0 then
    local icon = unicode('f0026') .. ' '
    local warning = '%#StatusLineWarningText#' .. icon  .. warning_count
    table.insert(diagnostic_list, warning)
  end
  local info_count = diagnostic_count.info
  if info_count > 0 then
    local icon = unicode('f05a') .. ' '
    local info = '%#StatusLineInfoText#' .. icon  .. info_count
    table.insert(diagnostic_list, info)
  end
  local hint_count = diagnostic_count.hint
  if hint_count > 0 then
    local icon = unicode('f0fd') .. ' '
    local hint = '%#StatusLineHintText#' .. icon  .. hint_count
    table.insert(diagnostic_list, hint)
  end
  local diagnostics = nil
  if #diagnostic_list > 0 then
    diagnostics = table.concat(diagnostic_list, ' ')
  end

  local left_side_items = {}
  local mode_map = {
    ['n']      = 'NORMAL',
    ['no']     = 'O-PENDING',
    ['nov']    = 'O-PENDING',
    ['noV']    = 'O-PENDING',
    ['no\22'] = 'O-PENDING',
    ['niI']    = 'NORMAL',
    ['niR']    = 'NORMAL',
    ['niV']    = 'NORMAL',
    ['nt']     = 'NORMAL',
    ['ntT']    = 'NORMAL',
    ['v']      = 'VISUAL',
    ['vs']     = 'VISUAL',
    ['V']      = 'V-LINE',
    ['Vs']     = 'V-LINE',
    ['\22']   = 'V-BLOCK',
    ['\22s']  = 'V-BLOCK',
    ['s']      = 'SELECT',
    ['S']      = 'S-LINE',
    ['\19']   = 'S-BLOCK',
    ['i']      = 'INSERT',
    ['ic']     = 'INSERT',
    ['ix']     = 'INSERT',
    ['R']      = 'REPLACE',
    ['Rc']     = 'REPLACE',
    ['Rx']     = 'REPLACE',
    ['Rv']     = 'V-REPLACE',
    ['Rvc']    = 'V-REPLACE',
    ['Rvx']    = 'V-REPLACE',
    ['c']      = 'COMMAND',
    ['cv']     = 'EX',
    ['ce']     = 'EX',
    ['r']      = 'REPLACE',
    ['rm']     = 'MORE',
    ['r?']     = 'CONFIRM',
    ['!']      = 'SHELL',
    ['t']      = 'TERMINAL',
  }
  local mode = mode_map[vim.api.nvim_get_mode().mode]
  if mode == nil then
    mode = '?'
  end
  local function make_highlight_names(name)
    return {
      mode = '%#' .. string.format('StatusLineMode%s', name) .. '#',
      inner = '%#' .. string.format('StatusLineMode%sPowerlineInner', name) .. '#',
      outer = '%#' .. string.format('StatusLineMode%sPowerlineOuter', name) .. '#',
    }
  end
  local highlights = make_highlight_names('Other')
  local function startswith(text, prefix)
    return text:find(prefix, 1, true) == 1
  end
  if startswith(mode, 'V') then
    highlights = make_highlight_names('Visual')
  elseif startswith(mode, 'I') then
    highlights = make_highlight_names('Insert')
  elseif startswith(mode, 'N') then
    highlights = make_highlight_names('Normal')
  elseif startswith(mode, 'T') then
    highlights = make_highlight_names('Terminal')
  end
  local mode_indicator = highlights.outer .. unicode('e0b6') .. highlights.mode .. ' ' .. mode .. ' ' .. highlights.inner .. unicode('e0b4')
  table.insert(left_side_items, mode_indicator)
  if filetype then
    table.insert(left_side_items, filetype)
  end
  if fileformat then
    table.insert(left_side_items, fileformat)
  end
  if readonly then
    table.insert(left_side_items, readonly)
  end
  if reg_recording then
    table.insert(left_side_items, reg_recording)
  end
  if search_info then
    table.insert(left_side_items, search_info)
  end
  local left_side = table.concat(left_side_items, ' ')

  local right_side_items = {}
  if diagnostics then
    table.insert(right_side_items, diagnostics)
  end
  table.insert(right_side_items, position)
  local right_side = table.concat(right_side_items, item_separator)

  local showcmd = '%#StatusLineShowcmd#%S'
  local statusline_separator = '%#StatusLine# %=' .. showcmd .. '%#StatusLine#%= '

  local padding = '%#StatusLine# '
  local statusline = left_side .. statusline_separator .. right_side .. padding .. '%#StatusLinePowerlineOuter#' .. unicode('e0b4')

  return statusline
end

vim.o.laststatus = 3
vim.o.statusline = '%!v:lua.StatusLine()'
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

local cursor_group_id = vim.api.nvim_create_augroup('Cursor', {})
vim.api.nvim_create_autocmd(
  {'VimLeave', 'VimSuspend',},
  {
    callback = reset_cursor,
    group = cursor_group_id,
  }
)
vim.api.nvim_create_autocmd(
  {'VimResume',},
  {
    callback = set_cursor,
    group = cursor_group_id,
  }
)
-- }}}

-- }}}

-- LSP {{{
vim.diagnostic.config({
  virtual_text = true,
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
-- }}}

-- Terminal {{{
vim.api.nvim_create_autocmd(
  "TermOpen",
  {
    callback = function()
      vim.o.showtabline = 0
      vim.opt_local.number = false
      vim.opt_local.relativenumber = false
      vim.opt_local.cursorline = false
      vim.cmd.startinsert()
    end,
  }
)
vim.api.nvim_create_autocmd(
  "TermClose",
  {
    callback = function()
      vim.o.showtabline = 1
      vim.cmd.bdelete({
        args = {vim.fn.expand('<abuf>')},
        bang = true,
      })
    end,
  }
)
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
        -- Don't add bracket pairs after quote.
        enable_afterquote = false,
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

      vim.api.nvim_create_autocmd(
        {'BufWinEnter', 'VimResized',},
        {
          callback = function() vim.cmd.VirtColumnRefresh() end,
          group = vim.api.nvim_create_augroup('MyVirtColumn', {}),
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
      local telescope = require('telescope')
      local actions = require('telescope.actions')
      local resolve = require('telescope.config.resolve')

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
          results_title = '(C-q: quickfix, C-{v,h}: vertical/horizontal split)',
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
      -- Outside TMUX the above won't work, I have to use <C-/>, so I just map both.
      vim.keymap.set('n', '<C-/>', '<Cmd>Telescope commands<CR>')
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
            layout_config = {
              height = 6,
            },
          }),
          get_config = function(options)
            if options.kind == 'mason.ui.language-filter' then
              return {
                telescope = {
                  layout_strategy = 'center',
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
        local foldmethod = vim.o.foldmethod
        local is_foldmethod_overridable = foldmethod ~= 'manual'
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
          -- This is how the docs say it should be called.
          -- docs: https://github.com/JoosepAlviste/nvim-ts-context-commentstring/wiki/Integrations#nvim-comment
          ---@diagnostic disable-next-line: missing-parameter
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
          text = unicode('f0335'),
          texthl = 'CodeActionSign',
        }
      )
    end,
  }
)

Plug(
  'oncomouse/czs.nvim',
  {
    config = function()
      -- 'n' always searches forwards, 'N' always searches backwards
      -- I have this set in base.lua, but since I need to use these czs mappings I had to redefine them.
      vim.keymap.set({'n'}, 'n', "['<Plug>(czs-move-N)', '<Plug>(czs-move-n)'][v:searchforward]", {expr = true, replace_keycodes = false,})
      vim.keymap.set({'x'}, 'n', "['<Plug>(czs-move-N)', '<Plug>(czs-move-n)'][v:searchforward]", {expr = true, replace_keycodes = false,})
      vim.keymap.set({'o'}, 'n', "['<Plug>(czs-move-N)', '<Plug>(czs-move-n)'][v:searchforward]", {expr = true, replace_keycodes = false,})
      vim.keymap.set({'n'}, 'N', "['<Plug>(czs-move-n)', '<Plug>(czs-move-N)'][v:searchforward]", {expr = true, replace_keycodes = false,})
      vim.keymap.set({'x'}, 'N', "['<Plug>(czs-move-n)', '<Plug>(czs-move-N)'][v:searchforward]", {expr = true, replace_keycodes = false,})
      vim.keymap.set({'o'}, 'N', "['<Plug>(czs-move-n)', '<Plug>(czs-move-N)'][v:searchforward]", {expr = true, replace_keycodes = false,})
    end,
  }
)
vim.g.czs_do_not_map = true

Plug(
  'akinsho/bufferline.nvim',
  {
    config = function()
      local function close(buffer)
        -- If this is the last window and tab, close the buffer and if that was the last buffer, close vim.
        local window_count = vim.fn.winnr('$')
        local tab_count = vim.fn.tabpagenr('$')
        if tab_count == 1 and (window_count == 1 or (window_count == 2 and require('nvim-tree.api').tree.is_visible())) then
          local buffer_count_before_closing = #vim.fn.getbufinfo({buflisted = 1,})
          vim.cmd('bdelete! ' .. buffer)
          if buffer_count_before_closing == 1 then
            vim.cmd.quit()
          end
          return
        end

        -- If the buffer is only open in the current window, close the buffer and window. Otherwise just close
        -- the window.
        local buffer_window_count = #vim.fn.win_findbuf(buffer)
        if buffer_window_count == 1 then
          vim.cmd('bdelete! ' .. buffer)
        else
          vim.cmd.close()
        end

      end

      local close_icon = unicode('f467')
      local separator_icon = ' │ '
      require("bufferline").setup({
        options = {
          numbers = function(context) return context.raise(context.ordinal) end,
          indicator= { style = 'none', },
          close_icon = close_icon,
          close_command = close,
          buffer_close_icon = close_icon,
          separator_style = {separator_icon, separator_icon,},
          modified_icon = close_icon,
          offsets = {
            {
              filetype = "NvimTree",
              text = unicode('f4d3') .. " File Explorer",
              text_align = "center",
              separator = true,
              highlight = 'Normal',
            },
          },
          hover = {
            enabled = true,
            delay = 50,
            reveal = {'close'},
          },
          themable = true,
          max_name_length = 100,
          max_prefix_length = 100,
          tab_size = 1,
        },
        highlights = {
          fill = { ctermbg = 8, ctermfg = 15, },
          background = { ctermbg = 8, ctermfg = 15, },
          buffer_visible = { ctermbg = 8, ctermfg = 15, },
          buffer_selected = { ctermbg = 8, ctermfg = 'NONE', italic = false, },
          duplicate = { ctermbg = 8, ctermfg = 15, italic = false,},
          duplicate_selected = { ctermbg = 8, ctermfg = 'None', italic = false,},
          duplicate_visible = { ctermbg = 8, ctermfg = 15, italic = false,},
          numbers = { ctermbg = 8, ctermfg = 15, italic = false,},
          numbers_visible = { ctermbg = 8, ctermfg = 15, italic = false,},
          numbers_selected = { ctermbg = 8, ctermfg = 6, italic = false,},
          close_button = { ctermbg = 8, ctermfg = 15, },
          close_button_selected = { ctermbg = 8, ctermfg = 'None', },
          close_button_visible = { ctermbg = 8, ctermfg = 15, },
          modified = { ctermbg = 8, ctermfg = 15, },
          modified_selected = { ctermbg = 8, ctermfg = 'None', },
          modified_visible = { ctermbg = 8, ctermfg = 'None', },
          tab = { ctermbg = 8, ctermfg = 15, bold = true, },
          tab_selected = { ctermbg = 8, ctermfg = 6, bold = true, underline = true, },
          tab_separator = { ctermbg = 8, ctermfg = 8, },
          tab_separator_selected = { ctermbg = 8, ctermfg = 8, },
          tab_close = { ctermbg = 8, ctermfg = 'NONE', bold = true,},
          offset_separator = { ctermbg = 'NONE', ctermfg = 15, },
          separator = { ctermbg = 8, ctermfg = 0, },
          separator_visible = { ctermbg = 8, ctermfg = 0, },
          separator_selected = { ctermbg = 8, ctermfg = 0, },
          indicator_selected = { ctermbg = 8, ctermfg = 8, },
          indicator_visible = { ctermbg = 8, ctermfg = 8, },
        },
      })

      vim.keymap.set({'n', 'i'}, '<F7>', vim.cmd.BufferLineCyclePrev, {silent = true})
      vim.keymap.set({'n', 'i'}, '<F8>', vim.cmd.BufferLineCycleNext, {silent = true})

      -- Switch buffers with <Leader><tab number>
      for buffer_index=1,9 do
        vim.keymap.set('n', '<Leader>' .. buffer_index, function() require("bufferline").go_to(buffer_index, true) end)
      end

      vim.keymap.set('n', '<C-q>', function() close(vim.fn.bufnr()) end, {silent = true,})
      function BufferlineWrapper()
        local original = nvim_bufferline()
        if string.find(original, unicode('f4d3')) then
          local x = string.gsub(original, '│', '│' .. '%%#TabLineBorder#' .. unicode('e0b6'), 1) .. '%#TabLineBorder#' .. unicode('e0b4')
          if string.sub(original, -2, -1) ~= '%=' then
            x = string.gsub(x, '%=', '%=' .. '%%#TabLineBorder2#' .. unicode('e0b7'), 1)
          end
          return x
        else
          local x = '%#TabLineBorder#' .. unicode('e0b6') .. original .. '%#TabLineBorder#' .. unicode('e0b4')
          if string.sub(original, -2, -1) ~= '%=' then
            x = string.gsub(x, '%=', '%=' .. '%%#TabLineBorder2#' .. unicode('e0b7'), 1)
          end
          return x
        end
      end
      vim.o.tabline = '%!v:lua.BufferlineWrapper()'
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
          width = function() return math.max(30, math.floor(vim.o.columns * .20)) end,
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

      local function configure_nvim_tree_window()
        if vim.o.filetype ~= 'NvimTree' then
          return
        end

        vim.opt_local.winbar = '%=%#Normal# Press %#ExplorerHint#g?%#Normal# for help%='
      end
      vim.api.nvim_create_autocmd(
        {'BufWinEnter',},
        {
          callback = configure_nvim_tree_window,
          -- nvim-tree has an augroup named 'NvimTree' so I have to use a different name
          group = vim.api.nvim_create_augroup('__NvimTree', {}),
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
      require('luasnip.loaders.from_vscode').lazy_load()
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
          format = function(_, vim_item)
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
          ["<C-h>"] = cmp.mapping(function(_)
            if luasnip.jumpable(-1) then
              luasnip.jump(-1)
            end
          end, { 'i', 's' }),
          ["<C-l>"] = cmp.mapping(function(_)
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
          -- Ideally I'd use a function here so I could set it to '<screen_height> - 1', but this field doesn't support
          -- functions.
          height = 1,
          icons = {
            package_installed = unicode('f0133') .. '  ',
            package_pending = unicode('f251') .. '  ',
            package_uninstalled = unicode('f0766') .. '  ',
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
      local lspconfig = require('lspconfig')

      local on_attach = function(client, buffer_number)
        local capabilities = client.server_capabilities
        local buffer_keymap = vim.api.nvim_buf_set_keymap
        local keymap_opts = { noremap = true, silent = true }

        local foldmethod = vim.o.foldmethod
        local isFoldmethodOverridable = foldmethod ~= 'marker'
          and foldmethod ~= 'diff'
          and foldmethod ~= 'expr'
        if capabilities.foldingRangeProvider and isFoldmethodOverridable then
          -- folding-nvim prints a message if any attached language server does not support folding so I'm suppressing
          -- that.
          vim.cmd([[silent lua require('folding').on_attach()]])
        end

        local filetype = vim.o.filetype
        local isKeywordprgOverridable = filetype ~= 'vim' and filetype ~= 'sh'
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

      local cmp_lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()
      local folding_capabilities = {
        textDocument = {
          foldingRange = {
            dynamicRegistration = false,
            lineFoldingOnly = true,
          },
        },
      }
      local capabilities = vim.tbl_deep_extend(
        'error',
        cmp_lsp_capabilities,
        folding_capabilities
      )

      local default_server_config = {
        capabilities = capabilities,
        on_attach = on_attach,
      }

      -- Don't include my configs in the library. Otherwise when I'm working on my dotfiles those files will appear
      -- twice and lua will tell me my global variables are being redefined.
      local neovim_lua_library_directories = vim.api.nvim_get_runtime_file("", true)
      for index,directory in ipairs(neovim_lua_library_directories) do
        if directory == vim.fn.stdpath('config') then
          neovim_lua_library_directories[index] = nil
        end
      end
      local server_specific_configs = {
        jsonls = {
          settings = {
            json = {
              schemas = require('schemastore').json.schemas(),
              validate = { enable = true },
            },
          },
        },

        lua_ls = {
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
                library = neovim_lua_library_directories,
                checkThirdParty = false,
              },
              telemetry = {
                -- Do not send telemetry data containing a randomized but unique identifier
                enable = false,
              },
            },
          },
        },

        lemminx = {
          settings = {
            xml = {
              catalogs = {'/etc/xml/catalog'},
            },
          },
        },

        vale_ls = {
          filetypes = {
            -- NOTE: This should have all of the programming languages listed here:
            -- https://vale.sh/docs/topics/scoping/#code-1
            'c', 'cs', 'cpp', 'css', 'go', 'haskell', 'java', 'javascript', 'less', 'lua', 'perl', 'php',
            'python', 'r', 'ruby', 'sass', 'scala', 'swift',
          },
        },
      }

      local server_config_handlers = {}
      -- Default handler to be called for each installed server that doesn't have a dedicated handler.
      server_config_handlers[1] = function (server_name)
        lspconfig[server_name].setup(default_server_config)
      end
      -- server-specific handlers
      for server_name,server_specific_config in pairs(server_specific_configs) do
        server_config_handlers[server_name] = function()
          lspconfig[server_name].setup(vim.tbl_deep_extend('force', default_server_config, server_specific_config))
        end
      end
      require("mason-lspconfig").setup_handlers(server_config_handlers)

      -- Set the filetype of all the currently open buffers to trigger a 'FileType' event for each buffer so nvim_lsp
      -- has a chance to attach to any buffers that were openeed before it was configured.
      local buffer = vim.fn.bufnr()
      vim.cmd([[
        silent! bufdo silent! lua vim.o.filetype = vim.o.filetype
      ]])
      vim.cmd.b(buffer)
    end,
  }
)

Plug(
  'neovim/nvim-lspconfig',
  {
    config = function()
      require('lspconfig.ui.windows').default_options.border = 'solid'
    end,
  }
)

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
          builtins.diagnostics.actionlint,
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
  vim.api.nvim_set_hl(0, 'TabLineBorder', {ctermbg = 'NONE', ctermfg = 8,})
  vim.api.nvim_set_hl(0, 'TabLineBorder2', {ctermbg = 8, ctermfg = 0,})
  -- The TabLine* highlights are the so the tabline looks blank before bufferline populates it so it needs the same
  -- background color as bufferline. The foreground needs to match the background so you can't see the text from the
  -- original tabline function.
  vim.api.nvim_set_hl(0, 'TabLine', {ctermbg = 8, ctermfg = 8,})
  vim.api.nvim_set_hl(0, 'TabLineFill', {link = 'TabLine'})
  vim.api.nvim_set_hl(0, 'TabLineSel', {link = 'TabLine'})
  vim.api.nvim_set_hl(0, 'ExplorerHint', {ctermbg = 'NONE', ctermfg = 6,})
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
  vim.api.nvim_set_hl(0, 'MasonNormal', {link = 'Float4Normal'})
  vim.api.nvim_set_hl(0, 'NormalFloat', {link = 'Float1Normal'})
  vim.api.nvim_set_hl(0, 'FloatBorder', {link = 'Float1Border'})
  vim.api.nvim_set_hl(0, 'LuaSnipNode', {ctermfg = 11,})
  vim.api.nvim_set_hl(0, 'WhichKeyFloat', {link = 'Float4Normal'})
  vim.api.nvim_set_hl(0, 'WhichKeyBorder', {link = 'Float4Border'})
  vim.api.nvim_set_hl(0, 'CodeActionSign', {ctermbg = 'NONE', ctermfg = 3,})
  vim.api.nvim_set_hl(0, 'LspInfoBorder', {link = 'Float1Border'})
  vim.api.nvim_set_hl(0, 'Float1Normal', {ctermbg = 16,})
  vim.api.nvim_set_hl(0, 'Float1Border', {link = 'Float1Normal'})
  vim.api.nvim_set_hl(0, 'Float2Normal', {ctermbg = 24,})
  vim.api.nvim_set_hl(0, 'Float2Border', {link = 'Float2Normal'})
  vim.api.nvim_set_hl(0, 'Float3Normal', {ctermbg = 8,})
  vim.api.nvim_set_hl(0, 'Float3Border', {link = 'Float3Normal'})
  vim.api.nvim_set_hl(0, 'Float4Normal', {ctermbg = 'NONE',})
  vim.api.nvim_set_hl(0, 'Float4Border', {ctermbg = 'NONE', ctermfg = 15,})
  vim.api.nvim_set_hl(0, 'String', {ctermfg = 50,})
  vim.api.nvim_set_hl(0, 'StatusLineRecordingIndicator', {ctermbg = 8, ctermfg = 1,})
  vim.api.nvim_set_hl(0, 'StatusLineShowcmd', {ctermbg = 8, ctermfg = 6,})
  vim.api.nvim_set_hl(0, 'StatusLinePowerlineOuter', {ctermbg = 'NONE', ctermfg = 8,})
  vim.api.nvim_set_hl(0, 'NvimTreeWinBar', {ctermfg = 6, ctermbg = 8,})
  vim.api.nvim_set_hl(0, 'NvimTreeIndentMarker', {ctermfg = 15,})
  vim.api.nvim_set_hl(0, 'MsgArea', {link = 'StatusLine',})
  local mode_highlights = {
    {mode = 'Normal', color = 'NONE',},
    {mode = 'Visual', color = 3,},
    {mode = 'Insert', color = 6,},
    {mode = 'Terminal', color = 2,},
    {mode = 'Other', color = 4,},
  }
  for _, highlight in pairs(mode_highlights) do
    local mode = highlight.mode
    local color = highlight.color
    vim.api.nvim_set_hl(0, string.format('StatusLineMode%s', mode), {ctermbg = 'NONE', ctermfg = color, reverse = true, bold = true,})
    vim.api.nvim_set_hl(0, string.format('StatusLineMode%sPowerlineOuter', mode), {ctermbg = 'NONE', ctermfg = color,})
    vim.api.nvim_set_hl(0, string.format('StatusLineMode%sPowerlineInner', mode), {ctermbg = 8, ctermfg = color,})
  end
end
local nord_vim_group_id = vim.api.nvim_create_augroup('NordVim', {})
vim.api.nvim_create_autocmd(
  'ColorScheme',
  {
    pattern = 'nord',
    callback = SetNordOverrides,
    group = nord_vim_group_id,
  }
)
vim.api.nvim_create_autocmd(
  'User',
  {
    pattern = "PlugEndPost",
    callback = function()
      -- Normally my plugin configuration code is inside a `config` function in the plugin definition, but I need
      -- this loaded earlier so you don't see a flash of the default colorscheme and then mine. I use `pcall` so
      -- that even if the colorscheme doesn't exist, an error won't be printed.
      pcall(vim.cmd.colorscheme, 'nord')
    end,
    group = nord_vim_group_id,
    -- use nested so my colorscheme changes are loaded
    nested = true,
  }
)
-- }}}

-- Install Missing Plugins {{{
-- Install any plugins that have been registered in the plugfile.vim, but aren't installed
vim.api.nvim_create_autocmd(
  'User',
  {
    pattern = 'PlugEndPost',
    callback = function()
      local plugs = vim.g.plugs or {}
      -- Plugins registered in plugfile.vim will be in _G.registered_plugs
      local missing_plugins = {}
      for name, info in pairs(plugs) do
        local is_installed = vim.fn.isdirectory(info.dir) ~= 0
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
      local should_install = vim.fn.confirm(install_prompt, "yes\nno") == 1
      if should_install then
        vim.cmd(string.format(
          'PlugInstall --sync %s',
          table.concat(missing_plugin_names, ' ')
        ))
      end
    end,
    group = vim.api.nvim_create_augroup('InstallMissingPlugins', {}),
  }
)
-- }}}

-- }}}
