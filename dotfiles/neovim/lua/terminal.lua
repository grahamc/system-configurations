-- vim:foldmethod=marker

-- This is so I can assign variables to `vim.b`
---@diagnostic disable: inject-field

-- Exit if vim is not running in a terminal (also referred to as a TTY). I detect this by
-- checking if the input to vim is coming from a terminal or vim is outputting to a terminal.
local has_ttyin = vim.fn.has("ttyin") == 1
local has_ttyout = vim.fn.has("ttyout") == 1
if not has_ttyin and not has_ttyout then
  return
end

-- Miscellaneous {{{
vim.o.confirm = true
vim.o.mouse = "a"
vim.o.scrolloff = 999
vim.o.jumpoptions = "stack"
vim.o.mousemoveevent = true

-- persist undo history to disk
vim.o.undofile = true

local general_group_id = vim.api.nvim_create_augroup("General", {})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "sh",
  callback = function()
    vim.opt_local.keywordprg = "man"
  end,
  group = general_group_id,
})
-- Put focus back in quickfix window after opening an entry
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "<CR>", "<CR><C-W>p", { buffer = true })
  end,
  group = general_group_id,
})
vim.api.nvim_create_autocmd(
  -- I'm using BufEnter as opposed to FileType because if you run `:help something` and the help buffer is already
  -- open, vim will reset the buffer to not being listed so to get around that I set it back every time I enter the buffer.
  "BufEnter",
  {
    callback = function()
      if vim.o.filetype == "help" then
        -- so it shows up in the bufferline
        vim.opt_local.buflisted = true
      end
    end,
    group = general_group_id,
  }
)
-- Get help buffers to open in the current window by first opening it in a new tab (this is done elsewhere in my config),
-- closing the tab and jumping to the previous buffer, the help buffer.
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    if vim.o.filetype == "help" and vim.g.opening_help_in_tab ~= nil then
      vim.g.opening_help_in_tab = nil
      -- Calling `tabclose` here doesn't work without `defer_fn`, not sure why though.
      vim.defer_fn(function()
        local help_buffer_number = vim.fn.bufnr()
        vim.cmd.tabclose()
        vim.cmd.buffer(help_buffer_number)
      end, 0)
    end
  end,
  group = general_group_id,
})

vim.keymap.set("", "<C-x>", "<Cmd>xa<CR>")

-- suspend vim
vim.keymap.set({ "n", "i", "x" }, "<C-z>", "<Cmd>suspend<CR>")

-- colorcolumn
local colorcolumn_group_id = vim.api.nvim_create_augroup("ColorColumn", {})
vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "readonly",
  callback = function()
    if vim.v.option_new then
      vim.wo.colorcolumn = ""
    end
  end,
  group = colorcolumn_group_id,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "qf", "help" },
  callback = function()
    vim.wo.colorcolumn = ""
  end,
  group = colorcolumn_group_id,
})
vim.api.nvim_create_autocmd("WinLeave", {
  pattern = "*",
  callback = function()
    vim.w.old_colorcolumn = vim.wo.colorcolumn
    vim.wo.colorcolumn = ""
  end,
  group = colorcolumn_group_id,
})
vim.api.nvim_create_autocmd("WinEnter", {
  pattern = "*",
  callback = function()
    if vim.w.old_colorcolumn then
      vim.wo.colorcolumn = vim.w.old_colorcolumn
    end
  end,
  group = colorcolumn_group_id,
})
vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function()
    vim.wo.colorcolumn = tostring(_G.GetMaxLineLength() + 1)
    vim.w.old_colorcolumn = vim.wo.colorcolumn
  end,
  group = colorcolumn_group_id,
})

vim.o.shell = "sh"

vim.keymap.set("n", "<BS>", "<C-^>")

vim.o.ttimeout = true
vim.o.ttimeoutlen = 50

-- Open link on mouse click. Works on URLs that wrap on to the following line.
function ClickLink()
  local cfile = vim.fn.expand("<cfile>")
  local is_url = cfile:match(
    "https?://(([%w_.~!*:@&+$/?%%#-]-)(%w[-.%w]*%.)(%w%w%w?%w?)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))"
  ) or cfile:match(
    "ftps?://(([%w_.~!*:@&+$/?%%#-]-)(%w[-.%w]*%.)(%w%w%w?%w?)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))"
  )
  if is_url then
    vim.fn.jobstart({ "open", cfile }, { detach = true })
  end

  -- If we are in a float that doesn't have a filetype, jump back to previous window. This way I can
  -- click a link in a documentation/diagnostic float and stay in the editing window.
  local is_float = vim.api.nvim_win_get_config(0).relative ~= ""
  if is_float and (not vim.o.filetype or #vim.o.filetype == 0) then
    vim.cmd.wincmd("p")
  end
end
vim.keymap.set("n", "<C-LeftMouse>", "<LeftMouse><Cmd>lua ClickLink()<CR>")

vim.o.scroll = 1

vim.keymap.set("n", "|", "<Cmd>set list!<CR>", { silent = true })

vim.o.shortmess = "filnxtToOFs"

-- I have a mapping in my terminal for <C-i> that sends F9 to get around the fact that TMUX
-- considers <C-i> the same as <Tab> right now since TMUX lost support for extended keys.
-- TODO: tmux issue: https://github.com/tmux/tmux/issues/2705#issuecomment-841133549
vim.keymap.set({ "n" }, "<F9>", "<C-i>")

-- Use shift+u to redo the last undone change
vim.keymap.set({ "n" }, "<S-u>", "<C-r>")
-- }}}

-- Quickfix {{{
local function toggle_quickfix()
  local qf_exists = false
  for _, win in pairs(vim.fn.getwininfo()) do
    if win["quickfix"] == 1 then
      qf_exists = true
    end
  end
  if qf_exists == true then
    vim.cmd("cclose")
    return
  end
  if not vim.tbl_isempty(vim.fn.getqflist()) then
    vim.cmd("copen")
  end
end
vim.keymap.set("n", "<M-q>", toggle_quickfix)
-- }}}

-- Utilities {{{
local function set_jump_before(fn)
  return function(...)
    vim.cmd([[
      normal! m'
    ]])
    fn(...)
  end
end
-- }}}

-- System Theme Synchronization {{{
---@diagnostic disable-next-line: unused-function, unused-local
local function get_system_theme()
  local path = (os.getenv("XDG_STATE_HOME") or os.getenv("HOME") .. "/.local/state")
    .. "/wezterm/current-theme.txt"
  local file_exists = vim.fn.filereadable(path) ~= 0
  if file_exists then
    return vim.fn.readfile(path)[1]
  end
  return "dark"
end

---@diagnostic disable-next-line: unused-function, unused-local
local function listen_for_system_theme_changes()
  local run_path = (os.getenv("XDG_RUNTIME_DIR") or os.getenv("TMPDIR") or "/tmp")
    .. "/nvim-wezterm/pipes"
  vim.fn.mkdir(run_path, "p")
  local pipe_file = vim.trim(vim.fn.system(string.format([[TMPDIR='%s' mktemp -u]], run_path)))
  vim.fn.serverstart(pipe_file)
  vim.api.nvim_create_autocmd("User", {
    pattern = "ColorSchemeDark",
    callback = function()
      vim.o.background = "dark"
    end,
    nested = true,
  })
  vim.api.nvim_create_autocmd("User", {
    pattern = "ColorSchemeLight",
    callback = function()
      vim.o.background = "light"
    end,
    nested = true,
  })
end

-- TODO: Forcing dark mode since devicons looks best in dark mode when using 256 colors. If I ever
-- switch to termguicolors I can remove this.
vim.o.background = "dark"
-- nord sets the background on startup so this will overwrite that. I wanted to use 'OptionSet', but this works too.
-- vim.api.nvim_create_autocmd(
--   'ColorScheme',
--   {
--     pattern = 'nord',
--     callback = function()
--       vim.o.background = get_system_theme()
--     end,
--     nested = true,
--     once = true,
--   }
-- )
-- listen_for_system_theme_changes()
-- }}}

-- Autosave {{{
_G.is_autosave_task_queued = false
local function save()
  _G.is_autosave_task_queued = false
  vim.cmd("silent! update")
end
local function enqueue_save_task()
  if _G.is_autosave_task_queued then
    return
  end

  _G.is_autosave_task_queued = true
  vim.defer_fn(
    save,
    500 -- time in milliseconds between saves
  )
end
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  callback = enqueue_save_task,
  group = vim.api.nvim_create_augroup("Autosave", {}),
})
-- }}}

-- Windows {{{
-- open new horizontal and vertical panes to the right and bottom respectively
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.winminheight = 0
vim.o.winminwidth = 0
vim.keymap.set("n", "<Leader><Bar>", "<Cmd>vsplit<CR>")
vim.keymap.set("n", "<Leader>-", "<Cmd>split<CR>")
vim.keymap.set("n", "<C-w>", vim.cmd.close)

local window_group_id = vim.api.nvim_create_augroup("Window", {})

-- Automatically resize all splits to make them equal when the vim window is resized or a new window
-- is created/closed.
vim.api.nvim_create_autocmd({ "VimResized", "WinNew", "WinClosed", "TabEnter" }, {
  callback = function()
    -- Don't equalize splits if the new window is floating, it won't get resized anyway.
    -- Don't equalize when vim is starting up so it doesn't reset the window sizes from my session.
    local is_vim_starting = vim.fn.has("vim_starting") == 1
    local is_float = vim.api.nvim_win_get_config(0).relative ~= ""
    if is_float or is_vim_starting then
      return
    end
    vim.cmd.wincmd("=")
  end,
  group = window_group_id,
})

-- TODO: This won't work until I use a release of neovim that has this fix, right now it's only on
-- nightly: https://github.com/neovim/neovim/pull/25096
vim.api.nvim_create_autocmd({ "WinNew" }, {
  callback = function()
    local is_float = vim.api.nvim_win_get_config(0).relative ~= ""
    if is_float then
      local ok, reticle = pcall(require, "reticle")
      if ok then
        reticle.disable_cursorline()
      end
    end
  end,
  group = window_group_id,
})

local toggle_cursor_line_group_id =
  vim.api.nvim_create_augroup("ToggleCursorlineWithWindowFocus", {})
vim.api.nvim_create_autocmd({ "FocusGained" }, {
  callback = function()
    pcall(require("reticle").enable_cursorline)
  end,
  group = toggle_cursor_line_group_id,
})
vim.api.nvim_create_autocmd({ "FocusLost" }, {
  callback = function()
    pcall(require("reticle").disable_cursorline)
  end,
  group = toggle_cursor_line_group_id,
})

-- Resize windows
vim.keymap.set({ "n" }, "<C-Left>", [[<Cmd>vertical resize +1<CR>]], { silent = true })
vim.keymap.set({ "n" }, "<C-Right>", [[<Cmd>vertical resize -1<CR>]], { silent = true })
vim.keymap.set({ "n" }, "<C-Up>", [[<Cmd>resize +1<CR>]], { silent = true })
vim.keymap.set({ "n" }, "<C-Down>", [[<Cmd>resize -1<CR>]], { silent = true })
-- }}}

-- Tabs {{{
vim.keymap.set({ "n", "i" }, "<C-M-[>", vim.cmd.tabprevious, { silent = true })
vim.keymap.set({ "n", "i" }, "<C-M-]>", vim.cmd.tabnext, { silent = true })
-- }}}

-- Pager (https://github.com/I60R/page) {{{
-- String that will be appended to the buffer name
-- TODO: `page` adds quotations around these strings and I want to remove them
vim.g.page_icon_pipe = "(reading from pipe)" -- When piped
vim.g.page_icon_redirect = "(reading from stdin)" -- When exposes pty device
vim.g.page_icon_instance = "(reading from instance)" -- When `-i, -I` flags provided

local function disable_winbar()
  vim.o.winbar = ""
end

local function reset_cursor_position()
  -- TODO: `page` doesn't offer a way to disable the centering of the cursor so I'm using an
  -- autocommand to reset the cursor after it's centered. For more info on why `page` centers the
  -- cursor see: https://github.com/I60R/page/issues/16
  local pager_group_id = vim.api.nvim_create_augroup("Pager", {})
  vim.api.nvim_create_autocmd("CursorMoved", {
    callback = function()
      local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
      -- I assume the cursor is centered if the row is more than one. I tried to calculate the
      -- middle row to have a more accurate check, but occasionally I would be off by one. I can't
      -- imagine where else `page` would move the cursor besides the center so this should be ok.
      --
      -- I also tried assuming that the first cursor movement made must be the centering of the
      -- cursor, but the event would fire a few times before the cursor was centered, though the
      -- cursor position wouldn't change.
      local is_cursor_centered_vertically = cursor_row > 1
      if is_cursor_centered_vertically then
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        vim.api.nvim_clear_autocmds({ group = pager_group_id })
      end
    end,
    group = pager_group_id,
  })
end

-- Will run once when the pager opens
vim.api.nvim_create_autocmd("User", {
  pattern = "PageOpen",
  callback = function()
    disable_winbar()
    reset_cursor_position()
    vim.o.showtabline = 0
  end,
})
-- }}}

-- Indentation {{{
vim.o.expandtab = true
vim.o.autoindent = true
vim.o.smarttab = true
-- Round indent to multiple of shiftwidth (applies to < and >)
vim.o.shiftround = true
local tab_width = 2
vim.o.tabstop = tab_width
vim.o.shiftwidth = tab_width
vim.o.softtabstop = tab_width
-- }}}

-- Folds {{{
vim.o.foldlevelstart = 99
vim.opt.fillchars:append("fold: ")
vim.keymap.set("n", "<Tab>", function()
  vim.cmd([[silent! normal! za]])
end)

-- Setting this so that the fold column gets displayed
vim.o.foldenable = true

-- Set max number of nested folds when 'foldmethod' is 'syntax' or 'indent'
vim.o.foldnestmax = 1

-- Minimum number of lines a fold must have to be able to be closed
vim.o.foldminlines = 1

-- Fold visually selected lines. 'foldmethod' must be set to 'manual' for this work.
vim.keymap.set("x", "Tab", "zf")

-- Toggle opening and closing all folds
local function fold_toggle()
  if vim.o.foldlevel > 0 then
    return "zM"
  else
    return "zR"
  end
end
vim.keymap.set("n", "<S-Tab>", fold_toggle, { silent = true, expr = true })

-- Jump to the top and bottom of the current fold
vim.keymap.set({ "n", "x" }, "[<Tab>", "[z")
vim.keymap.set({ "n", "x" }, "]<Tab>", "]z")

local function SetDefaultFoldMethod()
  local foldmethod = vim.o.foldmethod
  local isFoldmethodOverridable = foldmethod ~= "marker"
    and foldmethod ~= "diff"
    and foldmethod ~= "expr"
  if isFoldmethodOverridable then
    vim.o.foldmethod = "indent"
  end
end
vim.api.nvim_create_autocmd("FileType", {
  callback = SetDefaultFoldMethod,
  group = vim.api.nvim_create_augroup("SetDefaultFoldMethod", {}),
})

function FoldText()
  local window_width = vim.fn.winwidth(0)
  local gutter_width = vim.fn.getwininfo(vim.fn.win_getid())[1].textoff
  local line_width = window_width - gutter_width

  local fold_line_count = (vim.v.foldend - vim.v.foldstart) + 1
  local fold_description = string.format("(%s)", fold_line_count)
  local fold_description_length = vim.fn.strdisplaywidth(fold_description)

  local separator_text = "⋯ "
  local separator_text_length = 2

  local line_text = vim.fn.getline(vim.v.foldstart)
  -- truncate if there isn't space for the fold description and separator text
  local max_line_text_length = line_width - (fold_description_length + separator_text_length)
  if vim.fn.strdisplaywidth(line_text) > max_line_text_length then
    line_text = string.sub(line_text, 1, max_line_text_length)
  end

  return line_text .. separator_text .. fold_description
end
vim.o.foldtext = "v:lua.FoldText()"
-- }}}

-- Autocomplete {{{
vim.o.complete = ".,w,b,u"
vim.o.pumheight = 6
-- }}}

-- Command line {{{
-- on first wildchar press (<Tab>), show all matches and complete the longest common substring among
-- on them. subsequent wildchar presses, cycle through matches
vim.o.wildmode = "longest:full,full"
vim.o.wildoptions = "pum"
vim.o.cmdheight = 0
vim.o.showcmdloc = "statusline"
vim.keymap.set("c", "<C-a>", "<C-b>", { remap = true })
vim.cmd([[
  cnoreabbrev <expr> h getcmdtype() == ":" && getcmdline() == 'h' ? 'let g#opening_help_in_tab = v:true \| tab help' : 'h'
]])
vim.cmd([[
  cnoreabbrev <expr> lua getcmdtype() == ":" && getcmdline() == 'lua' ? 'lua=' : 'lua'
]])
-- }}}

-- Search {{{
vim.o.hlsearch = false
-- toggle search highlighting
vim.keymap.set("n", [[\]], "<Cmd>set hlsearch!<CR>", { silent = true })
-- }}}

-- Sessions {{{
vim.opt.sessionoptions:remove("blank")
vim.opt.sessionoptions:remove("options")
vim.opt.sessionoptions:append("tabpages")
vim.opt.sessionoptions:remove("folds")
_G.session_dir = vim.fn.stdpath("data") .. "/sessions"

local function save_session()
  local has_active_session = string.len(vim.v.this_session) > 0
  if has_active_session then
    vim.cmd({
      cmd = "mksession",
      args = { vim.fn.fnameescape(vim.v.this_session) },
      bang = true,
    })
  end
end

local function restore_or_create_session()
  -- We only want to restore/create a session if:
  --  1. neovim was called with no arguments. The first element in `vim.v.argv` will always be the
  --  path to the vim -- executable and the second will be '--embed' so if no arguments were passed
  --  to neovim, the size of `vim.v.argv` -- will be two.
  --  2. neovim's stdin is a terminal. If neovim's stdin isn't the terminal, then that means
  --  content is being -- piped in and we should load that instead.
  local is_neovim_called_with_no_arguments = #vim.v.argv == 2
  if is_neovim_called_with_no_arguments and has_ttyin then
    local session_name = string.gsub(vim.fn.getcwd(), "/", "%%") .. "%vim"
    vim.fn.mkdir(session_dir, "p")
    local session_full_path = session_dir .. "/" .. session_name
    local session_full_path_escaped = vim.fn.fnameescape(session_full_path)
    if vim.fn.filereadable(session_full_path) ~= 0 then
      vim.cmd("silent source " .. session_full_path_escaped)
    else
      vim.cmd({
        cmd = "mksession",
        args = { session_full_path_escaped },
        bang = true,
      })
    end

    local save_session_group_id = vim.api.nvim_create_augroup("SaveSession", {})

    -- Save the session whenever the window layout or active window changes
    vim.api.nvim_create_autocmd({ "BufEnter" }, {
      callback = save_session,
      group = save_session_group_id,
    })

    -- save session before vim exits
    vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
      callback = save_session,
      group = save_session_group_id,
    })
  end
end

-- Restore/create session after vim starts.
vim.api.nvim_create_autocmd({ "VimEnter" }, {
  callback = restore_or_create_session,
  group = vim.api.nvim_create_augroup("RestoreOrCreateSession", {}),
  -- The 'nested' option tells vim to fire events normally while this autocommand is executing. By
  -- default, no events are fired during the execution of an autocommand to prevent infinite loops.
  nested = true,
})

local function delete_current_session()
  local session = vim.v.this_session

  local has_active_session = string.len(session) > 0
  if not has_active_session then
    vim.cmd.echoerr([['ERROR: No session is currently active.']])
    return
  end

  -- Stop saving the current session
  pcall(vim.api.nvim_del_augroup_by_name, "SaveSession")

  local exit_code = vim.fn.delete(session)
  if exit_code == -1 then
    vim.cmd.echoerr(string.format([["Failed to delete current session '%s'."]], session))
  end
end
local function delete_all_sessions()
  -- Stop saving the current session, if there is one.
  pcall(vim.api.nvim_del_augroup_by_name, "SaveSession")

  if not vim.fn.isdirectory(session_dir) then
    vim.cmd.echoerr(
      string.format([["Unable to delete all sessions, '%s' is not a directory."]], session_dir)
    )
    return
  end

  local sessions = vim.fn.split(vim.fn.globpath(session_dir, "*"), "\n")
  for _, session in ipairs(sessions) do
    local exit_code = vim.fn.delete(session)
    if exit_code == -1 then
      vim.cmd.echoerr(
        string.format(
          [["Failed to delete session '%s'. Aborting the rest of the operation..."]],
          session
        )
      )
      return
    end
  end
end
vim.api.nvim_create_user_command(
  "DeleteCurrentSession",
  delete_current_session,
  { desc = "Delete the current session" }
)
vim.api.nvim_create_user_command(
  "DeleteAllSessions",
  delete_all_sessions,
  { desc = "Delete all sessions" }
)
-- }}}

-- Aesthetics {{{

-- Miscellaneous {{{
vim.o.linebreak = true
vim.o.breakat = " ^I"
vim.o.cursorline = true
vim.o.cursorlineopt = "number,screenline"
vim.o.showtabline = 2
vim.o.wrap = true
-- chars to represent tabs and spaces when 'setlist' is enabled
vim.o.listchars = "tab:¬-,space:·"
vim.o.signcolumn = "yes:2"
vim.opt.fillchars:append("eob: ")
vim.o.termguicolors = false
-- }}}

-- Statusline {{{
local function make_statusline(left_items, right_items)
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
  local function make_highlight_names(name)
    return {
      mode = "%#" .. string.format("StatusLineMode%s", name) .. "#",
      inner = "%#" .. string.format("StatusLineMode%sPowerlineInner", name) .. "#",
      outer = "%#" .. string.format("StatusLineMode%sPowerlineOuter", name) .. "#",
    }
  end
  local highlights = make_highlight_names("Other")
  local function startswith(text, prefix)
    return text:find(prefix, 1, true) == 1
  end
  if startswith(mode, "V") then
    highlights = make_highlight_names("Visual")
  elseif startswith(mode, "I") then
    highlights = make_highlight_names("Insert")
  elseif startswith(mode, "N") then
    highlights = make_highlight_names("Normal")
  elseif startswith(mode, "T") then
    highlights = make_highlight_names("Terminal")
  end
  local mode_indicator = highlights.outer
    .. ""
    .. highlights.mode
    .. " "
    .. mode
    .. " "
    .. highlights.inner
    .. " "
  local left_side = mode_indicator .. table.concat(left_items, "  ")
  local right_side = table.concat(right_items, "%#StatusLineSeparator# ∙ ")

  local showcmd = "%#StatusLineShowcmd#%S"
  local statusline_separator = "%#StatusLine# %=" .. showcmd .. "%#StatusLine#%= "

  local padding = "%#StatusLine# "
  local statusline = left_side
    .. statusline_separator
    .. right_side
    .. padding
    .. "%#StatusLinePowerlineOuter#"
    .. ""

  return statusline
end
function GetDiagnosticCountForSeverity(severity)
  return #vim.diagnostic.get(0, { severity = severity })
end
function StatusLine()
  local position = "%#StatusLine#" .. " %l:%c"

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
    local icon, color = require("nvim-web-devicons").get_icon_cterm_color(basename, extension)
    if icon ~= nil then
      vim.api.nvim_set_hl(0, "FileTypeIcon", { ctermfg = tonumber(color), ctermbg = 51 })
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
    #vim.lsp.get_active_clients({ bufnr = vim.api.nvim_get_current_buf() })
  if language_server_count_for_current_buffer > 0 then
    lsp_info = "%#StatusLine# " .. language_server_count_for_current_buffer
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

  local left_side_items = {}
  table.insert(left_side_items, fileencoding)
  table.insert(left_side_items, fileformat)
  if filetype then
    table.insert(left_side_items, filetype)
  end
  if readonly then
    table.insert(left_side_items, readonly)
  end
  if lsp_info then
    table.insert(left_side_items, lsp_info)
  end
  if reg_recording then
    table.insert(left_side_items, reg_recording)
  end
  if search_info then
    table.insert(left_side_items, search_info)
  end

  local right_side_items = {}
  if diagnostics then
    table.insert(right_side_items, diagnostics)
  end
  if mixed_indentation_indicator then
    table.insert(right_side_items, mixed_indentation_indicator)
  end
  if mixed_line_endings then
    table.insert(right_side_items, mixed_line_endings)
  end
  table.insert(right_side_items, position)

  return make_statusline(left_side_items, right_side_items)
end
function QuickfixStatusLine()
  return make_statusline(
    { [[%#StatusLine#%t%{exists('w:quickfix_title')? ' '.w:quickfix_title : ''}]] },
    { "%#StatusLine#Press gf for find&replace" }
  )
end

vim.o.laststatus = 3
vim.o.statusline = "%!v:lua.StatusLine()"
vim.api.nvim_create_autocmd({ "Filetype" }, {
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "gf", ":cdo s///e<left><left><left>", {})
    vim.opt_local.statusline = "%!v:lua.QuickfixStatusLine()"
  end,
  group = vim.api.nvim_create_augroup("Quickfix Statusline", {}),
})
-- }}}

-- StatusColumn {{{
local function is_virtual_line()
  return vim.v.virtnum < 0
end

local function is_wrapped_line()
  return vim.v.virtnum > 0
end

-- Fold column calculation was taken from the following files in the plugin statuscol.nvim:
-- https://github.com/luukvbaal/statuscol.nvim/blob/98d02fc90ebd7c4674ec935074d1d09443d49318/lua/statuscol/ffidef.lua
-- https://github.com/luukvbaal/statuscol.nvim/blob/98d02fc90ebd7c4674ec935074d1d09443d49318/lua/statuscol/builtin.lua
local ffi = require("ffi")
-- I moved this call to `cdef` outside the fold function because I was getting the error "table
-- overflow" a few seconds into using neovim. Plus, not calling this during the fold function is
-- faster.
ffi.cdef([[
  int next_namespace_id;
  uint64_t display_tick;
  typedef struct {} Error;
  typedef struct {} win_T;
  typedef struct {
    int start;  // line number where deepest fold starts
    int level;  // fold level, when zero other fields are N/A
    int llevel; // lowest level that starts in v:lnum
    int lines;  // number of lines from v:lnum to end of closed fold
  } foldinfo_T;
  foldinfo_T fold_info(win_T* wp, int lnum);
  win_T *find_window_by_handle(int Window, Error *err);
  int compute_foldcolumn(win_T *wp, int col);
  int win_col_off(win_T *wp);
]])
local function get_fold_section()
  local wp = ffi.C.find_window_by_handle(vim.g.statusline_winid, ffi.new("Error"))
  local foldinfo = ffi.C.fold_info(wp, vim.v.lnum)
  local string = "%#FoldColumn#"
  local level = foldinfo.level

  if is_virtual_line() or is_wrapped_line() or level == 0 then
    return "  "
  end

  if foldinfo.start == vim.v.lnum then
    local closed = foldinfo.lines > 0
    if closed then
      string = string .. ""
    else
      string = string .. ""
    end
  else
    string = string .. " "
  end
  string = string .. " "

  return string
end

function StatusColumn()
  local buffer = vim.api.nvim_win_get_buf(vim.g.statusline_winid)

  local border_highlight = "%#NonText#"
  local gitHighlights = {
    SignifyAdd = "SignifyAdd",
    SignifyRemoveFirstLine = "SignifyDelete",
    SignifyDelete = "SignifyDelete",
    SignifyDeleteMore = "SignifyDelete",
    SignifyChange = "SignifyChange",
  }
  -- There will be one item at most in this list since I supplied a buffer number.
  local signsPerBuffer = vim.fn.sign_getplaced(buffer, { lnum = vim.v.lnum, group = "" })
  if next(signsPerBuffer) ~= nil then
    for _, sign in ipairs(signsPerBuffer[1].signs) do
      local name = sign.name
      local highlight = gitHighlights[name]
      if highlight ~= nil then
        border_highlight = "%#" .. highlight .. "#"
        break
      end
    end
  end
  local border_section = border_highlight .. "│"

  local line_number_section = nil
  local last_line_digit_count = #tostring(vim.fn.line("$", vim.g.statusline_winid))
  if is_virtual_line() or is_wrapped_line() then
    line_number_section = string.rep(" ", last_line_digit_count)
  else
    local line_number = tostring(vim.v.relnum ~= 0 and vim.v.relnum or vim.v.lnum)
    local line_number_padding = string.rep(" ", last_line_digit_count - #line_number)
    line_number_section = line_number_padding .. line_number
  end

  local fold_section = get_fold_section()
  local sign_section = "%s"
  local align_right = "%="

  return align_right .. sign_section .. line_number_section .. border_section .. fold_section
end

vim.o.statuscolumn = "%!v:lua.StatusColumn()"
-- }}}

-- Cursor {{{
local function set_cursor()
  -- Block cursor in normal mode, thin line in insert mode, and underline in replace mode
  vim.o.guicursor =
    "n-v:block-blinkon0,i-c-ci-ve:ver25-blinkwait0-blinkon200-blinkoff200,r-cr-o:hor20-blinkwait0-blinkon200-blinkoff200"
end
set_cursor()

local function reset_cursor()
  -- Reset terminal cursor to blinking bar.
  -- TODO: This won't be necessary once neovim starts doing this automatically.
  -- Issue: https://github.com/neovim/neovim/issues/4396
  vim.o.guicursor = "a:ver25-blinkwait0-blinkon200-blinkoff200"
end

local cursor_group_id = vim.api.nvim_create_augroup("Cursor", {})
vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend" }, {
  callback = reset_cursor,
  group = cursor_group_id,
})
vim.api.nvim_create_autocmd({ "VimResume" }, {
  callback = set_cursor,
  group = cursor_group_id,
})
-- }}}

-- Winbar {{{
local path_segments_cache = {}
local path_segment_delimiter = "%#NavicSeparator# > "
local path_segment_delimiter_length = 3
-- NOTE: I'm misusing the `minwid` parameter in order to signify which path segment to jump to.
function WinbarPath(path_segment_index)
  local buffer = vim.fn.winbufnr(vim.fn.getmousepos().winid)
  local path = vim.api.nvim_buf_get_name(buffer)
  local segments = vim.split(path, "/", { trimempty = true })
  local path_to_segment = ""
  for i = 1, path_segment_index do
    path_to_segment = path_to_segment .. "/" .. segments[i]
  end
  require("nvim-tree.api").tree.find_file({ buf = path_to_segment, open = true, focus = true })
end
local function create_path_segment_from_string(segment, segment_index)
  return {
    length = #segment,
    text = "%#NavicText#%" .. segment_index .. "@v:lua.WinbarPath@" .. segment .. "%X",
  }
end
-- Most of this logic was taken from here:
-- https://github.com/utilyre/barbecue.nvim/blob/d38a2a023dfb1073dd0e8fee0c9be08855d3688f/lua/barbecue/ui/components.lua#L10
local function get_path_segments(path)
  if path_segments_cache[path] ~= nil then
    return path_segments_cache[path]
  end

  local path_segments = {}

  if path == "." then
    path_segments_cache[path] = {}
    return {}
  end

  local protocol_start_index = path:find("://")
  if protocol_start_index ~= nil then
    path = path:sub(protocol_start_index + 3)
  end

  local path_segment_strings = vim.split(path, "/", { trimempty = true })
  for index, segment_string in ipairs(path_segment_strings) do
    table.insert(path_segments, 1, create_path_segment_from_string(segment_string, index))
  end

  path_segments_cache[path] = path_segments
  return path_segments
end
function Winbar()
  local buffer = vim.api.nvim_get_current_buf()
  local window = vim.api.nvim_get_current_win()
  local winbar = ""
  local winbar_length = 0

  local ok, nvim_navic = pcall(require, "nvim-navic")
  if ok and nvim_navic and nvim_navic.is_available(buffer) then
    winbar = nvim_navic.get_location(nil, buffer)
    for _, datum in ipairs(nvim_navic.get_data(buffer) or {}) do
      -- the 5 is for the delimiter ' > ' and 2 more for the icon
      winbar_length = winbar_length + #datum.name + 5
    end
  end

  if vim.bo[buffer].filetype ~= "help" then
    local path = vim.api.nvim_buf_get_name(buffer)
    local path_segments = get_path_segments(path)
    local path_segments_count = #path_segments
    local max_winbar_length = vim.api.nvim_win_get_width(window)
    local abbreviation_text = "…" .. path_segment_delimiter
    local abbreviation_text_length = 1 + path_segment_delimiter_length
    for index, segment in ipairs(path_segments) do
      local potential_length = winbar_length + segment.length
      local has_more_segments = index < path_segments_count
      if
        (has_more_segments and potential_length <= (max_winbar_length - abbreviation_text_length))
        or ((not has_more_segments) and potential_length <= max_winbar_length)
      then
        if winbar_length ~= 0 then
          winbar = path_segment_delimiter .. winbar
          winbar_length = winbar_length + path_segment_delimiter_length
        end
        winbar = segment.text .. winbar
        winbar_length = winbar_length + segment.length
      else
        winbar = abbreviation_text .. winbar
        winbar_length = winbar_length + abbreviation_text_length
        break
      end
    end
  end

  return winbar
end
vim.o.winbar = "%{%v:lua.Winbar()%}"
-- }}}

-- }}}

-- LSP {{{
vim.diagnostic.config({
  virtual_text = {
    prefix = "",
  },
  update_in_insert = true,
  -- With this enabled, sign priorities will become: hint=11, info=12, warn=13, error=14
  severity_sort = true,
  float = {
    source = true,
    focusable = true,
    border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
    format = function(diagnostic)
      local result = diagnostic.message

      local code = diagnostic.code
      if code ~= nil then
        result = result .. string.format(" [%s]", code)
      end

      return result
    end,
  },
})

local bullet = "•"
local signs = { Error = bullet, Warn = bullet, Hint = bullet, Info = bullet }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl })
end

vim.keymap.set("n", "<S-l>", vim.diagnostic.open_float, { desc = "Show diagnostics" })
vim.keymap.set("n", "[l", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic" })
vim.keymap.set("n", "]l", vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })
vim.keymap.set("n", "gi", function()
  require("telescope.builtin").lsp_implementations({ preview_title = "" })
end, { desc = "Go to implementation" })
vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { desc = "Show signature help" })
vim.keymap.set("n", "gt", function()
  require("telescope.builtin").lsp_type_definitions({ preview_title = "" })
end, { desc = "Go to type definition" })
vim.keymap.set("n", "gd", function()
  require("telescope.builtin").lsp_definitions({ preview_title = "" })
end, { desc = "Go to definition" })
vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
vim.keymap.set("n", "ghi", function()
  require("telescope.builtin").lsp_incoming_calls({ preview_title = "" })
end, { desc = "Show incoming calls" })
vim.keymap.set("n", "gho", function()
  require("telescope.builtin").lsp_outgoing_calls({ preview_title = "" })
end, { desc = "Show outgoing calls" })
vim.keymap.set("n", "gn", vim.lsp.buf.rename, { desc = "Rename" })

-- TODO: When there is only one result, it doesn't add to the jumplist so I'm adding that here. I
-- should upstream this.
vim.keymap.set(
  "n",
  "gr",
  set_jump_before(function()
    require("telescope.builtin").lsp_references()
  end),
  { desc = "Go to reference" }
)
-- }}}

-- Terminal {{{
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.opt_local.signcolumn = "no"
    vim.opt_local.statuscolumn = ""
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.cursorline = false
    vim.cmd.startinsert()
  end,
})
-- }}}

-- Plugins {{{

-- Miscellaneous {{{
-- Add icons to the gutter to represent version control changes (e.g. new lines, modified lines,
-- etc.)
Plug("mhinz/vim-signify", {
  config = function()
    -- Make `[c` and `]c` wrap around. Taken from here:
    -- https://github.com/mhinz/vim-signify/issues/239#issuecomment-305499283
    vim.cmd([[
        function! s:signify_hunk_next(count) abort
          let oldpos = getcurpos()
          call sy#jump#next_hunk(a:count)
          if getcurpos() == oldpos
            call sy#jump#prev_hunk(9999)
          endif
        endfunction

        function! s:signify_hunk_prev(count) abort
          let oldpos = getcurpos()
          call sy#jump#prev_hunk(a:count)
          if getcurpos() == oldpos
            call sy#jump#next_hunk(9999)
          endif
        endfunction

        nnoremap <silent> <expr> <plug>(sy-hunk-next) &diff
              \ ? ']c'
              \ : ":\<c-u>call <sid>signify_hunk_next(v:count1)\<cr>"
        nnoremap <silent> <expr> <plug>(sy-hunk-prev) &diff
              \ ? '[c'
              \ : ":\<c-u>call <sid>signify_hunk_prev(v:count1)\<cr>"

        nmap ]c <plug>(sy-hunk-next)
        nmap [c <plug>(sy-hunk-prev)
      ]])
  end,
})
-- I'm setting all of these so that the signify signs will be added to the sign column, but NOT be
-- visible. I don't want them to be visible because I already change the color of my statuscolumn
-- border to indicate git changes. I want them to be added to the sign column so I know where to
-- color my statuscolumn border.
vim.g.signify_sign_add = ""
vim.g.signify_sign_delete = ""
vim.g.signify_sign_delete_first_line = ""
vim.g.signify_sign_change = ""
vim.g.signify_sign_change_delete = ""
vim.g.signify_priority = -100
vim.g.signify_sign_show_count = 0

Plug("windwp/nvim-autopairs", {
  config = function()
    require("nvim-autopairs").setup({
      -- Don't add bracket pairs after quote.
      enable_afterquote = false,
    })
  end,
})

-- Seamless movement between vim windows and tmux panes.
Plug("christoomey/vim-tmux-navigator", {
  config = function()
    vim.keymap.set({ "n", "i" }, "<M-h>", "<Cmd>TmuxNavigateLeft<CR>", { silent = true })
    vim.keymap.set({ "n", "i" }, "<M-l>", "<Cmd>TmuxNavigateRight<CR>", { silent = true })
    vim.keymap.set({ "n", "i" }, "<M-j>", "<Cmd>TmuxNavigateDown<CR>", { silent = true })
    vim.keymap.set({ "n", "i" }, "<M-k>", "<Cmd>TmuxNavigateUp<CR>", { silent = true })
  end,
})
vim.g.tmux_navigator_no_mappings = 1
vim.g.tmux_navigator_preserve_zoom = 1
vim.g.tmux_navigator_disable_when_zoomed = 0

Plug("Tummetott/reticle.nvim", {
  config = function()
    require("reticle").setup({
      on_startup = {
        cursorline = true,
        cursorcolumn = false,
      },
      disable_in_insert = false,
      never = {
        cursorline = { "TelescopeResults" },
      },
      always_highlight_number = true,
    })
  end,
})

-- To get the vim help pages for vim-plug itself, you need to add it as a plugin
Plug("junegunn/vim-plug")

-- TODO: Using this so that substitutions made by vim-abolish get highlighted as I type them.
-- Won't be necessary if vim-abolish adds support for neovim's `inccommand`.
-- issue for `inccommand` support: https://github.com/tpope/vim-abolish/issues/107
Plug("markonm/traces.vim")
vim.g.traces_abolish_integration = 1

-- Automatically add closing keywords (e.g. function/endfunction in vimscript)
Plug("RRethy/nvim-treesitter-endwise", {
  config = function()
    -- this way endwise triggers on `o`
    vim.keymap.set("n", "o", "A<CR>", { remap = true })
  end,
})

-- Use the ANSI OSC52 sequence to copy text to the system clipboard.
--
-- TODO:
-- Ultimately I'd like my clipboard provider to behave like the following:
--     1. check if OSC52 copy/paste is supported by the terminal (a lot of terminals offer copy, but not paste for
-- security reasons),
--     2. If so use it, if not fallback to one of CLIs e.g. wl-copy.
--
-- There are 2 ways I can get this:
--     1. I use my `pbcopy` as the clipboard provider and add a check to `pbcopy` to make sure
-- we're connected to a terminal before trying OSC52. There are some ideas here for how to do that check:
-- https://github.com/neovim/neovim/issues/3344#issuecomment-1808677428
-- I'd also have to set my `pbpaste` as the provider since you can't set just copy or paste it has to be both.
--     2. OSC52 is also being upstreamed so I may be able to just use that depending on how they do it:
-- https://github.com/neovim/neovim/pull/25872. I have a feeling the upstreamed support won't work for me
-- because they'll probably only use OSC52 if both copy _and_ paste are supported, but I'd like each one to
-- fallback separately, not as a pair.
Plug("ojroques/nvim-osc52", {
  config = function()
    local osc = require("osc52")

    osc.setup({ silent = true })

    local function copy()
      -- Use OSC 52 to set the clipboard whenever the `+` register is written to. Since the
      -- clipboard provider is probably setting the clipboard as well this means we do it twice.
      if vim.v.event.operator == "y" and vim.v.event.regname == "+" then
        osc.copy_register("+")
      end
    end
    vim.api.nvim_create_autocmd("TextYankPost", { callback = copy })
  end,
})

Plug("lukas-reineke/virt-column.nvim", {
  config = function()
    require("virt-column").setup({ char = "│" })
  end,
})

-- lua utility library specifically for use in neovim
Plug("nvim-lua/plenary.nvim")

-- Dependencies: plenary.nvim, nui.nvim, telescope-fzf-native.nvim
Plug("nvim-telescope/telescope.nvim", {
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    local select_one_or_multiple_files = function(prompt_buffer_number)
      local current_picker =
        require("telescope.actions.state").get_current_picker(prompt_buffer_number)
      local multi_selections = current_picker:get_multi_selection()
      if not vim.tbl_isempty(multi_selections) then
        actions.close(prompt_buffer_number)
        for _, multi_selection in pairs(multi_selections) do
          if multi_selection.path ~= nil then
            vim.cmd(string.format("edit %s", multi_selection.path))
          end
        end
      else
        actions.select_default(prompt_buffer_number)
      end
    end

    telescope.setup({
      defaults = {
        mappings = {
          i = {
            ["<Esc>"] = actions.close,
            ["<Tab>"] = actions.move_selection_next,
            ["<S-Tab>"] = actions.move_selection_previous,
            ["<F7>"] = actions.cycle_history_prev,
            ["<F8>"] = actions.cycle_history_next,
            ["<C-j>"] = actions.preview_scrolling_down,
            ["<C-k>"] = actions.preview_scrolling_up,
            ["<C-h>"] = actions.select_horizontal,
            ["<C-u>"] = false,
            ["<M-CR>"] = actions.toggle_selection,
            ["<M-a>"] = actions.toggle_all,
            ["<C-q>"] = function(...)
              actions.smart_send_to_qflist(...)
              actions.open_qflist(...)
            end,
          },
        },
        prompt_prefix = "   ",
        sorting_strategy = "ascending",
        selection_caret = " > ",
        entry_prefix = "   ",
        dynamic_preview_title = true,
        results_title = false,
        path_display = { "truncate" },
        history = {
          path = vim.fn.stdpath("data") .. "/telescope_history.sqlite3",
          limit = 100,
        },
        layout_strategy = "vertical",
        layout_config = {
          mirror = true,
          preview_cutoff = 20,
          prompt_position = "top",
        },
        borderchars = { "━", "", " ", " ", "━", "━", " ", " " },
      },
      pickers = {
        find_files = {
          hidden = true,
          follow = true,
          mappings = {
            i = {
              ["<CR>"] = select_one_or_multiple_files,
            },
          },
          disable_devicons = true,
          preview_title = "",
        },
        live_grep = {
          additional_args = {
            "--hidden",
            "--smart-case",
            "--follow",
          },
          mappings = {
            i = { ["<c-f>"] = actions.to_fuzzy_refine },
          },
          prompt_title = "Live Grep (Press <c-f> to fuzzy filter)",
          disable_devicons = true,
          preview_title = "",
        },
        help_tags = {
          mappings = {
            i = {
              ["<CR>"] = function(...)
                vim.g.opening_help_in_tab = true
                actions.select_tab(...)
              end,
            },
          },
          preview_title = "",
        },
        current_buffer_fuzzy_find = { preview_title = "" },
        jumplist = { preview_title = "" },
        highlights = { preview_title = "" },
        diagnostics = { preview_title = "" },
        lsp_dynamic_workspace_symbols = { preview_title = "" },
        autocommands = { preview_title = "" },
        filter_notifications = { preview_title = "" },
      },
    })

    local telescope_builtins = require("telescope.builtin")
    local function call_with_visual_selection(picker)
      local result = function()
        local visual_selection = GetVisualSelection()
        if #visual_selection > 0 then
          picker({ default_text = visual_selection })
        else
          picker()
        end
      end

      return result
    end
    vim.keymap.set(
      { "n", "v" },
      "<Leader>h",
      call_with_visual_selection(telescope_builtins.command_history)
    )
    -- TODO: I need to fix the previewer so it works with `page`. This way I get I get a live
    -- preview when I search manpages.
    vim.keymap.set("n", "<Leader>b", telescope_builtins.current_buffer_fuzzy_find)
    -- This is actually ctrl+/, see :help :map-special-keys
    vim.keymap.set("n", "<C-_>", telescope_builtins.commands)
    -- Outside TMUX the above won't work, I have to use <C-/>, so I just map both.
    vim.keymap.set("n", "<C-/>", telescope_builtins.commands)
    vim.keymap.set(
      { "n", "v" },
      "<Leader>k",
      call_with_visual_selection(telescope_builtins.help_tags)
    )
    vim.keymap.set(
      { "n", "v" },
      "<Leader>g",
      set_jump_before(call_with_visual_selection(telescope_builtins.live_grep))
    )
    vim.keymap.set("n", "<Leader>f", telescope_builtins.find_files)
    vim.keymap.set("n", "<Leader>j", telescope_builtins.jumplist)
    vim.keymap.set("n", "<Leader><Leader>", telescope_builtins.resume)
    vim.keymap.set(
      { "n", "v" },
      "<Leader>s",
      call_with_visual_selection(telescope_builtins.lsp_dynamic_workspace_symbols)
    )
    vim.keymap.set("n", "<Leader>l", telescope_builtins.diagnostics)
    vim.api.nvim_create_user_command("Highlights", telescope_builtins.highlights, {})
    vim.api.nvim_create_user_command("Autocommands", telescope_builtins.autocommands, {})
    vim.api.nvim_create_user_command("Mappings", telescope_builtins.keymaps, {})

    telescope.load_extension("fzf")
    telescope.load_extension("smart_history")
  end,
})

Plug("nvim-telescope/telescope-fzf-native.nvim")

Plug("kkharji/sqlite.lua")

Plug("nvim-telescope/telescope-smart-history.nvim")

Plug("stevearc/dressing.nvim", {
  config = function()
    require("dressing").setup({
      input = { enabled = false },
    })
  end,
})

-- Use folds provided by a language server
Plug("pierreglaser/folding-nvim")

Plug("folke/which-key.nvim", {
  config = function()
    require("which-key").setup({
      popup_mappings = {
        scroll_down = "<c-j>",
        scroll_up = "<c-k>",
      },
      -- hide mapping boilerplate
      -- This is the correct type.
      ---@diagnostic disable-next-line: assign-type-mismatch
      hidden = {
        "<silent>",
        "<cmd>",
        "<Cmd>",
        "<CR>",
        "call",
        "lua",
        "^:",
        "^ ",
        "<Plug>",
        "<plug>",
      },
      layout = {
        height = {
          max = math.floor(vim.o.lines * 0.25),
        },
      },
      window = {
        border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
        margin = { 1, 4, 2, 2 },
      },
      icons = {
        separator = " ",
      },
    })
  end,
})

Plug("tpope/vim-sleuth")

-- for autocomplete
Plug("blankname/vim-fish")

Plug("windwp/nvim-ts-autotag")

Plug("kosayoda/nvim-lightbulb", {
  config = function()
    require("nvim-lightbulb").setup({
      autocmd = { enabled = true },
      -- Giving it a higher priority than diagnostics
      sign = {
        priority = 15,
        text = "",
        hl = "CodeActionSign",
      },
    })
  end,
})

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

Plug("akinsho/bufferline.nvim", {
  config = function()
    local function close(buffer)
      local buffer_count = #vim.fn.getbufinfo({ buflisted = 1 })
      local window_count = vim.fn.winnr("$")
      local tab_count = vim.fn.tabpagenr("$")

      -- If the only other window in the tab page is nvim-tree, and only one tab is open, keep the
      -- window and switch to another buffer.
      if
        tab_count == 1
        and window_count == 2
        and require("nvim-tree.api").tree.is_visible()
        and buffer_count > 1
      then
        -- `bdelete` closes the window if the buffer is open in one so we have to switch to a
        -- different buffer first.
        vim.cmd.BufferLineCycleNext()
        vim.cmd("bdelete! " .. buffer)
        return
      end

      -- If this is the last window and tab, close the buffer and if that was the last buffer, close
      -- vim.
      if
        tab_count == 1
        and (
          window_count == 1 or (window_count == 2 and require("nvim-tree.api").tree.is_visible())
        )
      then
        local buffer_count_before_closing = buffer_count
        vim.cmd("bdelete! " .. buffer)
        if buffer_count_before_closing == 1 then
          -- Using `quitall` instead of quit so it closes both windows
          vim.cmd.quitall()
        end
        return
      end

      -- If the buffer is only open in the current window, close the buffer and window. Otherwise,
      -- just close the window.
      local buffer_window_count = #vim.fn.win_findbuf(buffer)
      if buffer_window_count == 1 then
        vim.cmd("b#")
        vim.cmd("bd#")
      end
    end

    local close_icon = ""
    local separator_icon = "   "
    require("bufferline").setup({
      ---@diagnostic disable-next-line: missing-fields
      options = {
        ---@diagnostic disable-next-line: undefined-field
        numbers = function(context)
          return context.raise(context.ordinal)
        end,
        indicator = { style = "none" },
        close_icon = close_icon,
        close_command = close,
        buffer_close_icon = close_icon,
        separator_style = { separator_icon, separator_icon },
        modified_icon = close_icon,
        offsets = {
          {
            filetype = "NvimTree",
            text = " File Explorer (Press g? for help)",
            text_align = "center",
            separator = true,
            highlight = "NvimTreeTitle",
          },
          {
            filetype = "aerial",
            text = "󰙅 Outline (Press ? for help)",
            text_align = "center",
            separator = true,
            highlight = "OutlineTitle",
          },
        },
        hover = {
          enabled = true,
          delay = 50,
          reveal = { "close" },
        },
        themable = true,
        max_name_length = 100,
        max_prefix_length = 100,
        tab_size = 1,
        custom_filter = function(buf_number, _)
          -- filter out file types you don't want to see
          if vim.bo[buf_number].filetype ~= "qf" then
            return true
          end
          return false
        end,
        show_buffer_icons = false,
      },
      highlights = {
        ---@diagnostic disable: missing-fields
        fill = { ctermbg = 51, ctermfg = 15 },
        background = { ctermbg = 51, ctermfg = 15 },
        buffer_visible = { ctermbg = 51, ctermfg = 15 },
        buffer_selected = { ctermbg = 51, ctermfg = "NONE", italic = false, bold = false },
        duplicate = { ctermbg = 51, ctermfg = 15, italic = false },
        duplicate_selected = { ctermbg = 51, ctermfg = "None", italic = false },
        duplicate_visible = { ctermbg = 51, ctermfg = 15, italic = false },
        numbers = { ctermbg = 51, ctermfg = 15, italic = false },
        numbers_visible = { ctermbg = 51, ctermfg = 15, italic = false },
        numbers_selected = { ctermbg = 51, ctermfg = 6, italic = false },
        close_button = { ctermbg = 51, ctermfg = 15 },
        close_button_selected = { ctermbg = 51, ctermfg = "None" },
        close_button_visible = { ctermbg = 51, ctermfg = 15 },
        modified = { ctermbg = 51, ctermfg = 15 },
        modified_selected = { ctermbg = 51, ctermfg = "None" },
        modified_visible = { ctermbg = 51, ctermfg = "None" },
        tab = { ctermbg = 51, ctermfg = 15 },
        tab_selected = { ctermbg = 51, ctermfg = 6, underline = true },
        tab_separator = { ctermbg = 51, ctermfg = 51 },
        tab_separator_selected = { ctermbg = 51, ctermfg = 51 },
        tab_close = { ctermbg = 51, ctermfg = "NONE", bold = true },
        offset_separator = { ctermbg = "NONE", ctermfg = 15 },
        separator = { ctermbg = 51, ctermfg = 0 },
        separator_visible = { ctermbg = 51, ctermfg = 0 },
        separator_selected = { ctermbg = 51, ctermfg = 0 },
        indicator_selected = { ctermbg = 51, ctermfg = 51 },
        indicator_visible = { ctermbg = 51, ctermfg = 51 },
        trunc_marker = { ctermbg = 51, ctermfg = 15 },
      },
    })

    vim.keymap.set({ "n", "i" }, "<F7>", vim.cmd.BufferLineCyclePrev, { silent = true })
    vim.keymap.set({ "n", "i" }, "<F8>", vim.cmd.BufferLineCycleNext, { silent = true })

    -- Switch buffers with <Leader><tab number>
    for buffer_index = 1, 9 do
      vim.keymap.set("n", "<Leader>" .. buffer_index, function()
        require("bufferline").go_to(buffer_index, true)
      end)
    end

    vim.keymap.set("n", "<C-q>", function()
      close(vim.fn.bufnr())
    end, { silent = true })
    function BufferlineWrapper()
      ---@diagnostic disable-next-line: undefined-global
      local original = nvim_bufferline()
      local result = original
      local is_explorer_open = string.find(original, "")
      local is_outline_open = string.find(original, "󰙅")
      local is_tab_section_visible = string.find(original, "%%=%%#BufferLineTab")

      if is_outline_open then
        result = string.gsub(
          result,
          "│%%#OutlineTitle#",
          "%%#TabLineBorder#%%#BufferLineOffsetSeparator#%0",
          1
        )
      else
        result = result .. "%#TabLineBorder#"
      end

      if is_explorer_open then
        result = string.gsub(result, "│", "%0%%#TabLineBorder#", 1)
      else
        result = "%#TabLineBorder#" .. result
      end

      if is_tab_section_visible then
        result =
          string.gsub(result, "%%=%%#BufferLineTab", "%%=%%#TabLineBorder2#%%#BufferLineTab", 1)
      end

      return result
    end
    vim.o.tabline = "%!v:lua.BufferlineWrapper()"
  end,
})

Plug("j-hui/fidget.nvim", {
  config = function()
    require("fidget").setup({
      progress = {
        ignore_done_already = true,
        ignore = { "null-ls" },
        display = {
          render_limit = 5,
          done_ttl = 0.1,
          done_icon = "󰄬",
          done_style = "FidgetNormal",
          progress_style = "FidgetAccent",
          group_style = "FidgetAccent",
          icon_style = "FidgetIcon",
          progress_icon = { "dots" },
        },
      },
      notification = {
        view = {
          group_separator = "─────",
        },
        window = {
          normal_hl = "FidgetNormal",
          winblend = 0,
          zindex = 1,
        },
      },
    })
  end,
})

Plug("rcarriga/nvim-notify", {
  config = function()
    local notify = require("notify")
    notify.setup({
      stages = "slide",
      timeout = 3000,
      render = "wrapped-compact",
      max_width = math.floor(vim.o.columns * 0.35),
    })
    vim.notify = notify
    vim.keymap.set("n", "<Leader>n", "<Cmd>Telescope notify<CR>")
  end,
})

-- Dependencies: nvim-lspconfig
Plug("SmiteshP/nvim-navic", {
  config = function()
    require("nvim-navic").setup({
      -- Allow control of the colors used through highlights
      highlight = true,
      -- click on a breadcrumb to jump there
      click = true,
    })
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        if vim.api.nvim_buf_line_count(0) > 10000 then
          -- For large files, only get update on CursorHold, not CursorMoved.
          ---@diagnostic disable-next-line: inject-field
          vim.b.navic_lazy_update_context = true
        end
      end,
    })
  end,
})

Plug("f-person/git-blame.nvim", {
  config = function()
    vim.g.gitblame_highlight_group = "GitBlameVirtualText"
    local message_prefix = "    "
    require("gitblame").setup({
      message_template = message_prefix .. "<author>, <date> ∙ <summary>",
      message_when_not_committed = message_prefix .. "Not committed yet",
      date_format = "%r",
      use_blame_commit_file_urls = true,
      -- TODO: Workaround for a bug in neovim where virtual text highlight is being combined with
      -- the cursorline highlight. issue: https://github.com/neovim/neovim/issues/15485
      set_extmark_options = {
        hl_mode = "combine",
      },
    })
  end,
})

Plug("stevearc/aerial.nvim", {
  config = function()
    AerialIsFolded = false
    local function aerial_fold_toggle()
      if AerialIsFolded then
        require("aerial.tree").open_all()
        AerialIsFolded = false
      else
        require("aerial.tree").close_all()
        AerialIsFolded = true
      end
    end
    require("aerial").setup({
      backends = { "lsp", "treesitter", "markdown", "man" },
      layout = {
        max_width = 0.3,
        min_width = 0.2,
        default_direction = "right",
        placement = "edge",
        -- When the symbols change, resize the aerial window (within min/max constraints) to fit
        resize_to_content = true,
      },
      attach_mode = "global",
      keymaps = {
        ["<C-j>"] = false,
        ["<C-k>"] = false,
        ["<tab>"] = "actions.tree_toggle",
        ["<S-tab>"] = { callback = aerial_fold_toggle },
        ["<CR>"] = {
          callback = function()
            require("aerial.navigation").select({ jump = false })
          end,
        },
        ["<LeftMouse>"] = [[<LeftMouse><Cmd>lua require('aerial.navigation').select({jump = false,})<CR>]],
      },
      lazy_load = true,
      nerd_font = true,
      show_guides = true,
      link_tree_to_folds = false,
    })
    vim.api.nvim_create_user_command("OutlineToggle", function()
      vim.cmd.AerialToggle()
    end, { desc = "Toggle the symbol outline window" })
    vim.keymap.set({ "n" }, "<M-o>", vim.cmd.AerialToggle, { silent = true })
    local aerial_group_id = vim.api.nvim_create_augroup("MyAerial", {})
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        if vim.o.filetype == "aerial" then
          vim.opt_local.scrolloff = 0
          vim.wo.statuscolumn = " "
          -- I want to disable it, but you can't if it has a global value:
          -- https://github.com/neovim/neovim/issues/18660
          vim.opt_local.winbar = " "
          vim.b.minicursorword_disable = true
          vim.b.minicursorword_disable_permanent = true
          vim.api.nvim_set_hl(0, "OutlineTitle", { link = "BufferLineBufferSelected" })
        end
      end,
      group = aerial_group_id,
    })
    vim.api.nvim_create_autocmd("BufLeave", {
      callback = function()
        if vim.o.filetype == "aerial" then
          vim.api.nvim_set_hl(0, "OutlineTitle", { link = "BufferLineBufferVisible" })
        end
      end,
      group = aerial_group_id,
    })
  end,
})

Plug("anuvyklack/middleclass")

Plug("anuvyklack/windows.nvim", {
  config = function()
    require("windows").setup({
      autowidth = {
        enable = false,
      },
    })

    -- TODO: When tmux is able to differentiate between enter and ctrl+m this mapping should be
    -- updated. tmux issue: https://github.com/tmux/tmux/issues/2705#issuecomment-841133549
    vim.keymap.set("n", "<Leader>m", function()
      vim.cmd.WindowsMaximize()
    end)
  end,
})

Plug("iamcco/markdown-preview.nvim")

Plug("aznhe21/actions-preview.nvim", {
  config = function()
    local actions_preview = require("actions-preview")
    actions_preview.setup({
      telescope = {},
    })
    vim.keymap.set(
      { "n", "v" },
      "ga",
      actions_preview.code_actions,
      { desc = "Choose code action" }
    )
  end,
})

Plug("nvim-tree/nvim-web-devicons")
-- }}}

-- File Explorer {{{
Plug("kyazdani42/nvim-tree.lua", {
  config = function()
    require("nvim-tree").setup({
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
        signcolumn = "yes",
        width = {
          max = function()
            return math.floor(vim.o.columns * 0.30)
          end,
          -- Enough to fit the title text
          min = 45,
        },
        preserve_window_proportions = true,
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
          symlink_arrow = "   ",
          show = {
            file = false,
            folder = false,
          },
          glyphs = {
            folder = {
              arrow_closed = "›",
              arrow_open = "⌄",
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
        local api = require("nvim-tree.api")
        api.config.mappings.default_on_attach(buffer_number)

        vim.keymap.set("n", "h", "<BS>", { buffer = buffer_number, remap = true })
        vim.keymap.set("n", "l", "<CR>", { buffer = buffer_number, remap = true })
        vim.keymap.set("n", "<Tab>", "<CR>", { buffer = buffer_number, remap = true })
      end,
    })
    vim.api.nvim_create_user_command("ExplorerToggle", function()
      vim.cmd.NvimTreeFindFileToggle()
    end, { desc = "Toggle the explorer window" })
    vim.keymap.set("n", "<M-e>", vim.cmd.ExplorerToggle, { silent = true })
    local nvim_tree_group_id = vim.api.nvim_create_augroup("MyNvimTree", {})
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        if vim.o.filetype == "NvimTree" then
          vim.api.nvim_set_hl(0, "NvimTreeTitle", { link = "BufferLineBufferSelected" })
          vim.opt_local.cursorline = true
        end
      end,
      group = nvim_tree_group_id,
    })
    vim.api.nvim_create_autocmd("BufLeave", {
      callback = function()
        if vim.o.filetype == "NvimTree" then
          vim.api.nvim_set_hl(0, "NvimTreeTitle", { link = "BufferLineBufferVisible" })
          vim.opt_local.cursorline = false
        end
      end,
      group = nvim_tree_group_id,
    })
    vim.api.nvim_create_autocmd("BufWinEnter", {
      callback = function()
        if vim.o.filetype == "NvimTree" then
          vim.opt_local.statuscolumn = ""
          -- I want to disable it, but you can't if it has a global value:
          -- https://github.com/neovim/neovim/issues/18660
          vim.opt_local.winbar = " "
        end
      end,
      group = nvim_tree_group_id,
    })
  end,
})
-- }}}

-- Autocomplete {{{
Plug("hrsh7th/cmp-omni")

Plug("hrsh7th/cmp-cmdline")

Plug("dmitmel/cmp-cmdline-history")

-- This won't work until this is fixed: https://github.com/andersevenrud/cmp-tmux/issues/29
Plug("andersevenrud/cmp-tmux")

Plug("hrsh7th/cmp-buffer")

Plug("hrsh7th/cmp-nvim-lsp")

Plug("hrsh7th/cmp-path")

Plug("hrsh7th/cmp-nvim-lsp-signature-help")

Plug("bydlw98/cmp-env")

Plug("L3MON4D3/LuaSnip", {
  config = function()
    require("luasnip").config.set_config({
      history = true,
      delete_check_events = "TextChanged",
    })
    require("luasnip.loaders.from_vscode").lazy_load()
  end,
})

Plug("saadparwaiz1/cmp_luasnip")

Plug("rafamadriz/friendly-snippets")

Plug("hrsh7th/nvim-cmp", {
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    local cmp_buffer = require("cmp_buffer")

    cmp.event:on(
      "confirm_done",
      require("nvim-autopairs.completion.cmp").on_confirm_done({
        filetypes = {
          nix = false,
        },
      })
    )

    -- sources
    local buffer = {
      name = "buffer",
      option = {
        keyword_length = 2,
        get_bufnrs = function()
          local filtered_buffer_numbers = {}
          local all_buffer_numbers = vim.api.nvim_list_bufs()
          for _, buffer_number in ipairs(all_buffer_numbers) do
            local is_buffer_loaded = vim.api.nvim_buf_is_loaded(buffer_number)
            -- 5 megabyte max
            local is_buffer_under_max_size = vim.api.nvim_buf_get_offset(
              buffer_number,
              vim.api.nvim_buf_line_count(buffer_number)
            ) < 1024 * 1024 * 5

            if is_buffer_loaded and is_buffer_under_max_size then
              table.insert(filtered_buffer_numbers, buffer_number)
            end
          end

          return filtered_buffer_numbers
        end,
      },
    }
    local nvim_lsp = { name = "nvim_lsp" }
    local omni = { name = "omni" }
    local path = {
      name = "path",
      option = {
        label_trailing_slash = false,
      },
    }
    local tmux = {
      name = "tmux",
      option = { all_panes = true, label = "Tmux", capture_history = true },
    }
    local cmdline = { name = "cmdline", priority = 9 }
    local cmdline_history = {
      name = "cmdline_history",
      max_item_count = 2,
    }
    local lsp_signature = { name = "nvim_lsp_signature_help", priority = 8 }
    local luasnip_source = {
      name = "luasnip",
      option = { use_show_condition = false },
    }
    local env = { name = "env" }

    -- helpers
    local is_cursor_preceded_by_nonblank_character = function()
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      return col ~= 0
        and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s")
          == nil
    end
    local cmdline_search_config = {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        buffer,
        cmdline_history,
      },
    }

    cmp.setup({
      formatting = {
        fields = { "abbr", "kind" },
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
          winhighlight = "NormalFloat:CmpDocumentationNormal,FloatBorder:CmpDocumentationBorder",
          border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
        },
        completion = {
          winhighlight = "NormalFloat:CmpNormal,Pmenu:CmpNormal,CursorLine:CmpCursorLine,PmenuSbar:CmpScrollbar",
          border = "none",
          side_padding = 1,
          col_offset = 1,
        },
      },
      experimental = {
        ghost_text = { hl_group = "CmpGhostText" },
      },
      mapping = cmp.mapping.preset.insert({
        ["<CR>"] = function(fallback)
          -- TODO: Don't block <CR> if signature help is active
          -- https://github.com/hrsh7th/cmp-nvim-lsp-signature-help/issues/13
          if
            not cmp.visible()
            or not cmp.get_selected_entry()
            or cmp.get_selected_entry().source.name == "nvim_lsp_signature_help"
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
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
          elseif is_cursor_preceded_by_nonblank_character() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<C-k>"] = cmp.mapping.scroll_docs(-4),
        ["<C-j>"] = cmp.mapping.scroll_docs(4),
        ["<C-h>"] = cmp.mapping(function(_)
          if luasnip.jumpable(-1) then
            luasnip.jump(-1)
          end
        end, { "i", "s" }),
        ["<C-l>"] = cmp.mapping(function(_)
          if luasnip.jumpable(1) then
            luasnip.jump(1)
          end
        end, { "i", "s" }),
      }),
      -- The order of the sources controls which entry will be chosen if multiple sources return
      -- entries with the same names. Sources at the bottom of this list will be chosen over the
      -- sources above them.
      sources = cmp.config.sources({
        lsp_signature,
        buffer,
        tmux,
        env,
        luasnip_source,
        omni,
        nvim_lsp,
        path,
      }),
      sorting = {
        -- Builtin comparators are defined here:
        -- https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/config/compare.lua
        comparators = {
          -- Sort by the item kind enum, lower ordinal values are ranked higher. Enum is defined here:
          -- https://github.com/hrsh7th/nvim-cmp/blob/5dce1b778b85c717f6614e3f4da45e9f19f54435/lua/cmp/types/lsp.lua#L177
          function(entry1, entry2)
            local text_kind = require("cmp.types").lsp.CompletionItemKind.Text
            -- Adjust the rankings so the new rankings will be:
            -- 1. Everything else
            -- 2. Text
            local function get_adjusted_ranking(kind)
              if kind == text_kind then
                return 2
              else
                return 1
              end
            end
            local kind1 = get_adjusted_ranking(entry1:get_kind())
            local kind2 = get_adjusted_ranking(entry2:get_kind())

            if kind1 ~= kind2 then
              local diff = kind1 - kind2
              if diff < 0 then
                return true
              elseif diff > 0 then
                return false
              end
            end

            return nil
          end,

          function(...)
            return cmp_buffer:compare_locality(...)
          end,
        },
      },
    })

    cmp.setup.cmdline("/", cmdline_search_config)
    cmp.setup.cmdline("?", cmdline_search_config)
    cmp.setup.cmdline(":", {
      formatting = {
        fields = { "abbr", "menu" },
        format = function(entry, vim_item)
          vim_item.menu = ({
            cmdline = "Commandline",
            cmdline_history = "History",
            buffer = "Buffer",
            path = "Path",
          })[entry.source.name]
          vim_item.dup = 0
          return vim_item
        end,
      },
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        cmdline,
        cmdline_history,
        path,
        buffer,
      }),
    })
  end,
})
-- }}}

-- Tool Manager {{{
Plug("williamboman/mason.nvim", {
  config = function()
    require("mason").setup({
      ui = {
        width = 1,
        -- Ideally I'd use a function here so I could set it to '<screen_height> - 1', but this
        -- field doesn't support functions.
        height = 1,
        icons = {
          package_installed = "󰄳  ",
          package_pending = "  ",
          package_uninstalled = "󰝦  ",
        },
        keymaps = {
          toggle_package_expand = "<Tab>",
        },
      },
      log_level = vim.log.levels.DEBUG,
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "mason",
      callback = function()
        vim.b.minicursorword_disable = true
        vim.b.minicursorword_disable_permanent = true
      end,
      group = vim.api.nvim_create_augroup("MyMason", {}),
    })
    vim.api.nvim_create_user_command(
      "Extensions",
      vim.cmd.Mason,
      { desc = "Manage external tooling such as language servers" }
    )

    -- Store the number of packages that have an update available so I can put it in my statusline.
    local registry = require("mason-registry")
    local function maybe_set_update_flag(success, _)
      if success then
        _G.mason_update_available_count = _G.mason_update_available_count + 1
      end
    end
    local function set_mason_update_count()
      _G.mason_update_available_count = 0
      local packages = registry.get_installed_packages()
      for _, package in ipairs(packages) do
        package:check_new_version(maybe_set_update_flag)
      end
    end
    -- Update the registry first so we get the latest package versions.
    registry.update(function(was_successful, registry_sources_or_error)
      if not was_successful then
        vim.notify(
          "Failed to check for mason updates: " .. registry_sources_or_error,
          vim.log.levels.ERROR
        )
        return
      end
      set_mason_update_count()
    end)
    -- Set the count every time we update a package so it gets decremented accordingly.
    --
    -- TODO: This event also fires when a new package is installed, but we aren't interested in that
    -- event. This means we'll set the count more often than we need to.
    registry:on("package:install:success", vim.schedule_wrap(set_mason_update_count))
  end,
})

-- To read/write config files the way the vscode extension does.
Plug("barreiroleo/ltex-extra.nvim")

Plug("williamboman/mason-lspconfig.nvim", {
  config = function()
    require("mason-lspconfig").setup()
    local lspconfig = require("lspconfig")

    local on_attach = function(client, buffer_number)
      local capabilities = client.server_capabilities
      local buffer_keymap = vim.api.nvim_buf_set_keymap
      local keymap_opts = { noremap = true, silent = true }

      -- TODO: foldmethod is window-local, but I want to set it per buffer. Possible solution here:
      -- https://github.com/ii14/dotfiles/blob/e40d2b8316ec72b5b06b9e7a1d997276ff4ddb6a/.config/nvim/lua/m/opt.lua
      local foldmethod = vim.o.foldmethod
      local isFoldmethodOverridable = foldmethod ~= "marker" and foldmethod ~= "diff"
      if capabilities.foldingRangeProvider and isFoldmethodOverridable then
        -- folding-nvim prints a message if any attached language server does not support folding so I'm suppressing
        -- that.
        vim.cmd([[silent lua require('folding').on_attach()]])
      end

      local filetype = vim.o.filetype
      local isKeywordprgOverridable = filetype ~= "vim"
      if capabilities.hoverProvider and isKeywordprgOverridable then
        buffer_keymap(buffer_number, "n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", keymap_opts)

        -- Change border of documentation hover window, See https://github.com/neovim/neovim/pull/13998.
        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
          focusable = true,
          border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
        })
      end

      if capabilities.documentSymbolProvider then
        require("nvim-navic").attach(client, buffer_number)
      end
    end

    local cmp_lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()
    local folding_capabilities = {
      textDocument = {
        foldingRange = {
          dynamicRegistration = false,
          lineFoldingOnly = true,
        },
      },
    }
    local capabilities = vim.tbl_deep_extend("error", cmp_lsp_capabilities, folding_capabilities)

    local default_server_config = {
      capabilities = capabilities,
      on_attach = on_attach,
    }

    local server_specific_configs = {
      jsonls = {
        settings = {
          json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
          },
        },
      },

      lemminx = {
        settings = {
          xml = {
            catalogs = { "/etc/xml/catalog" },
          },
        },
      },

      vale_ls = {
        filetypes = {
          -- NOTE: This should have all the programming languages listed here:
          -- https://vale.sh/docs/topics/scoping/#code-1
          "c",
          "cs",
          "cpp",
          "css",
          "go",
          "haskell",
          "java",
          "javascript",
          "less",
          "lua",
          "perl",
          "php",
          "python",
          "r",
          "ruby",
          "sass",
          "scala",
          "swift",
        },
      },

      ltex = {
        on_attach = function(client, buffer_number)
          on_attach(client, buffer_number)
          require("ltex_extra").setup({
            load_langs = { "en-US" },
            -- For compatibility with the vscode extension
            path = ".vscode",
          })
        end,
        -- This should have file types for all the languages specified in `settings.ltex.enabled`
        filetypes = {
          "bib",
          "gitcommit", -- The LSP language ID is `git-commit`, but neovim uses `gitcommit`.
          "markdown",
          "org",
          "plaintex",
          "rst",
          "rnoweb",
          "tex",
          "pandoc",
          "quarto",
          "rmd",

          -- neovim gives plain text files the file type `text`, but ltex-ls only supports the LSP
          -- language ID for plain text, `plaintext`. However, since ltex-ls treats unsupported file
          -- types as plain text, it works out.
          "text",
        },
        settings = {
          ltex = {
            completionEnabled = true,
            enabled = {
              -- This block of languages should contain all the languages here:
              -- https://github.com/valentjn/ltex-ls/blob/1193c9959aa87b3d36ca436060447330bf735a9d/src/main/kotlin/org/bsplines/ltexls/parsing/CodeFragmentizer.kt
              "bib",
              "bibtex",
              "gitcommit", -- The LSP language ID is `git-commit`, but neovim uses `gitcommit`.
              "html",
              "xhtml",
              "context",
              "context.tex",
              "latex",
              "plaintex",
              "rsweave",
              "tex",
              "markdown",
              "nop",
              "org",
              "plaintext",
              "restructuredtext",

              -- neovim gives plain text files the file type `text`, but ltex-ls only supports
              -- the LSP language ID for plain text, `plaintext`. However, since ltex-ls treats
              -- unsupported file types as plain text, it works out.
              "text",
            },
          },
        },
      },
    }

    local server_config_handlers = {}
    -- Default handler to be called for each installed server that doesn't have a dedicated handler.
    server_config_handlers[1] = function(server_name)
      lspconfig[server_name].setup(default_server_config)
    end
    -- server-specific handlers
    for server_name, server_specific_config in pairs(server_specific_configs) do
      server_config_handlers[server_name] = function()
        lspconfig[server_name].setup(
          vim.tbl_deep_extend("force", default_server_config, server_specific_config)
        )
      end
    end
    require("mason-lspconfig").setup_handlers(server_config_handlers)

    -- Set the filetype of all the currently open buffers to trigger a 'FileType' event for each
    -- buffer so nvim_lsp has a chance to attach to any buffers that were openeed before it was
    -- configured. This way I can load nvim_lsp asynchronously.
    local buffer = vim.fn.bufnr()
    vim.cmd([[
        silent! bufdo silent! lua vim.o.filetype = vim.o.filetype
      ]])
    vim.cmd.b(buffer)
  end,
})

Plug("neovim/nvim-lspconfig", {
  config = function()
    require("lspconfig.ui.windows").default_options.border =
      { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" }
  end,
})

Plug("b0o/SchemaStore.nvim")

-- }}}

-- CLI to LSP {{{
-- A language server that acts as a bridge between neovim's language server client and commandline
-- tools that don't support the language server protocol. It does this by transforming the output of
-- a commandline tool into the format specified by the language server protocol.
Plug("nvimtools/none-ls.nvim", {
  config = function()
    local null_ls = require("null-ls")
    local builtins = null_ls.builtins
    null_ls.setup({
      border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
      sources = {
        builtins.code_actions.shellcheck.with({
          filetypes = { "sh", "bash" },
        }),
        builtins.diagnostics.fish,
        builtins.diagnostics.markdownlint_cli2,
        builtins.diagnostics.markdownlint,
        builtins.diagnostics.actionlint,
      },
    })
  end,
})
-- }}}

-- Color scheme {{{
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
  vim.api.nvim_set_hl(0, "TabLine", { ctermbg = 51, ctermfg = 51 })
  vim.api.nvim_set_hl(0, "TabLineFill", { link = "TabLine" })
  vim.api.nvim_set_hl(0, "TabLineSel", { link = "TabLine" })
  vim.api.nvim_set_hl(0, "Comment", { ctermfg = 15, ctermbg = "NONE" })
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
  vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { ctermfg = 1, italic = true })
  vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { ctermfg = 3, italic = true })
  vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", { ctermfg = 4, italic = true })
  vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { ctermfg = 5, italic = true })
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
  vim.api.nvim_set_hl(0, "NavicText", { italic = true })
  vim.api.nvim_set_hl(0, "NavicSeparator", { ctermfg = 15 })
  vim.api.nvim_set_hl(0, "SignifyAdd", { ctermfg = 2 })
  vim.api.nvim_set_hl(0, "SignifyDelete", { ctermfg = 1 })
  vim.api.nvim_set_hl(0, "SignifyChange", { ctermfg = 3 })
  vim.api.nvim_set_hl(0, "QuickFixLine", { ctermfg = "NONE", ctermbg = 51 })
  vim.api.nvim_set_hl(0, "GitBlameVirtualText", { ctermfg = 15, italic = true })
  vim.api.nvim_set_hl(0, "Underlined", {})
  vim.api.nvim_set_hl(0, "NullLsInfoBorder", { link = "FloatBorder" })
  vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { ctermbg = "NONE", ctermfg = 15 })
  vim.api.nvim_set_hl(0, "MiniJump2dSpot", { ctermbg = "NONE", ctermfg = 3 })
  vim.api.nvim_set_hl(0, "MiniJump2dSpotUnique", { link = "MiniJump2dSpot" })
  vim.api.nvim_set_hl(0, "MiniJump2dSpotAhead", { link = "MiniJump2dSpot" })
  vim.api.nvim_set_hl(0, "MiniJump2dDim", { ctermbg = "NONE", ctermfg = 15 })

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
-- }}}

-- Install Missing Plugins {{{
vim.api.nvim_create_autocmd("User", {
  pattern = "PlugEndPost",
  callback = function()
    local plugs = vim.g.plugs or {}
    local missing_plugins = {}
    for name, info in pairs(plugs) do
      local is_installed = vim.fn.isdirectory(info.dir) ~= 0
      if not is_installed then
        missing_plugins[name] = info
      end
    end

    -- checking for empty table
    if next(missing_plugins) == nil then
      return
    end

    local missing_plugin_names = {}
    for key, _ in pairs(missing_plugins) do
      table.insert(missing_plugin_names, key)
    end

    local install_prompt = string.format(
      "The following plugins are not installed:\n%s\nWould you like to install them?",
      table.concat(missing_plugin_names, ", ")
    )
    local should_install = vim.fn.confirm(install_prompt, "yes\nno") == 1
    if should_install then
      vim.cmd(string.format("PlugInstall --sync %s", table.concat(missing_plugin_names, " ")))
    end
  end,
  group = vim.api.nvim_create_augroup("InstallMissingPlugins", {}),
})
-- }}}

-- }}}
