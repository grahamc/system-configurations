-- This lets you use the hammerspoon commandline tool
require("hs.ipc")
hs.ipc.cliInstall()

-- Create annotations that lua language servers can use to provide documentation, autocomplete, etc.
hs.loadSpoon("EmmyLua", false)

hs.loadSpoon("Speakers")

require("stackline"):init()

local icons = {
  bsp = [[ASCII:
1 · · · · · · 4 · 6 · · · · · · 9
· · · · · · · · · · · · · · · · ·
· · · · · · · · · · · · · · · · ·
· · · · · · · · · · · · · · · · ·
· · · · · · · · · · · · · · · · ·
· · · · · · · · · 7 · · · · · · 8
· · · · · · · · · · · · · · · · ·
· · · · · · · · · B · · · · · · E
· · · · · · · · · · · · · · · · ·
· · · · · · · · · · · · · · · · ·
· · · · · · · · · · · · · · · · ·
· · · · · · · · · · · · · · · · ·
2 · · · · · · 3 · C · · · · · · D
]],
  float = [[ASCII:
· · · · · · · 2 · · · · · · · · · 1
· · · · · · · · · · · · · · · · · ·
· · · · · · · 3 · · · 4 · · · · · ·
· · · · · · · · · · · · · · · · · ·
H · · · · · · · · I · · · · · · · ·
· · · · · · · · · · · · · · · · · ·
· · · · · · · · · · · · · · · · · ·
· · · · · · · · · · · 5 · · · · · 6
· · · · · · · · · · · · · · · · · ·
· · · · · · · · · · · 9 · · · 8 · ·
G · · · · · · · · F · · · · · · · ·
· · · · · · · · · · · · · · · · · ·
· · · · · B · · · · · A · · · · · ·
· · · · · · · · · · · · · · · · · ·
· · · · · C · · · · · · · · · D · ·
]],
}

local function execute(executable, arguments, callback)
  -- I'm using hs.task because os.execute was really slow. For more on why os.execute was slow see here:
  -- https://github.com/Hammerspoon/hammerspoon/issues/2570
  hs.task.new(executable, callback, arguments):start()
end

local function toggle_tiling_mode()
  execute(
    "/usr/local/bin/yabai",
    { "-m", "config", "layout" },
    function(_, stdout, _)
      local layout = "bsp"
      if stdout == "bsp\n" then
        layout = "float"
      end
      execute(
        "/usr/local/bin/yabai",
        { "-m", "config", "layout", layout },
        function()
          menubar_item:setIcon(icons[layout])
        end
      )
    end
  )
end

local function getShortcutsHtml()
  local commandEnum = {
    cmd = "⌘",
    shift = "⇧",
    alt = "⌥",
    ctrl = "⌃",
    fn = "Fn",
  }

  local direction_key_label = "&lt;direction&gt;"

  local shortcuts = {
    {
      title = "Direction Keys",
      items = {
        {
          mods = {},
          key = "h&nbsp; j&nbsp; k&nbsp; l",
          description = "Move left, down, up, and right respectively (like Vim)",
        },
      },
    },
    {
      title = "Navigate windows",
      items = {
        {
          mods = { "cmd" },
          key = direction_key_label,
          description = "Switch focus between windows",
        },
      },
    },
    {
      title = "Move windows",
      items = {
        {
          mods = { "cmd", "shift" },
          key = direction_key_label,
          description = "Move window",
        },
        {
          mods = { "cmd", "ctrl" },
          key = direction_key_label,
          description = "Swap window",
        },
        {
          mods = { "cmd" },
          key = "o",
          description = "Rotate windows clockwise",
        },
        {
          mods = { "cmd", "shift" },
          key = "o",
          description = "Rotate windows counter-clockwise",
        },
        {
          mods = { "cmd" },
          key = "g",
          description = "Toggle floating mode",
        },
        {
          mods = { "cmd" },
          key = "s",
          description = "Toggle stacking mode (Next window opened will open on top of the current one)",
        },
      },
    },
    {
      title = "Resize Windows",
      items = {
        {
          mods = { "cmd" },
          key = "m",
          description = "Toggle fullscreen zoom",
        },
        {
          mods = { "cmd", "shift" },
          key = "m",
          description = "Toggle parent zoom",
        },
        {
          mods = { "cmd", "shift" },
          key = "0",
          description = "Reset all window sizes so that they share space evenly",
        },
      },
    },
  }

  local menu = ""
  for index, shortcut_group in ipairs(shortcuts) do
    menu = menu .. "<ul class='col col" .. index .. "'>"
    menu = menu
      .. "<li class='title group-title'><strong>"
      .. shortcut_group.title
      .. "</strong></li>"

    for _, shortcut in ipairs(shortcut_group.items) do
      local mods = ""
      for _, value in ipairs(shortcut.mods) do
        mods = mods .. commandEnum[value]
      end
      local shortcut_key = shortcut.key
      menu = menu
        .. "<li class='keybinds'><div class='cmdModifiers'>"
        .. mods
        .. " "
        .. shortcut_key
        .. "</div><div class='cmdtext'>"
        .. " "
        .. shortcut.description
        .. "</div></li>"
    end

    menu = menu .. "</ul>"
  end

  return menu
end

local function generateHtml()
  local app_title = "Tiling Mode Shortcuts"
  local shortcuts_html = getShortcutsHtml()

  local function rtrim(s)
    local n = #s
    while n > 0 and s:find("^%s", n) do
      n = n - 1
    end
    return s:sub(1, n)
  end
  local stdout = hs.execute("defaults read -g AppleInterfaceStyle")
  -- Hammerspoon docs for hs.execute say that there may be an extra newline at the end
  stdout = rtrim(stdout)
  local is_dark_mode = stdout == "Dark"
  local bg_color = is_dark_mode and "#292828" or "#eee"
  local fg_color = is_dark_mode and "#cbcbcb" or "#292828"

  local html = [[
        <!DOCTYPE html>
        <html>
        <head>
        <style type="text/css">
            *{margin:0; padding:0;}
            html, body{
              background-color: ]] .. bg_color .. [[;
              font-family: arial;
              font-size: 13px;
              color: ]] .. fg_color .. [[;
            }
            a{
              text-decoration:none;
              color: ]] .. fg_color .. [[;
            }
            li.title > strong{text-align: center;}
      li {
    display: flex;
    align-items: center;
    justify-content: center;
      }
            ul, li{list-style: inside none; padding: 0 0 5px;}
      ul {width: 20%;}
            header hr,
            .title{
                padding: 8px;
            }
            .group-title {
              border-bottom: 1px solid;
            }
            .keybinds {
              padding: 8px;
            }
            .col {
              border: 1px solid;
              border-radius: 10px;
            }
            header {
              text-align: center;
              margin-bottom: 20px;
              font-size: 1.5rem;
            }
            .maincontent{
        display:flex;
        justify-content: space-around;
            }
            .cmdModifiers{
              width: 50%;
              font-weight: bold;
            }
            .cmdtext{
              width: 50%;
            }
        </style>
        </head>
          <body>
            <header>
              <div class="title"><strong>]] .. app_title .. [[</strong></div>
            </header>
            <div class="content maincontent">]] .. shortcuts_html .. [[</div>
          </body>
        </html>
        ]]

  return html
end

local function open_help_page()
  local screen_rect = hs.screen.mainScreen():fullFrame()
  local help_page = hs
    .webview
    .new({
      x = 0 + screen_rect.w * 0.15 / 2,
      y = 0 + screen_rect.h * 0.50 / 2,
      w = screen_rect.w * 0.85,
      h = screen_rect.h * 0.50,
    })
    -- `windowStyle` exists so I'm disabling this lint
    ---@diagnostic disable-next-line: undefined-field
    :windowStyle({
      "closable",
      "titled",
      "fullSizeContentView",
      "texturedBackground",
      "nonactivating",
    })
    :closeOnEscape(true)
    :bringToFront(true)
    :deleteOnClose(true)
    :html(generateHtml())
  help_page:show()
end

local menu_items = {
  {
    title = "Show Tiling Mode Shortcuts",
    fn = open_help_page,
  },
  {
    title = "Toggle Tiling Mode",
    fn = toggle_tiling_mode,
  },
  {
    title = "Refresh Hammerspoon",
    fn = hs.reload,
  },
}

-- `setIcon` exists so I'm disabling this lint
---@diagnostic disable-next-line: undefined-field
_G.menubar_item = hs.menubar.new():setIcon(icons["bsp"]):setMenu(menu_items)
