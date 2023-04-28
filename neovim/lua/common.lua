-- vim:foldmethod=marker

-- Miscellaneous {{{
vim.opt.nrformats:remove('octal')
vim.o.timeout = true
vim.o.timeoutlen = 500
vim.o.updatetime = 500
vim.o.swapfile = false
vim.o.fileformats = 'unix,dos,mac'
vim.o.paragraphs = ''
vim.o.sections = ''

local group_id = vim.api.nvim_create_augroup('ExtendIskeyword', {})
vim.api.nvim_create_autocmd(
  'FileType',
  {
    pattern = 'txt',
    callback = function() vim.opt_local.iskeyword:append('_') end,
    group = group_id,
  }
)
vim.api.nvim_create_autocmd(
  'FileType',
  {
    pattern = 'tmux',
    callback = function() vim.opt_local.iskeyword:append('-') end,
    group = group_id,
  }
)
vim.api.nvim_create_autocmd(
  'FileType',
  {
    pattern = {'css', 'scss', 'javascriptreact', 'typescriptreact', 'javascript', 'typescript', 'sass', 'postcss',},
    callback = function() vim.opt_local.iskeyword:append('-,?,!') end,
    group = group_id,
  }
)

vim.keymap.set({'i'}, 'jk', '<Esc>')

-- 1. reindent the pasted text
-- 2. move to the end of the pasted text
vim.keymap.set({'n'}, 'p', 'p=`]', {silent = true})

-- select the text that was just pasted
vim.keymap.set({'n'}, 'gp', '`[v`]')

-- Prevents inserting two spaces after punctuation on a join (J)
vim.o.joinspaces = false

vim.o.formatoptions = ''
vim.opt.matchpairs:append('<:>')

-- move ten lines at a time by holding ctrl and a directional key
vim.keymap.set({'n'}, '<C-j>', '10j', {remap = true})
vim.keymap.set({'n'}, '<C-k>', '10k', {remap = true})
vim.keymap.set({'x'}, '<C-j>', '10j', {remap = true})
vim.keymap.set({'x'}, '<C-k>', '10k', {remap = true})

-- Always move by screen line, unless a count was specified or we're in a line-wise mode.
function move_by_screen_line(direction)
  mode = vim.fn.mode()
  is_in_linewise_mode = mode == 'V' or mode == ''
  if is_in_linewise_mode then
    return direction
  end

  if vim.v.count > 0 then
    return direction
  end

  return 'g' .. direction
end
vim.keymap.set({'n', 'x'}, 'j', function() return move_by_screen_line('j') end, {expr =true})
vim.keymap.set({'n', 'x'}, 'k', function() return move_by_screen_line('k') end, {expr =true})

-- Resizing panes
vim.keymap.set({'n'}, '<C-Left>', [[<Cmd>vertical resize +1<CR>]], {silent = true})
vim.keymap.set({'n'}, '<C-Right>', [[<Cmd>vertical resize -1<CR>]], {silent = true})
vim.keymap.set({'n'}, '<C-Up>', [[<Cmd>resize +1<CR>]], {silent = true})
vim.keymap.set({'n'}, '<C-Down>', [[<Cmd>resize -1<CR>]], {silent = true})

-- Copy up to the end of line, not including the newline character
vim.keymap.set({'n'}, 'Y', 'yg_')

-- Using the paragraph motions won't add to the jump stack
vim.keymap.set({'n'}, '}', [[<Cmd>keepjumps normal! }<CR>]])
vim.keymap.set({'n'}, '{', [[<Cmd>keepjumps normal! {<CR>]])

-- 'n' always searches forwards, 'N' always searches backwards
vim.keymap.set({'n'}, 'n', "'Nn'[v:searchforward]", {expr = true})
vim.keymap.set({'x'}, 'n', "'Nn'[v:searchforward]", {expr = true})
vim.keymap.set({'o'}, 'n', "'Nn'[v:searchforward]", {expr = true})
vim.keymap.set({'n'}, 'N', "'nN'[v:searchforward]", {expr = true})
vim.keymap.set({'x'}, 'N', "'nN'[v:searchforward]", {expr = true})
vim.keymap.set({'o'}, 'N', "'nN'[v:searchforward]", {expr = true})

-- Enter a newline above or below the current line.
vim.keymap.set({'n'}, '<Enter>', 'o<ESC>')

-- TODO: This won't work until tmux can differentiate between enter and shift+enter.
-- tmux issue: https://github.com/tmux/tmux/issues/2705#issuecomment-841133549
vim.keymap.set({'n'}, '<S-Enter>', 'O<ESC>')

-- Disable language providers. Feels like a lot of trouble to install neovim bindings for all these languages
-- so I'll just avoid plugins that require them. By disabling the providers, I won't get a warning about
-- missing bindings when I run ':checkhealth'.
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0

vim.keymap.set({'n'}, 'Q', '<Nop>')

-- Execute macros more quickly by enabling lazyredraw and disabling events while the macro is running
local function get_char()
  local ret_val, char_num = pcall(vim.fn.getchar)
  -- Return nil if error (e.g. <C-c>) or for control characters
  if not ret_val or char_num < 32 then
      return nil
  end
  local char = vim.fn.nr2char(char_num)

  return char
end
_G.fast_macro = function()
  mode = vim.fn.mode()
  count = vim.v.count1
  vim.cmd('execute "normal \\<Esc>"')

  range = ''
  for _, visual_mode in pairs({'v', 'V', ''}) do
    if mode == visual_mode then
      range = [['<,'>]]
      break
    end
  end

  local register = get_char()
  if register == nil then
    return
  end

  vim.o.eventignore = 'all'
  vim.o.lazyredraw = true
  vim.cmd(
    string.format(
      [[%snormal! %s@%s]],
      range,
      count,
      register
    )
  )
  vim.o.eventignore = ''
  vim.o.lazyredraw = false
end
vim.keymap.set({'x', 'n'}, '@', '<Cmd>lua fast_macro()<CR>')
local group_id = vim.api.nvim_create_augroup('FastMacro', {})
vim.api.nvim_create_autocmd(
  'RecordingEnter',
  {
    callback = function()
      if vim.g.fast_macro_events == nil then
        events = vim.fn.getcompletion('', 'event')

        for index, event in ipairs(events) do
          if event == 'RecordingLeave' then
            table.remove(events, index)
            break
          end
        end

        vim.g.fast_macro_events = table.concat(events, ',')
      end

      vim.g.old_eventignore = vim.o.eventignore
      vim.o.eventignore = vim.g.fast_macro_events
    end,
    group = group_id,
  }
)
vim.api.nvim_create_autocmd(
  'RecordingLeave',
  {
    callback = function()
      vim.o.eventignore = vim.g.old_eventignore
    end,
    group = group_id,
  }
)

vim.o.clipboard = 'unnamedplus'

-- Move to beginning and end of line
vim.keymap.set({'n'}, '<C-a>', '^')
vim.keymap.set({'n'}, '<C-e>', '$')
vim.keymap.set({'i'}, '<C-a>', '<ESC>^i')
vim.keymap.set({'i'}, '<C-e>', '<ESC>$a')

-- My terminal is configured to send F12 when I press <C-i> and neovim maps it back to <C-i> here.
-- TODO: When tmux is able to differentiate between tab and ctrl+i this mapping should be removed.
-- tmux issue: https://github.com/tmux/tmux/issues/2705#issuecomment-841133549
--
-- move forward in the jumplist
vim.keymap.set({"n"}, "<F12>", '<C-i>')
-- }}}

-- Option overrides {{{
local group_id = vim.api.nvim_create_augroup('VimDefaultOverrides', {})

-- Vim's default filetype plugins get run when filetype detection is enabled (i.e. ':filetype plugin on').
-- So in order to override settings from vim's filetype plugins, these FileType autocommands need to be registered
-- after filetype detection is enabled. Filetype detection is turned on in plug_end() so this function gets called at
-- PlugEndPost, which is right after plug_end() is called.
local function override_default_filetype_plugins()
  -- Don't automatically hard-wrap text
  vim.api.nvim_create_autocmd(
    'FileType',
    {
      pattern = '*',
      callback = function()
        vim.opt_local.textwidth = 0
        vim.opt_local.wrapmargin = 0
      end,
      group = group_id,
    }
  )

  -- Use vim help pages for keywordprg in vim files
  vim.api.nvim_create_autocmd(
    'FileType',
    {
      pattern = 'vim',
      callback = function() vim.opt_local.keywordprg = ':tab help' end,
      group = group_id,
    }
  )
end

vim.api.nvim_create_autocmd(
  'User',
  {
    pattern = 'PlugEndPost',
    callback = override_default_filetype_plugins,
    group = group_id,
  }
)
-- }}}

-- Searching {{{
-- searching is only case sensitive when the query contains an uppercase letter
vim.o.ignorecase = true
vim.o.smartcase = true

-- Use ripgrep as the grep program, if it's available. Otherwise use the internal
-- grep implementation since it's cross-platform
vim.o.grepprg = vim.fn.executable('rg') and 'rg --vimgrep --smart-case --follow' or 'internal'

-- Search for selected text, forwards or backwards.
vim.keymap.set(
  {'v'},
  '*',
  [[:<C-U>let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>gvy/<C-R>=&ic?'\c':'\C'<CR><C-R><C-R>=substitute(escape(@", '/\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>gVzv:call setreg('"', old_reg, old_regtype)<CR>]],
  {silent = true}
)
vim.keymap.set(
  {'v'},
  '#',
  [[:<C-U>let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>gvy?<C-R>=&ic?'\c':'\C'<CR><C-R><C-R>=substitute(escape(@", '?\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>gVzv:call setreg('"', old_reg, old_regtype)<CR>]],
  {silent = true}
)
-- }}}

-- Plugins {{{
-- Motions for levels of indentation
Plug(
  'jeetsukumaran/vim-indentwise',
  {
    config = function()
      vim.keymap.set('', '[-', '<Plug>(IndentWisePreviousLesserIndent)', {remap = true})
      vim.keymap.set('', '[+', '<Plug>(IndentWisePreviousGreaterIndent)', {remap = true})
      vim.keymap.set('', '[=', '<Plug>(IndentWisePreviousEqualIndent)', {remap = true})
      vim.keymap.set('', ']-', '<Plug>(IndentWiseNextLesserIndent)', {remap = true})
      vim.keymap.set('', ']+', '<Plug>(IndentWiseNextGreaterIndent)', {remap = true})
      vim.keymap.set('', ']=', '<Plug>(IndentWiseNextEqualIndent)', {remap = true})
    end
  }
)
vim.g.indentwise_suppress_keymaps = 1

-- replacement for matchit since matchit wasn't working for me
Plug('andymass/vim-matchup')
-- Don't display offscreen matches in my statusline or a popup window
vim.g.matchup_matchparen_offscreen = {}

-- Additional text objects and motions
Plug('wellle/targets.vim')

Plug('bkad/CamelCaseMotion')
vim.g.camelcasemotion_key = ','

-- Makes it easier to manipulate brace/bracket/quote pairs by providing commands to do common
-- operations like change pair, remove pair, etc.
Plug(
  'kylechui/nvim-surround',
  {
    config = function()
      require("nvim-surround").setup()
    end,
  }
)

-- For swapping two pieces of text
Plug('tommcdo/vim-exchange')

-- Commands/mappings for working with variants of words:
-- - A command for performing substitutions. More features than vim's builtin :substitution
-- - A command for creating abbreviations. More features than vim's builtin :iabbrev
-- - Mappings for case switching e.g. mixed-case, title-case, etc.
Plug('tpope/vim-abolish')

-- Text object for text at the same level of indentation
Plug(
  'michaeljsmith/vim-indent-object',
  {
    config = function()
      -- Make 'ai' and 'ii' behave like 'aI' and 'iI' respectively
      vim.keymap.set('o', 'ai', 'aI', {remap = true})
      vim.keymap.set('x', 'ai', 'aI', {remap = true})
      vim.keymap.set('o', 'ii', 'iI', {remap = true})
      vim.keymap.set('x', 'ii', 'iI', {remap = true})
    end,
  }
)

-- Extend the types of text that can be incremented/decremented
Plug(
  'monaqa/dial.nvim',
  {
    on = {'<Plug>(dial-increment)', '<Plug>(dial-decrement)'},
    config = function()
      local augend = require("dial.augend")

      local function words(...)
        return augend.constant.new({
          elements = {...},
          word = true,
          cyclic = true,
        })
      end

      local function symbols(...)
        return augend.constant.new({
          elements = {...},
          word = false,
          cyclic = true,
        })
      end

      require('dial.config').augends:register_group({
        default = {
          -- color: #ffffff
          -- NOTE: If the cursor is over one of the two digits in the red, green, or blue value, it only increments
          -- that color of the hex. To increment the red, green, and blue portions, the cursor must be over the '#'.
          augend.hexcolor.new({}),
          -- time: 14:30:00
          augend.date.alias["%H:%M:%S"],
          -- time: 14:30
          augend.date.alias["%H:%M"],
          -- decimal integer: 0, 4, -123
          augend.integer.alias.decimal_int,
          -- hex: 0x00
          augend.integer.alias.hex,
          -- binary: 0b0101
          augend.integer.alias.binary,
          -- octal: 0o00
          augend.integer.alias.octal,
          -- semver: 1.22.1
          augend.semver.alias.semver,
          -- uppercase letter: A
          augend.constant.alias.Alpha,
          -- lowercase letter: a
          augend.constant.alias.alpha,
          words('and', 'or'),
          words('public', 'private'),
          words('true', 'false'),
          words('True', 'False'),
          words('yes', 'no'),
          symbols('&&', '||'),
          symbols('!=', '=='),
          symbols('<', '>'),
          symbols('<=', '>='),
          symbols('+=', '-='),
        },
      })
    end,
  }
)
vim.keymap.set("n", "+", '<Plug>(dial-increment)')
vim.keymap.set("n", "-", '<Plug>(dial-decrement)')
vim.keymap.set("v", "+", '<Plug>(dial-increment)')
vim.keymap.set("v", "-", '<Plug>(dial-decrement)')
vim.keymap.set("v", "g+", 'g<Plug>(dial-increment)')
vim.keymap.set("v", "g-", 'g<Plug>(dial-decrement)')

Plug 'arthurxavierx/vim-caser'
-- }}}
