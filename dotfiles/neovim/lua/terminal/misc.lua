-- vim:foldmethod=marker

vim.o.mouse = "a"
vim.o.scrolloff = 999
vim.o.jumpoptions = "stack"
vim.o.mousemoveevent = true

-- open links with browser {{{
--
-- Mostly taken from here:
-- https://github.com/MariaSolOs/dotfiles/blob/da291d841447ed7daddcf3f9d3c66ed04e025b50/.config/nvim/lua/lsp.lua#L232C17-L248C20
local function open(path)
  local _, err = vim.ui.open(path)
  if err ~= nil then
    vim.notify(string.format("Failed to open path '%s'\n%s", path, err), vim.log.levels.ERROR)
  end
end
local function get_url_under_cursor()
  local cfile = vim.fn.expand("<cfile>")
  local is_url = cfile:match(
    "https?://(([%w_.~!*:@&+$/?%%#-]-)(%w[-.%w]*%.)(%w%w%w?%w?)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))"
  ) or cfile:match(
    "ftps?://(([%w_.~!*:@&+$/?%%#-]-)(%w[-.%w]*%.)(%w%w%w?%w?)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))"
  )
  if is_url then
    return cfile
  end

  return nil
end
function OpenUrlUnderCursor(is_mouse_click)
  -- wrap in function so I can return early
  (function()
    -- Vim help links.
    local vim_help_tag = (vim.fn.expand("<cWORD>") --[[@as string]]):match("|(%S-)|")
    if vim_help_tag then
      vim.cmd.Help(vim_help_tag)
      return
    end

    -- Markdown links.
    local col = vim.api.nvim_win_get_cursor(0)[2] + 1
    local from, to, url = vim.api.nvim_get_current_line():find("%[.-%]%((%S-)%)")
    if from and col >= from and col <= to then
      open(url)
      return
    end

    url = get_url_under_cursor()
    if url ~= nil then
      open(url)
    end
  end)()

  if is_mouse_click then
    -- If we are in am LSP hover, jump back to previous window. This way I can click a link in a
    -- documentation/diagnostic float and stay in the editing window.
    if IsInsideLspHoverOrSignatureHelp then
      vim.cmd.wincmd("p")
    end
  end
end
vim.keymap.set("n", "U", OpenUrlUnderCursor, { desc = "Open link" })
vim.keymap.set("n", "<C-LeftMouse>", "<LeftMouse><Cmd>lua OpenUrlUnderCursor(true)<CR>")
-- }}}

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
-- Get help buffers to open in the current window. Source: https://stackoverflow.com/a/26431632
vim.api.nvim_create_user_command("Help", function(context)
  vim.cmd.enew()
  vim.bo.buftype = "help"
  vim.cmd.help(context.args)
  vim.bo.buflisted = true
  -- some help pages, like vim-signify, have the filetype "text" so I'll change that
  vim.bo.filetype = "help"
end, {
  complete = "help",
  nargs = 1,
})

vim.o.confirm = true
vim.keymap.set("", "<C-x>", function()
  vim.cmd.qall()
end, {
  desc = "Quit [exit,close]",
})

-- suspend vim
vim.keymap.set({ "n", "i", "x" }, "<C-z>", "<Cmd>suspend<CR>", {
  desc = "Suspend [background]",
})

vim.o.shell = "sh"

vim.keymap.set("n", "<BS>", "<C-^>", {
  desc = "Last window",
})

vim.o.ttimeout = true
vim.o.ttimeoutlen = 50

vim.o.scroll = 1
vim.o.smoothscroll = true

vim.o.shortmess = "ltToOFs"

-- I have a mapping in my terminal for <C-i> that sends F9 to get around the fact that TMUX
-- considers <C-i> the same as <Tab> right now since TMUX lost support for extended keys.
-- TODO: tmux issue: https://github.com/tmux/tmux/issues/2705#issuecomment-841133549
vim.keymap.set({ "n" }, "<F9>", "<C-i>")

-- colorcolumn {{{
Plug("lukas-reineke/virt-column.nvim", {
  config = function()
    require("virt-column").setup({ char = "│" })
  end,
})

Plug("m4xshen/smartcolumn.nvim", {
  config = function()
    require("smartcolumn").setup({
      scope = "window",
      custom_colorcolumn = function()
        return tostring(require("utilities").get_max_line_length() + 1)
      end,
      disable_filetypes = {
        "qf",
        "help",
        "text",
        "NvimTree",
        "lspinfo",
        "mason",
      },
    })
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
vim.keymap.set("n", "<M-q>", toggle_quickfix, {
  desc = "Toggle quickfix",
})
-- }}}

-- Autosave {{{
--
-- TODO: These issues may affect how I want to do this:
-- https://github.com/neovim/neovim/pull/20801
-- https://github.com/neovim/neovim/issues/1380
-- https://github.com/neovim/neovim/issues/12605
--
-- TODO: When I call checktime after pressing something like 'cin' in normal mode, I get
-- E565 which doesn't make sense since I don't think complete mode was active, mini.ai was
-- just prompting me for a char. In any case, I tried checking if completion mode was active
-- first, but it wasn't so I still got this error. So now I'm just using pcall which isn't ideal
-- since it will suppress other errors too.
local function checktime()
  return pcall(vim.cmd.checktime)
end
vim.uv.new_timer():start(
  0,
  500,
  vim.schedule_wrap(function()
    -- you can't run checktime in the commandline
    if vim.fn.getcmdwintype() ~= "" then
      return
    end

    local success = checktime()
    if not success then
      return
    end

    -- check for changes made outside of vim
    -- give buffers a chance to update via 'autoread'
    vim.defer_fn(function()
      vim.cmd([[
        silent! wall
      ]])
    end, 300)
  end)
)
-- Check for changes made outside of vim. Source:
-- https://unix.stackexchange.com/questions/149209/refresh-changed-content-of-file-opened-in-vim/383044#383044
vim.api.nvim_create_autocmd(
  { "FocusGained", "BufEnter", "CursorHold", "CursorHoldI", "VimResume" },
  {
    group = vim.api.nvim_create_augroup("Autosave", {}),
    callback = function()
      -- you can't run checktime in the commandline
      if vim.fn.getcmdwintype() ~= "" then
        return
      end
      checktime()
    end,
  }
)
-- }}}

-- Tabs {{{
vim.keymap.set(
  { "n", "i" },
  "<C-M-[>",
  vim.cmd.tabprevious,
  { silent = true, desc = "Previous tab" }
)
vim.keymap.set({ "n", "i" }, "<C-M-]>", vim.cmd.tabnext, { silent = true, desc = "Next tab" })
vim.keymap.set({ "n" }, "<C-t>", function()
  vim.cmd.tabnew("%")
end, { silent = true, desc = "New tab" })
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
    return "Help"
  else
    return "h"
  end
end, { expr = true })
-- }}}

vim.o.hlsearch = false

-- toggle search highlighting, whitespace indicators, and indent guides
vim.keymap.set(
  "n",
  [[\/]],
  "<Cmd>set hlsearch!<CR>",
  { silent = true, desc = "Toggle search highlight" }
)
vim.keymap.set(
  "n",
  [[\ ]],
  "<Cmd>set list!<CR>",
  { silent = true, desc = "Toggle whitespace indicator" }
)
vim.keymap.set("n", [[\|]], function()
  vim.g.miniindentscope_disable = not vim.g.miniindentscope_disable
  return "lh"
end, { silent = true, expr = true, desc = "Toggle indent guide" })

-- Terminal {{{
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.opt_local.signcolumn = "no"
    vim.opt_local.statuscolumn = ""
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.cmd.startinsert()
  end,
})
-- TODO: see if reticle.nvim can support disabling by buftype
local terminal_group_id = vim.api.nvim_create_augroup("bigolu/terminal", {})
vim.api.nvim_create_autocmd("TermEnter", {
  group = terminal_group_id,
  callback = function()
    require("reticle").set_cursorline(false)
  end,
})
vim.api.nvim_create_autocmd("TermLeave", {
  group = terminal_group_id,
  callback = function()
    require("reticle").set_cursorline(true)
  end,
})
-- }}}

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
      input = {
        enabled = true,
        default_prompt = "Input:",
        trim_prompt = false,
        border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
        relative = "editor",
        prefer_width = 0.5,
        width = 0.5,
        max_width = 500,
      },
      select = {
        get_config = function(options)
          if options.kind == "legendary.nvim" then
            return {
              telescope = {
                -- favor entries that I've selected recently
                sorter = require("telescope.sorters").fuzzy_with_index_bias({}),
              },
            }
          end
        end,
      },
    })

    local dressing_group = vim.api.nvim_create_augroup("MyDressing", {})
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "DressingInput",
      group = dressing_group,
      callback = function()
        -- After I accept an autocomplete entry from nvim-cmp, buflisted gets set to true so
        -- this sets it back to false.
        vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
          group = dressing_group,
          buffer = vim.api.nvim_get_current_buf(),
          callback = function()
            vim.bo.buflisted = false
          end,
        })
      end,
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
        css = { names = true },
      },
      user_default_options = {
        mode = "inline",
        virtualtext = "  ",
        css = true,
        names = false,
        tailwind = "lsp",
        sass = { enable = true, parsers = { "css" } },
      },
    })

    vim.keymap.set("n", [[\c]], function()
      vim.cmd.ColorizerToggle()
    end, { silent = true, desc = "Toggle inlay colors" })
  end,
})
