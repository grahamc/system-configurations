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
  -- I'm using hs.task because os.execute was really slow. For more on why
  -- os.execute was slow see here:
  -- https://github.com/Hammerspoon/hammerspoon/issues/2570
  return hs.task.new(executable, callback, arguments):start()
end

local function get_command_output(executable, arguments, callback)
  execute(executable, arguments, function(_, stdout, _)
    -- TODO: I think this also trims leading newlines:
    -- https://stackoverflow.com/a/51181334
    local trimmed = string.gsub(stdout, "^%s*(.-)%s*$", "%1")
    callback(trimmed)
  end)
end

local function make_menubar_item(speakerctl_path)
  local function turn_on()
    execute(speakerctl_path, { "on" })
  end

  local function turn_off()
    execute(speakerctl_path, { "off" })
  end

  local function make_menu()
    -- TODO: Show a loading state initially and update the menu
    -- asynchronously. I'll be able to do that when this issue is resolved:
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

  local function is_laptop_docked()
    local exit_code = execute("/bin/sh", {
        "-c",
        [[system_profiler SPUSBDataType | grep -q 'OWC Thunderbolt']],
      })
      :waitUntilExit()
      :terminationStatus()

    return exit_code == 0
  end

  -- Assigning the menubar item to M so it doesn't get garbage collected.
  --
  -- `setIcon` exists so I'm disabling this lint
  ---@diagnostic disable-next-line: undefined-field
  M.menubar_item = hs.menubar.new():setIcon(icon):setMenu(make_menu)

  local watcher = hs.caffeinate.watcher
  -- Assigning the watcher to M so it doesn't get garbage collected.
  M.watcher = watcher
    .new(function(event)
      if not is_laptop_docked() then
        return
      end

      if
        hs.fnutils.contains(
          {
            watcher.screensDidLock,
            watcher.screensaverDidStart,
            watcher.screensDidSleep,
            watcher.systemWillPowerOff,
            watcher.systemWillSleep,
          },
          event
        )
      then
        turn_off()
      elseif
        hs.fnutils.contains(
          {
            watcher.screensDidUnlock,
            watcher.screensaverDidStop,
            watcher.screensDidWake,
            watcher.systemDidWake,
          },
          event
        )
      then
        turn_on()
      end
    end)
    :start()
end

-- Using a login shell to make sure Nix's login shell configuration runs so I
-- can find `speakerctl`.
--
---@diagnostic disable-next-line: unused-local
get_command_output(
  os.getenv("SHELL"),
  { "-l", "-c", [[command -v speakerctl]] },
  make_menubar_item
)

return M
