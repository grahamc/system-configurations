Plug("nvim-telescope/telescope.nvim", {
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    local select_one_or_multiple_files = function(prompt_buffer_number)
      local current_picker =
        require("telescope.actions.state").get_current_picker(prompt_buffer_number)
      local multi_selections = current_picker:get_multi_selection()
      if not vim.tbl_isempty(multi_selections) then
        actions.close(prompt_buffer_number)
        for _, multi_selection in pairs(multi_selections) do
          if multi_selection.path ~= nil then
            vim.cmd(string.format("edit %s", multi_selection.path))
          end
        end
      else
        actions.select_default(prompt_buffer_number)
      end
    end

    telescope.setup({
      defaults = {
        mappings = {
          i = {
            ["<Esc>"] = actions.close,
            ["<Tab>"] = actions.move_selection_next,
            ["<S-Tab>"] = actions.move_selection_previous,
            ["<F7>"] = actions.cycle_history_prev,
            ["<F8>"] = actions.cycle_history_next,
            ["<C-j>"] = actions.preview_scrolling_down,
            ["<C-k>"] = actions.preview_scrolling_up,
            ["<C-h>"] = actions.select_horizontal,
            ["<C-u>"] = false,
            ["<M-CR>"] = actions.toggle_selection,
            ["<M-a>"] = actions.toggle_all,
            ["<C-q>"] = function(...)
              actions.smart_send_to_qflist(...)
              actions.open_qflist(...)
            end,
          },
        },
        prompt_prefix = "   ",
        sorting_strategy = "ascending",
        selection_caret = " > ",
        entry_prefix = "   ",
        dynamic_preview_title = true,
        results_title = false,
        path_display = { "truncate" },
        history = {
          path = vim.fn.stdpath("data") .. "/telescope_history.sqlite3",
          limit = 100,
        },
        layout_strategy = "vertical",
        layout_config = {
          mirror = true,
          preview_cutoff = 20,
          prompt_position = "top",
        },
        borderchars = { "━", "", " ", " ", "━", "━", " ", " " },
      },
      pickers = {
        find_files = {
          hidden = true,
          follow = true,
          mappings = {
            i = {
              ["<CR>"] = select_one_or_multiple_files,
            },
          },
          disable_devicons = true,
          preview_title = "",
        },
        live_grep = {
          additional_args = {
            "--hidden",
            "--smart-case",
            "--follow",
          },
          mappings = {
            i = { ["<c-f>"] = actions.to_fuzzy_refine },
          },
          prompt_title = "Live Grep (Press <c-f> to fuzzy filter)",
          disable_devicons = true,
          preview_title = "",
        },
        help_tags = {
          mappings = {
            i = {
              ["<CR>"] = function(prompt_bufnr)
                local selection = require("telescope.actions.state").get_selected_entry().value
                actions.close(prompt_bufnr)
                vim.cmd("Help " .. selection)
              end,
            },
          },
          preview_title = "",
        },
        current_buffer_fuzzy_find = { preview_title = "" },
        jumplist = { preview_title = "" },
        highlights = { preview_title = "" },
        diagnostics = { preview_title = "" },
        lsp_dynamic_workspace_symbols = { preview_title = "" },
        autocommands = { preview_title = "" },
        filter_notifications = { preview_title = "" },
        command_history = {
          mappings = {
            -- If I execute the command directly from telescope I can't see the output so I'll
            -- send it to the commandline first.
            i = { ["<CR>"] = actions.edit_command_line },
          },
        },
      },
    })

    local telescope_builtins = require("telescope.builtin")
    local function call_with_visual_selection(picker)
      local result = function()
        local visual_selection = require("utilities").get_visual_selection()
        if #visual_selection > 0 then
          picker({ default_text = visual_selection })
        else
          picker()
        end
      end

      return result
    end
    vim.keymap.set(
      { "n", "v" },
      "<Leader>h",
      call_with_visual_selection(telescope_builtins.command_history),
      { desc = "Command history" }
    )
    -- TODO: I need to fix the previewer so it works with `page`. This way I get I get a live
    -- preview when I search manpages.
    vim.keymap.set("n", "<Leader>b", telescope_builtins.current_buffer_fuzzy_find, {
      desc = "Search buffer",
    })
    vim.keymap.set(
      { "n", "v" },
      "<Leader>k",
      call_with_visual_selection(telescope_builtins.help_tags),
      { desc = "Search help pages [manual,manpage]" }
    )
    vim.keymap.set(
      { "n", "v" },
      "<Leader>g",
      require("terminal.utilities").set_jump_before(
        call_with_visual_selection(telescope_builtins.live_grep)
      ),
      { desc = "Search files [grep]" }
    )
    vim.keymap.set("n", "<Leader>f", telescope_builtins.find_files, {
      desc = "Search files [find]",
    })
    vim.keymap.set("n", "<Leader>j", telescope_builtins.jumplist, {
      desc = "Jumplist",
    })
    vim.keymap.set("n", "<Leader><Leader>", telescope_builtins.resume, {
      desc = "Resume last picker",
    })
    vim.keymap.set(
      { "n", "v" },
      "<Leader>s",
      call_with_visual_selection(telescope_builtins.lsp_dynamic_workspace_symbols),
      { desc = "Symbols" }
    )
    vim.keymap.set("n", "<M-d>", telescope_builtins.diagnostics, {
      desc = "Diagnostics",
    })
    vim.api.nvim_create_user_command("Highlights", telescope_builtins.highlights, {})
    vim.api.nvim_create_user_command("Autocommands", telescope_builtins.autocommands, {})
    vim.api.nvim_create_user_command("Mappings", telescope_builtins.keymaps, {})

    telescope.load_extension("fzf")
    telescope.load_extension("smart_history")
  end,
})

Plug("nvim-telescope/telescope-fzf-native.nvim")

-- Dependencies: sqlite.lua
Plug("nvim-telescope/telescope-smart-history.nvim")
