-- vim:foldmethod=marker

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
    vim.ui.open(cfile)
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

vim.o.shortmess = "ltToOFs"

-- I have a mapping in my terminal for <C-i> that sends F9 to get around the fact that TMUX
-- considers <C-i> the same as <Tab> right now since TMUX lost support for extended keys.
-- TODO: tmux issue: https://github.com/tmux/tmux/issues/2705#issuecomment-841133549
vim.keymap.set({ "n" }, "<F9>", "<C-i>")

-- Use shift+u to redo the last undone change
vim.keymap.set({ "n" }, "<S-u>", "<C-r>")

-- colorcolumn {{{
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
    vim.wo.colorcolumn = tostring(require("utilities").get_max_line_length() + 1)
    vim.w.old_colorcolumn = vim.wo.colorcolumn
  end,
  group = colorcolumn_group_id,
})

Plug("lukas-reineke/virt-column.nvim", {
  config = function()
    require("virt-column").setup({ char = "│" })
  end,
})
-- }}}

-- Quickfix {{{
local function toggle_quickfix()
  local qf_exists = false
  for _, win in pairs(vim.fn.getwininfo() or {}) do
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
-- TODO: When I leave insert mode on a line with just spaces (e.g. enter 'ojk' from a line that's
-- indented at least once) the automatic removal of extra spaces isn't triggering TextChanged{I} so
-- I added ModeChanged to catch that.
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "ModeChanged" }, {
  callback = enqueue_save_task,
  group = vim.api.nvim_create_augroup("Autosave", {}),
})
-- }}}

-- Tabs {{{
vim.keymap.set({ "n", "i" }, "<C-M-[>", vim.cmd.tabprevious, { silent = true })
vim.keymap.set({ "n", "i" }, "<C-M-]>", vim.cmd.tabnext, { silent = true })
vim.keymap.set({ "n" }, "<C-t>", function()
  vim.cmd.tabnew("%")
end, { silent = true })
vim.keymap.set({ "n" }, "<C-M-w>", vim.cmd.tabclose, { silent = true })
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

Plug("tpope/vim-sleuth")
-- }}}

-- Command line {{{
-- on first wildchar press (<Tab>), show all matches and complete the longest common substring among
-- on them. subsequent wildchar presses, cycle through matches
vim.o.wildmode = "longest:full,full"
vim.o.wildoptions = "pum"
vim.o.cmdheight = 0
vim.o.showcmdloc = "statusline"
vim.keymap.set("c", "<C-a>", "<C-b>", { remap = true })
vim.keymap.set({ "ca" }, "lua", function()
  if vim.fn.getcmdtype() == ":" and vim.fn.getcmdline() == "lua" then
    return "lua="
  else
    return "lua"
  end
end, { expr = true })
vim.keymap.set({ "ca" }, "h", function()
  if vim.fn.getcmdtype() == ":" and vim.fn.getcmdline() == "h" then
    vim.g.opening_help_in_tab = true
    return "tab help"
  else
    return "h"
  end
end, { expr = true })
-- }}}

-- Search {{{
vim.o.hlsearch = false
-- toggle search highlighting
vim.keymap.set("n", [[\]], "<Cmd>set hlsearch!<CR>", { silent = true })
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

Plug("nvim-lua/plenary.nvim")
Plug("kkharji/sqlite.lua")

Plug("stevearc/dressing.nvim", {
  config = function()
    require("dressing").setup({
      input = { enabled = false },
    })
  end,
})

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

Plug("iamcco/markdown-preview.nvim")

-- TODO: I'll keep using this fork until this PR is merged:
-- https://github.com/NvChad/nvim-colorizer.lua/pull/63
Plug("mehalter/nvim-colorizer.lua", {
  config = function()
    require("colorizer").setup({
      filetypes = {
        "*", -- Highlight all files, but customize some others.
        cmp_docs = { always_update = true },
      },
      user_default_options = {
        mode = "inline",
        virtualtext = "  ",
        css = true,
        tailwind = "lsp",
        sass = { enable = true, parsers = { "css" } },
      },
    })
  end,
})

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
