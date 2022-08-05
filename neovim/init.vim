lua << EOF
-- Disable unused builtin plugins.
plugins_to_disable = {
  "netrw",
  "netrwPlugin",
  "netrwSettings",
  "netrwFileHandlers",
  "gzip",
  "zip",
  "zipPlugin",
  "tar",
  "tarPlugin",
  "getscript",
  "getscriptPlugin",
  "vimball",
  "vimballPlugin",
  "2html_plugin",
  "logipat",
  "rrhelper",
  "spellfile_plugin",
  "matchit",
}

for _, plugin in pairs(plugins_to_disable) do
  vim.g["loaded_" .. plugin] = 1
end
EOF

" Variables used across config files
let g:mapleader = "\<Space>"
let g:data_path = stdpath('data')
let g:profiles = []
let profile_directory = expand('<sfile>:h') . '/profiles'
if isdirectory(profile_directory)
  let g:profiles = split(globpath(profile_directory, '*'), '\n')
endif

" Install vim-plug if not found
let vim_plug_plugin_file = g:data_path . '/site/autoload/plug.vim'
if empty(glob(vim_plug_plugin_file))
  silent execute '!curl -fLo '.vim_plug_plugin_file.' --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif

" Calling this before I load the profiles so I can register plugins inside them
call plug#begin()

" Load profiles
for profile in g:profiles
  execute 'source ' . profile
endfor

" Calling this after I load the profiles so I can register plugins inside them
call plug#end()

" This way the profiles can run code after plugins are loaded, but before 'VimEnter'
doautocmd User PlugEndPost
