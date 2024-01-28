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
          max = math.floor(vim.o.lines * 0.25),
        },
      },
      window = {
        border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
        margin = { 1, 4, 2, 2 },
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
      return key and item[key] or " "
    end

    local function make_buffer_filter(buffer)
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
          table.insert(filters, make_buffer_filter(keymap.buffer))
        end

        -- coerce to a non-empty string because legendary won't show it otherwise
        local description = get_description(keymap, { "desc", "rhs" })

        local truncated_lhs = string.sub(keymap.lhs, 1, max_lhs_length)

        return {
          truncated_lhs,
          description = description,
          filters = filters,
        }
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
          table.insert(filters, make_buffer_filter(buf))
        end

        -- coerce to a non-empty string because legendary won't show it otherwise
        local description = get_description(info, { "definition" })

        return {
          command_name,
          description = description,
          unfinished = info.nargs ~= "0",
          filters = filters,
        }
      end

      vim
        .iter(vim.api.nvim_get_commands({}))
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
    vim.keymap.set("n", "<C-_>", open_command_palette)
    -- Outside TMUX the above won't work, I have to use <C-/>, so I just map both.
    vim.keymap.set("n", "<C-/>", open_command_palette)
  end,
})
