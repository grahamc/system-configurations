-- This lets you use the hammerspoon commandline tool
require("hs.ipc")
hs.ipc.cliInstall()

stackline = require "stackline"
stackline:init()

icons = {
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

function execute(executable, arguments, callback)
	-- I'm using hs.task because os.execute was really slow. For more on why os.execute was slow see here:
	-- https://github.com/Hammerspoon/hammerspoon/issues/2570
	hs.task.new(
		executable,
		callback,
		arguments
	):start()
end


function toggle_stack_icon_style()
	execute(
		'/usr/local/bin/hs',
		{'-c',  [[stackline.config:toggle("appearance.showIcons")]],}
	)
end

function toggle_tiling_mode()
	execute(
		'/usr/local/bin/yabai',
		{'-m', 'config', 'layout',},
		function(exit_code, stdout, stderr)
			if stdout == 'bsp\n' then
				layout = 'float'
			else
				layout = 'bsp'
			end
			execute(
				'/usr/local/bin/yabai',
				{'-m', 'config', 'layout', layout,},
				function()
					menubar_item:setIcon(icons[layout])
				end
			)
		end
	)
end

local function getShortcutsHtml()
    commandEnum = {
        cmd = '⌘',
        shift = '⇧',
        alt = '⌥',
        ctrl = '⌃',
	fn = 'Fn',
    }

    direction_key_label = '&lt;direction&gt;'

    shortcuts = {
	    {
		title = 'Direction Keys',
		items = {
			{
				mods = {},
				key = 'h&nbsp; j&nbsp; k&nbsp; l',
				description = 'Move left, down, up, and right respectively (like Vim)',
			},
		},
	    },
	    {
		title = 'Navigate windows',
		items = {
			{
				mods = {'cmd',},
				key = direction_key_label,
				description = 'Switch focus between windows',
			},
			{
				mods = {'cmd', 'alt',},
				key = 'k',
				description = 'Switch focus to previous window in a stack',
			},
			{
				mods = {'cmd', 'alt',},
				key = 'j',
				description = 'Switch focus to next window in a stack',
			},
		},
	    },
	    {
		title = 'Move, resize, and swap windows in adjustment mode',
		items = {
			{
				mods = {'cmd',},
				key = 'enter',
				description = 'Enter adjustment mode',
			},
			{
				mods = {},
				key = direction_key_label,
				description = 'Move window',
			},
			{
				mods = {'fn'},
				key = 'left mouse button drag',
				description = 'Move window',
			},
			{
				mods = {'shift'},
				key =   direction_key_label,
				description = 'Grow/shrink window',
			},
			{
				mods = {'fn'},
				key = 'right mouse button drag',
				description = 'Grow/shrink window',
			},
			{
				mods = {'ctrl'},
				key = direction_key_label,
				description = 'Swap Windows',
			},
			{
				mods = {'alt'},
				key = direction_key_label,
				description = 'Stack Windows',
			},
			{
				mods = {},
				key = 'Esc',
				description = 'Exit adjustment mode',
			},
		},
	    },
	    {
		title = 'Window Shortcuts',
		items = {
			{
				mods = {'cmd',},
				key = 'o',
				description = 'Rotate windows clockwise',
			},
			{
				mods = {'cmd', 'shift',},
				key = 'o',
				description = 'Rotate windows counter-clockwise',
			},
			{
				mods = {'cmd',},
				key = 'g',
				description = 'Toggle floating mode',
			},
			{
				mods = {'cmd',},
				key = 'm',
				description = 'Toggle fullscreen zoom',
			},
			{
				mods = {'cmd', 'shift',},
				key = 'm',
				description = 'Toggle parent zoom',
			},
			{
				mods = {'cmd', 'shift',},
				key = '0',
				description = 'Reset all window sizes so that they share space evenly',
			},
			{
				mods = {'cmd',},
				key = 's',
				description = 'Toggle stacking mode (Next window opened will open on top of the current one)',
			},
		},
	    },
    }

    local menu = ""
    for index,shortcut_group in ipairs(shortcuts) do
                menu = menu .. "<ul class='col col" .. index .. "'>"
                menu = menu .. "<li class='title'><strong>" .. shortcut_group.title .. "</strong></li>"

    	    for _,shortcut in ipairs(shortcut_group.items) do
    		local mods = ''
    		for _,value in ipairs(shortcut.mods) do
    		    mods = mods .. commandEnum[value]
    		end
    		local shortcut_key = shortcut.key
    		menu = menu .. "<li><div class='cmdModifiers'>" .. mods .. " " .. shortcut_key .. "</div><div class='cmdtext'>" .. " " .. shortcut.description .. "</div></li>"
    	    end

            menu = menu .. "</ul>"
    end

    return menu
end

local function generateHtml()
    local app_title = 'Tiling Mode Shortcuts'
    local shortcuts_html = getShortcutsHtml()

    function rtrim(s)
      local n = #s
      while n > 0 and s:find("^%s", n) do n = n - 1 end
      return s:sub(1, n)
    end
    stdout = hs.execute('defaults read -g AppleInterfaceStyle')
    -- Hammerspoon docs for hs.execute say that there may be an extra newline at the end
    stdout = rtrim(stdout)
    is_dark_mode = stdout == 'Dark'
    bg_color = is_dark_mode and '#111' or '#eee'
    fg_color = is_dark_mode and '#eee' or '#111'

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
              font-size:12px;
            }
            li.title{ text-align:center;}
            ul, li{list-style: inside none; padding: 0 0 5px;}
            footer{
              position: fixed;
              left: 0;
              right: 0;
              height: 48px;
              /*background-color:#eee;*/
            }
            header{
              position: fixed;
              top: 0;
              left: 0;
              right: 0;
              height:48px;
              /*background-color:#eee;*/
              z-index:99;
            }
            footer{ bottom: 0; }
            header hr,
            footer hr {
              border: 0;
              height: 0;
              border-top: 1px solid rgba(0, 0, 0, 0.1);
              border-bottom: 1px solid rgba(255, 255, 255, 0.3);
            }
            .title{
                padding: 15px;
            }
            li.title{padding: 0  10px 15px}
            .content{
              padding: 0 0 15px;
              font-size:12px;
              overflow:hidden;
            }
            .content.maincontent{
            position: relative;
              height: 577px;
              margin-top: 46px;
            }
            .content > .col{
              width: 23%;
              padding:20px 0 20px 10px;
            }
            li:after{
              visibility: hidden;
              display: block;
              font-size: 0;
              content: " ";
              clear: both;
              height: 0;
            }
            .cmdModifiers{
              width: 110px;
              padding-right: 15px;
              text-align: right;
              float: left;
              font-weight: bold;
            }
            .cmdtext{
              float: left;
              overflow: hidden;
              width: 150px;
            }
        </style>
        </head>
          <body>
            <header>
              <div class="title"><strong>]] .. app_title .. [[</strong></div>
              <hr />
            </header>
            <div class="content maincontent">]] .. shortcuts_html .. [[</div>
            <br>
          <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.isotope/2.2.2/isotope.pkgd.min.js"></script>
            <script type="text/javascript">
              var elem = document.querySelector('.content');
              var iso = new Isotope( elem, {
                // options
                itemSelector: '.col',
                layoutMode: 'masonry'
              });
            </script>
          </body>
        </html>
        ]]

    return html
end


function open_help_page()
	screen_rect = hs.screen.mainScreen():fullFrame()
	help_page = hs.webview.new({x = screen_rect.x+screen_rect.w*0.15/2, y = screen_rect.x+screen_rect.w*0.25/2, w = screen_rect.w * .85, h = screen_rect.h * .40}):windowStyle({'closable', 'titled', 'fullSizeContentView', 'texturedBackground', 'nonactivating',}):closeOnEscape(true):bringToFront(true):deleteOnClose(true):html(generateHtml())
	help_page:show()
end

menu_items = {
	{
		title = 'Show Shortcuts',
		fn = open_help_page,
	},
	{
		title = 'Toggle Stack Icon Style',
		fn = toggle_stack_icon_style,
	},
	{
		title = 'Toggle Tiling Mode',
		fn = toggle_tiling_mode,
	},
	{
		title = 'Refresh',
		fn = hs.reload,
	},
}

menubar_item = hs.menubar.new():setIcon(icons['bsp']):setMenu(menu_items)
