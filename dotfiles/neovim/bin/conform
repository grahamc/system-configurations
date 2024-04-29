#!/usr/bin/env bash

# For more on how the file printing from vim works:
# https://vi.stackexchange.com/questions/23198/vim-ex-mode-write-to-stdout
#
# TODO: Without using printf, I get a segfault when I do `cat <file> | conform`
#
# Using `%print` wasn't working so I'm using `io.write` instead.
printf %s "$(nvim -u "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/init.lua" -Es -c "lua vim.api.nvim_buf_set_name(0, '$2')" -c "set ft=$1" -c 'lua require("conform").format()' -c 'redi! > /dev/stdout' -c 'lua io.write(vim.iter(vim.api.nvim_buf_get_lines(0, 0, -1, true)):join("\n"))' -c 'redi END')"
