vim.g.colors_name = "my_dark_theme"

-- Force the colorscheme module to reload so it can pick up the new vim.g.colors_name
package.loaded["terminal.aesthetic.colorschemes.light_and_dark"] = nil

-- include our theme file and pass it to lush to apply
require("lush")(require("terminal.aesthetic.colorschemes.light_and_dark"))
