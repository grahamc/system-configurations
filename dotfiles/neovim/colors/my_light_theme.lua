vim.g.colors_name = "my_light_theme"

-- include our theme file and pass it to lush to apply
require("lush")(require("terminal.aesthetic.colorschemes.light"))
