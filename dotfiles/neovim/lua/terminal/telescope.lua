Plug("nvim-telescope/telescope.nvim", {
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    local select_one_or_multiple_files = function(prompt_buffer_number)
      local current_picker =
        require("telescope.actions.state").get_current_picker(
          prompt_buffer_number
        )
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
            ["<C-o>"] = require("telescope.actions.layout").cycle_layout_next,
          },
        },
        cycle_layout_list = {
          {
            layout_strategy = "horizontal",
            layout_config = {
              mirror = false,
              preview_cutoff = 20,
              prompt_position = "top",
              preview_width = 0.60,
            },
          },
          {
            layout_strategy = "vertical",
            layout_config = {
              mirror = true,
              preview_cutoff = 20,
              prompt_position = "top",
            },
          },
        },
        layout_strategy = "vertical",
        layout_config = {
          mirror = true,
          preview_cutoff = 20,
          prompt_position = "top",
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
        },
        live_grep = {
          additional_args = {
            "--hidden",
            "--smart-case",
            "--follow",
          },
          mappings = {
            i = { ["<c-g>"] = actions.to_fuzzy_refine },
          },
          prompt_title = "Live Grep (Press <c-g> to fuzzy filter)",
          disable_devicons = true,
        },
        help_tags = {
          mappings = {
            i = {
              ["<CR>"] = function(prompt_bufnr)
                local selection =
                  require("telescope.actions.state").get_selected_entry().value
                actions.close(prompt_bufnr)
                vim.cmd("Help " .. selection)
              end,
            },
          },
        },
        command_history = {
          mappings = {
            i = {
              ["<CR>"] = function(prompt_bufnr)
                local selection =
                  require("telescope.actions.state").get_selected_entry().value
                actions.close(prompt_bufnr)
                -- If you just use `vim.cmd` the output won't show so I'm using feedkeys instead
                local enter_key =
                  vim.api.nvim_replace_termcodes("<CR>", true, false, true)
                vim.api.nvim_feedkeys(":" .. selection .. enter_key, "n", false)
              end,
            },
          },
        },
      },
      extensions = {
        menufacture = {
          mappings = {
            main_menu = { [{ "i", "n" }] = "<C-f>" },
          },
        },
        ast_grep = {
          grep_open_files = false,
          disable_devicons = true,
        },
      },
    })
    telescope.load_extension("fzf")
    telescope.load_extension("smart_history")
    telescope.load_extension("menufacture")
    telescope.load_extension("ast_grep")

    local telescope_menufacture = require("telescope").extensions.menufacture
    local function with_menufacture_mappings_displayed(picker)
      return function(opts)
        IsMenufactureOpen = true
        picker(opts)
      end
    end

    local telescope_builtins = require("telescope.builtin")
    local function with_visual_selection(picker)
      local result = function(opts)
        -- some pickers, like ast_grep require you pass a table, even if it's empty
        opts = opts or {}

        local visual_selection =
          require("base.utilities").get_visual_selection()
        if #visual_selection > 0 then
          opts = vim.tbl_deep_extend(
            "error",
            opts,
            { default_text = visual_selection }
          )
        end

        picker(opts)
      end

      return result
    end
    vim.keymap.set(
      { "n", "v" },
      "<Leader>h",
      with_visual_selection(telescope_builtins.command_history),
      { desc = "Command history" }
    )
    -- TODO: I need to fix the previewer so it works with `page`. This way I get I get a live
    -- preview when I search manpages.
    vim.keymap.set(
      { "n", "v" },
      "<Leader>b",
      with_visual_selection(telescope_builtins.current_buffer_fuzzy_find),
      {
        desc = "Search buffer",
      }
    )
    vim.keymap.set(
      { "n", "v" },
      "<Leader>k",
      with_visual_selection(telescope_builtins.help_tags),
      { desc = "Search help pages [manual,manpage]" }
    )
    vim.keymap.set(
      { "n", "v" },
      "<Leader>g",
      require("terminal.utilities").set_jump_before(
        with_visual_selection(
          with_menufacture_mappings_displayed(telescope_menufacture.live_grep)
        )
      ),
      { desc = "Search in files [grep]" }
    )
    vim.keymap.set(
      { "n", "v" },
      "<Leader>a",
      require("terminal.utilities").set_jump_before(
        with_visual_selection(telescope.extensions.ast_grep.ast_grep)
      ),
      { desc = "Search file ASTs [grep]" }
    )
    vim.keymap.set(
      "n",
      "<Leader>f",
      with_menufacture_mappings_displayed(telescope_menufacture.find_files),
      {
        desc = "Search file names [find]",
      }
    )
    vim.keymap.set("n", "<Leader>j", telescope_builtins.jumplist, {
      desc = "Jumplist",
    })
    vim.keymap.set("n", "<Leader><Leader>", telescope_builtins.resume, {
      desc = "Resume last picker",
    })
    vim.keymap.set(
      { "n", "v" },
      "<Leader>s",
      with_visual_selection(telescope_builtins.lsp_dynamic_workspace_symbols),
      { desc = "Symbols" }
    )
    vim.keymap.set("n", "<Leader>o", telescope_builtins.vim_options, {
      desc = "Vim options",
    })
    vim.api.nvim_create_user_command(
      "Highlights",
      telescope_builtins.highlights,
      {}
    )
    vim.api.nvim_create_user_command(
      "Autocommands",
      telescope_builtins.autocommands,
      {}
    )
    vim.api.nvim_create_user_command("Mappings", telescope_builtins.keymaps, {})
  end,
})

Plug("nvim-telescope/telescope-fzf-native.nvim")

-- Dependencies: sqlite.lua
Plug("nvim-telescope/telescope-smart-history.nvim")

Plug("molecule-man/telescope-menufacture")

Plug("Marskey/telescope-sg")
