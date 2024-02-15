-- Exit if vim is not running in a terminal (also referred to as a TTY). I detect this by
-- checking if the input to vim is coming from a terminal or vim is outputting to a terminal.
local has_ttyin = vim.fn.has("ttyin") == 1
local has_ttyout = vim.fn.has("ttyout") == 1
if not has_ttyin and not has_ttyout then
  return
end

require("terminal.aesthetic")
require("terminal.statusbars")
require("terminal.autocomplete")
require("terminal.folds")
require("terminal.git")
require("terminal.lsp")
require("terminal.misc")
require("terminal.notifications")
require("terminal.pager")
require("terminal.sessions")
require("terminal.telescope")
require("terminal.tools")
require("terminal.windows")
require("terminal.discovery")
require("terminal.quickfix")
require("terminal.file-explorer")
