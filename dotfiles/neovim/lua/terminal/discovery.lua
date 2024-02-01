Plug("folke/which-key.nvim", {
  config = function()
    require("which-key").setup({
      popup_mappings = {
        scroll_down = "<c-j>",
        scroll_up = "<c-k>",
      },
      -- hide mapping boilerplate
      -- This is the correct type.
      ---@diagnostic disable-next-line: assign-type-mismatch
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
        border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
        margin = { 1, 0.05, 2, 0.05 },
      },
      icons = {
        separator = " ",
      },
    })
  end,
})

Plug("mrjones2014/legendary.nvim", {
  config = function()
    local legendary = require("legendary")

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

      -- coerce to a non-empty string because legendary won't show it otherwise
      return key and item[key] or " "
    end

    local function make_legendary_buffer_filter(buffer)
      return function(_, context)
        return buffer == context.buf
      end
    end

    local filter_unique_keymaps_across_invocations = make_unique_filter(function(keymap)
      return { keymap.buffer, keymap.lhs }
    end)
    local function load_keymaps()
      local modes = { "n", "i", "c", "x" }

      local max_lhs_length = math.floor(vim.o.columns / 4)
      local function to_legendary_keymap(keymap)
        local filters = {}
        if keymap.buffer ~= 0 then
          table.insert(filters, make_legendary_buffer_filter(keymap.buffer))
        end

        local description = get_description(keymap, { "desc", "rhs" })

        local formatted_lhs =
          string.sub(keymap.lhs, 1, max_lhs_length):gsub(vim.g.mapleader, "<leader>")

        return {
          formatted_lhs,
          description = description,
          filters = filters,
        }
      end

      local function filter_non_plug_mappings(keymap)
        return not vim.startswith(keymap.lhs, "<Plug>")
      end

      local buf = vim.api.nvim_win_get_buf(0)
      local buffer_keymaps = vim
        .iter(modes)
        :map(function(mode)
          vim.api.nvim_buf_get_keymap(buf, mode)
        end)
        :flatten()
        :totable()

      local global_keymaps = vim.iter(modes):map(vim.api.nvim_get_keymap):flatten():totable()

      local function table_concat(t1, t2)
        for i = 1, #t2 do
          t1[#t1 + 1] = t2[i]
        end
        return t1
      end
      -- NOTE: I put buffer maps first so buffer maps will take priority over global maps when we
      -- filter.
      local all_keymaps = table_concat(buffer_keymaps, global_keymaps)

      vim
        .iter(all_keymaps)
        :filter(filter_non_plug_mappings)
        :filter(filter_unique_keymaps_across_invocations)
        -- remove keymaps with duplicate LHS's, favoring buffer-local maps
        :filter(
          make_unique_filter(function(keymap)
            return { keymap.lhs }
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

        local description = get_description(info, { "definition" })

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

    legendary.setup({
      select_prompt = "Command/Keymap Palette",
      include_legendary_cmds = false,
    })

    local function open_command_palette()
      -- TODO: I should upstream this:
      -- https://github.com/mrjones2014/legendary.nvim/issues/258
      load_keymaps()
      load_commands()
      legendary.find({
        filters = { require("legendary.filters").current_mode() },
      })
    end
    -- This is actually ctrl+/, see :help :map-special-keys
    vim.keymap.set("n", "<C-_>", open_command_palette, {
      desc = "Command palette",
    })
    -- Outside TMUX the above won't work, I have to use <C-/>, so I just map both.
    vim.keymap.set("n", "<C-/>", open_command_palette, {
      desc = "Command palette",
    })
  end,
})
