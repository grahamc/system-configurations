-- Enabling this will cache any lua modules that are required after this point.
vim.loader.enable()

-- My configuration is mixed in with my plugin defintions so I have to do everything here.
require("plug").load_plugins(function(plug)
  -- expose the function to the profiles
  function Plug(...)
    plug(...)
  end

  local has_ttyin = vim.fn.has("ttyin") == 1
  local has_ttyout = vim.fn.has("ttyout") == 1
  IsRunningInTerminal = has_ttyout or has_ttyin

  require("base")
  require("terminal")
  require("vscode")
  require("browser")
end)
