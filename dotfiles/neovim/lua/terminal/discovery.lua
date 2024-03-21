Plug("folke/which-key.nvim", {
  config = function()
    -- controls how long it takes which-key to pop up
    vim.o.timeout = true
    vim.o.timeoutlen = 500

    require("which-key").setup({
      ignore_missing = false,
      popup_mappings = {
        scroll_down = "<c-j>",
        scroll_up = "<c-k>",
      },
      -- hide mapping boilerplate
      hidden = {
        "<silent>",
        "<cmd>",
        "<Cmd>",
        "<CR>",
        "call",
        "lua",
        "^:",
        "^ ",
        "<Plug>",
        "<plug>",
      },
      layout = {
        height = {
          max = math.floor(vim.o.lines * 0.20),
        },
        align = "center",
      },
      window = {
        border = { " ", " ", " ", " ", " ", " ", " ", " " },
        margin = { 1, 0.05, 2, 0.05 },
      },
      icons = {
        separator = " ",
      },
    })
  end,
})

local modes = { "n", "i", "x" }
Plug("mrjones2014/legendary.nvim", {
  on = { "CommandPalette" },
  config = function()
    local legendary = require("legendary")

    legendary.setup({
      select_prompt = "Command Palette",
      include_legendary_cmds = false,
      default_item_formatter = function(item)
        local Toolbox = require("legendary.toolbox")
        local function truncate(s)
          return string.sub(s, 1, math.max(25, math.floor(vim.o.columns * 0.15)))
        end
        if Toolbox.is_keymap(item) then
          return { truncate(item.keys), item.description }
        elseif Toolbox.is_command(item) then
          return { truncate(item.cmd), item.description }
        elseif Toolbox.is_autocmd(item) then
          return { truncate("<autocmd>"), item.description }
        elseif Toolbox.is_function(item) then
          return { truncate("<function>"), item.description }
        elseif Toolbox.is_itemgroup(item) then
          return { truncate(item.name), item.description or "Expand to select an item..." }
        else
          -- unreachable
          return { "", vim.inspect(item) }
        end
      end,
    })

    local function make_unique_filter(key_extractor)
      local seen = {}
      return function(...)
        local is_new = false
        local cursor = seen
        for _, key in ipairs(key_extractor(...)) do
          if not cursor[key] then
            is_new = true
            cursor[key] = {}
          end
          cursor = cursor[key]
        end

        return is_new
      end
    end

    --- get description for item
    --- @param item {} any
    --- @param candidate_keys {} candidate keys to use as description
    local function get_description(item, candidate_keys)
      local function is_non_empty_string(key)
        return item[key] ~= nil and item[key] ~= ""
      end
      local key = vim.iter(candidate_keys):find(is_non_empty_string)

      return key and item[key] or nil
    end

    local function make_legendary_buffer_filter(buffer)
      return function(_, context)
        return buffer == context.buf
      end
    end

    local function make_legendary_mode_filter(mode)
      return function(item)
        -- include everything that isn't a keymap since they aren't tied to a mode
        if not require("legendary.toolbox").is_keymap(item) then
          return true
        end

        local target_mode = ({
          ["n"] = "n",
          ["niI"] = "n",
          ["niR"] = "n",
          ["niV"] = "n",
          ["nt"] = "n",
          ["ntT"] = "n",
          ["v"] = "x",
          ["vs"] = "x",
          ["V"] = "x",
          ["Vs"] = "x",
          ["\22"] = "x",
          ["\22s"] = "x",
          ["i"] = "i",
          ["ic"] = "i",
          ["ix"] = "i",
        })[mode]

        return vim.iter(item:modes()):any(function(m)
          return m == target_mode
        end)
      end
    end

    local filter_unique_keymaps_across_invocations = make_unique_filter(function(keymap)
      return { keymap.buffer, keymap.lhs, keymap.mode }
    end)
    local function load_keymaps()
      local max_lhs_length = math.floor(vim.o.columns / 4)
      local function to_legendary_keymap(keymap)
        local filters = {}
        if keymap.buffer ~= 0 then
          table.insert(filters, make_legendary_buffer_filter(keymap.buffer))
        end

        local description = get_description(keymap, { "desc", "rhs" })

        local formatted_lhs =
          string.sub(keymap.lhs, 1, max_lhs_length):gsub(vim.g.mapleader, "<leader>")

        -- Remaps done by wezterm
        formatted_lhs = string.sub(formatted_lhs, 1, max_lhs_length):gsub("<F6>", "<C-m>")
        formatted_lhs = string.sub(formatted_lhs, 1, max_lhs_length):gsub("<F7>", "<C-[>")
        formatted_lhs = string.sub(formatted_lhs, 1, max_lhs_length):gsub("<F8>", "<C-]>")
        formatted_lhs = string.sub(formatted_lhs, 1, max_lhs_length):gsub("<F9>", "<C-i>")
        formatted_lhs = string.sub(formatted_lhs, 1, max_lhs_length):gsub("<leader>(%d)", "<C-%1>")

        return {
          formatted_lhs,
          description = description,
          filters = filters,
          mode = keymap.mode,
        }
      end

      local function filter_non_plug_mappings(keymap)
        return not vim.startswith(keymap.lhs, "<Plug>")
      end

      local buffer_keymaps = vim
        .iter(modes)
        :map(function(mode)
          return vim.api.nvim_buf_get_keymap(0, mode)
        end)
        :flatten()
        :totable()

      local global_keymaps = vim.iter(modes):map(vim.api.nvim_get_keymap):flatten():totable()

      -- I put buffer maps first so buffer maps will take priority over global maps when we
      -- filter.
      local all_keymaps = require("base.utilities").table_concat(buffer_keymaps, global_keymaps)

      vim
        .iter(all_keymaps)
        :filter(filter_non_plug_mappings)
        :filter(filter_unique_keymaps_across_invocations)
        -- remove keymaps with duplicate LHS's, favoring buffer-local maps
        :filter(
          make_unique_filter(function(keymap)
            return { keymap.lhs, keymap.mode }
          end)
        )
        :map(to_legendary_keymap)
        :each(legendary.keymap)
    end

    local filter_unique_commands_across_invocations = make_unique_filter(function(name, _, buf)
      return { buf, name }
    end)
    local function load_commands()
      local function to_legendary_command(command_name, info, buf)
        local filters = {}
        if buf then
          table.insert(filters, make_legendary_buffer_filter(buf))
        end

        -- Default to a non-empty string because legendary won't show it otherwise. Commands without
        -- descriptions are ok because they have names, unlike keymaps.
        local description = get_description(info, { "definition" }) or " "

        return {
          command_name,
          description = description,
          unfinished = info.nargs ~= "0",
          filters = filters,
        }
      end

      -- TODO: When I'm in the help page lsp.txt and I open the palette, nvim_buf_get_commands
      -- returns {6 = true}. So this will filter out values like that. I should probably report
      -- this.
      local function filter_valid_commands(key, value)
        return type(key) == "string" and type(value) == "table"
      end

      vim
        .iter(vim.api.nvim_get_commands({}))
        :filter(filter_valid_commands)
        -- Like `vim.api.nvim_get_keymap`, we'll use 0 as the buffer for global commands.
        :filter(
          function(name, info)
            return filter_unique_commands_across_invocations(name, info, 0)
          end
        )
        :map(to_legendary_command)
        :each(legendary.command)

      local buf = vim.api.nvim_win_get_buf(0)
      vim
        .iter(vim.api.nvim_buf_get_commands(buf, {}))
        :filter(filter_valid_commands)
        :filter(function(name, info)
          return filter_unique_commands_across_invocations(name, info, buf)
        end)
        :map(function(name, command)
          return to_legendary_command(name, command, buf)
        end)
        :each(legendary.command)
    end
    vim.api.nvim_create_user_command("CommandPalette", function()
      -- TODO: I should upstream this:
      -- https://github.com/mrjones2014/legendary.nvim/issues/258
      load_keymaps()
      load_commands()
      legendary.find({
        filters = { make_legendary_mode_filter(vim.api.nvim_get_mode().mode) },
      })
    end, {})
  end,
})

-- This is actually ctrl+/, see :help :map-special-keys
vim.keymap.set(modes, "<C-_>", vim.cmd.CommandPalette, {
  desc = "Command palette",
})
-- Outside TMUX the above won't work, I have to use <C-/>, so I just map both.
vim.keymap.set(modes, "<C-/>", vim.cmd.CommandPalette, {
  desc = "Command palette",
})
