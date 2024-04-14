local M = {}

local icon = [[ASCII:
1 · · · · · · · · · · · · · · 1 2
4 · · · · · · · · · · · · · · · ·
· · · · · · · · · · · · · · · · ·
· · · · · · · · · · · · · · · · ·
· · · · · · · · 6 · · · · · · · ·
· · · · · · · 6 · 6 · · · · · · ·
· · · · · · · · 6 · · · · · · · ·
· · · · · · · · · · · · · · · · ·
· · · · · · · · · · · · · · · · ·
· · · · · · · · · · · · · · · · ·
· · · · · · · · 5 · · · · · · · ·
· · · · · · · · · · · · · · · · ·
· · · · · · · · · · · · · · · · ·
· · · · · 5 · · · · · 5 · · · · ·
· · · · · · · · · · · · · · · · ·
· · · · · · · · 5 · · · · · · · ·
· · · · · · · · · · · · · · · · ·
· · · · · · · · · · · · · · · · 2
4 3 · · · · · · · · · · · · · · 3
]]

local function execute(executable, arguments, callback)
  -- I'm using hs.task because os.execute was really slow. For more on why os.execute was slow see here:
  -- https://github.com/Hammerspoon/hammerspoon/issues/2570
  return hs.task.new(executable, callback, arguments):start()
end

local function make_menubar_item(speakerctl_path)
  local function turn_on()
    execute(speakerctl_path, { "on" })
  end

  local function turn_off()
    execute(speakerctl_path, { "off" })
  end

  local function make_menu()
    -- TODO: Show a loading state initially and update the menu asynchronously. I'll be able to do
    -- that when this issue is resolved:
    -- https://github.com/Hammerspoon/hammerspoon/issues/1923
    local exit_code =
      execute(speakerctl_path, {}):waitUntilExit():terminationStatus()

    local menu_item = {
      title = "Disconnected from speakers",
      disabled = true,
    }
    if exit_code == 0 then
      menu_item = {
        title = "Turn speakers off",
        fn = turn_off,
      }
    elseif exit_code == 1 then
      menu_item = {
        title = "Turn speakers on",
        fn = turn_on,
      }
    end

    return { menu_item }
  end

  -- Assigning the menubar item to M so it doesn't get garbage collected.
  --
  -- `setIcon` exists so I'm disabling this lint
  ---@diagnostic disable-next-line: undefined-field
  M.menubar_item = hs.menubar.new():setIcon(icon):setMenu(make_menu)
end

-- Using an interactive-login shell to make sure Nix's vendor config gets sourced so I can find
-- `speakerctl`. I'm using `printf` so there's no trailing newline.
--
---@diagnostic disable-next-line: unused-local
execute(
  os.getenv("SHELL"),
  { "-i", "-l", "-c", [[printf %s "$(command -v speakerctl)"]] },
  function(_, stdout, _)
    make_menubar_item(stdout)
  end
)

return M
