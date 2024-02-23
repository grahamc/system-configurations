vim.o.complete = ".,w,b,u"
vim.o.pumheight = 6

-- for the  autocomplete omnifunc
Plug("blankname/vim-fish", {
  ["for"] = { "fish" },
})

Plug("hrsh7th/cmp-omni")

Plug("hrsh7th/cmp-cmdline")

Plug("dmitmel/cmp-cmdline-history")

-- This won't work until this is fixed: https://github.com/andersevenrud/cmp-tmux/issues/29
Plug("andersevenrud/cmp-tmux")

Plug("hrsh7th/cmp-buffer")

Plug("hrsh7th/cmp-nvim-lsp")

Plug("hrsh7th/cmp-path")

Plug("hrsh7th/cmp-nvim-lsp-signature-help")

Plug("bydlw98/cmp-env")

vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    vim.fn["plug#load"]("LuaSnip")
  end,
})
Plug("L3MON4D3/LuaSnip", {
  on = {},
  config = function()
    local luasnip = require("luasnip")
    local types = require("luasnip.util.types")
    luasnip.setup({
      keep_roots = true,
      link_roots = false,
      link_children = true,
      delete_check_events = "TextChanged",
      -- show virt_text while a snippet is active for any nodes that take user input
      ext_opts = {
        [types.insertNode] = {
          passive = {
            virt_text = { { "   ", "LuaSnipInlayHint" } },
            virt_text_pos = "inline",
          },
        },
        [types.exitNode] = {
          passive = {
            virt_text = { { "   ", "LuaSnipInlayHint" } },
            virt_text_pos = "inline",
          },
          -- The inlay was displaying sometimes after selecting an nvim-cmp autocomplete entry
          -- so I'm disabling visible exitNodes to hide it.
          visited = {
            virt_text = { { "", "LuaSnipInlayHint" } },
            virt_text_pos = "inline",
          },
        },
        [types.choiceNode] = {
          passive = {
            virt_text = { { "   ", "LuaSnipInlayHint" } },
            virt_text_pos = "inline",
          },
        },
      },
    })

    require("luasnip.loaders.from_vscode").lazy_load()

    vim.keymap.set({ "i", "s" }, "<C-c>", function()
      if luasnip.choice_active() then
        require("luasnip.extras.select_choice")()
      end
    end, { desc = "Select choice" })

    -- Disable the current snippet when I leave select/insert mode.
    --
    -- TODO: I'd like the option to reactivate the snippet, but luasnip.activate_node() only
    -- works for me if the snippet gets disabled through region_check_events and not this manual
    -- unlink_current()
    --
    -- Taken from:
    -- https://github.com/MariaSolOs/dotfiles/blob/da291d841447ed7daddcf3f9d3c66ed04e025b50/.config/nvim/lua/plugins/nvim-cmp.lua#L45
    vim.api.nvim_create_autocmd("ModeChanged", {
      group = vim.api.nvim_create_augroup("bigolu/unlink_snippet", {}),
      desc = "Cancel the snippet session when leaving insert mode",
      pattern = { "s:n", "i:*" },
      callback = function(args)
        if
          luasnip.session
          and luasnip.session.current_nodes[args.buf]
          and not luasnip.session.jump_active
          and not luasnip.choice_active()
        then
          luasnip.unlink_current()
        end
      end,
    })
  end,
})

Plug("saadparwaiz1/cmp_luasnip")

Plug("rafamadriz/friendly-snippets")

-- TODO: With this I'll be able to enable this source only in comments:
-- https://github.com/hrsh7th/nvim-cmp/pull/1314
-- I also want to enable it selectively for filetypes like markdown.
Plug("uga-rosa/cmp-dictionary", {
  config = function()
    require("cmp_dictionary").setup({
      max_number_items = 1000,
      first_case_insensitive = true,
      external = {
        enable = true,
        command = { "look", "${prefix}", "${path}" },
      },
      document = {
        enable = true,
        command = { "wn", "${label}", "-over" },
      },
    })
  end,
})

Plug("hrsh7th/nvim-cmp", {
  config = function()
    local cmp = require("cmp")
    local autocmd_group = vim.api.nvim_create_augroup("MyNvimCmp", {})

    cmp.event:on(
      "confirm_done",
      require("nvim-autopairs.completion.cmp").on_confirm_done({
        filetypes = {
          nix = false,
          sh = false,
        },
      })
    )

    -- sources
    local buffer = {
      name = "buffer",
      option = {
        keyword_length = 2,
        get_bufnrs = function()
          local filtered_buffer_numbers = {}
          local all_buffer_numbers = vim.api.nvim_list_bufs()
          for _, buffer_number in ipairs(all_buffer_numbers) do
            local is_buffer_loaded = vim.api.nvim_buf_is_loaded(buffer_number)
            -- 5 megabyte max
            local is_buffer_under_max_size = vim.api.nvim_buf_get_offset(
              buffer_number,
              vim.api.nvim_buf_line_count(buffer_number)
            ) < 1024 * 1024 * 5

            if is_buffer_loaded and is_buffer_under_max_size then
              table.insert(filtered_buffer_numbers, buffer_number)
            end
          end

          return filtered_buffer_numbers
        end,
      },
    }
    local nvim_lsp = { name = "nvim_lsp" }
    local omni = { name = "omni" }
    local path = {
      name = "path",
      option = {
        label_trailing_slash = false,
      },
    }
    local tmux = {
      name = "tmux",
      option = { all_panes = true, label = "Tmux", capture_history = true },
    }
    local cmdline = { name = "cmdline", priority = 9 }
    local cmdline_history = {
      name = "cmdline_history",
      max_item_count = 2,
    }
    local lsp_signature = { name = "nvim_lsp_signature_help", priority = 8 }
    local luasnip_source = {
      name = "luasnip",
      option = { use_show_condition = false },
    }
    local env = { name = "env" }
    local dictionary = { name = "dictionary", keyword_length = 2 }

    -- helpers
    local cmdline_search_config = {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        buffer,
        cmdline_history,
      },
    }

    cmp.setup({
      enabled = function()
        local is_not_prompt = vim.bo.buftype ~= "prompt"
        return is_not_prompt
      end,
      formatting = {
        fields = { "abbr", "kind" },
        format = function(_, vim_item)
          vim_item.menu = nil
          vim_item.dup = 0
          return vim_item
        end,
      },
      snippet = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body)
        end,
      },
      window = {
        documentation = {
          winhighlight = "NormalFloat:CmpDocumentationNormal,FloatBorder:CmpDocumentationBorder",
          border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
          -- TODO: ask if this option could accept a function instead so it can respond to window
          -- resizes
          max_height = math.floor(vim.o.lines * 0.35),
          max_width = math.floor(vim.o.columns * 0.65),
        },
        completion = {
          winhighlight = "NormalFloat:CmpNormal,Pmenu:CmpNormal,CursorLine:CmpCursorLine,PmenuSbar:CmpScrollbar",
          border = "none",
          side_padding = 1,
          col_offset = 1,
        },
      },
      mapping = cmp.mapping.preset.insert({
        ["<CR>"] = function(fallback)
          -- TODO: Don't block <CR> if signature help is active
          -- https://github.com/hrsh7th/cmp-nvim-lsp-signature-help/issues/13
          if
            not cmp.visible()
            or not cmp.get_selected_entry()
            or cmp.get_selected_entry().source.name == "nvim_lsp_signature_help"
          then
            fallback()
          else
            cmp.confirm({
              -- Replace word if completing in the middle of a word
              behavior = cmp.ConfirmBehavior.Replace,
              -- Don't select first item on CR if nothing was selected
              select = false,
            })
          end
        end,
        ["<Tab>"] = cmp.mapping(function(_)
          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
          else
            cmp.complete()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<C-j>"] = cmp.mapping(function(fallback)
          if cmp.visible_docs() then
            cmp.scroll_docs(4)
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<C-k>"] = cmp.mapping(function(fallback)
          if cmp.visible_docs() then
            cmp.scroll_docs(-4)
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<C-h>"] = cmp.mapping(function(_)
          if require("luasnip").jumpable(-1) then
            require("luasnip").jump(-1)
          end
        end, { "i", "s" }),
        ["<C-l>"] = cmp.mapping(function(_)
          if require("luasnip").expand_or_locally_jumpable() then
            require("luasnip").expand_or_jump()
          end
        end, { "i", "s" }),
      }),
      -- The order of the sources controls which entry will be chosen if multiple sources return
      -- entries with the same names. Sources at the bottom of this list will be chosen over the
      -- sources above them.
      sources = cmp.config.sources({
        lsp_signature,
        dictionary,
        buffer,
        tmux,
        env,
        luasnip_source,
        omni,
        nvim_lsp,
        path,
      }),
      sorting = {
        -- Builtin comparators are defined here:
        -- https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/config/compare.lua
        comparators = {
          -- Sort by the item kind enum, lower ordinal values are ranked higher. Enum is defined here:
          -- https://github.com/hrsh7th/nvim-cmp/blob/5dce1b778b85c717f6614e3f4da45e9f19f54435/lua/cmp/types/lsp.lua#L177
          function(entry1, entry2)
            local text_kind = require("cmp.types").lsp.CompletionItemKind.Text
            -- Adjust the rankings so the new rankings will be:
            -- 1. Everything else
            -- 2. Text
            -- 3. Text from dictionary
            local function get_adjusted_ranking(entry)
              if entry.source.name == "dictionary" then
                return 3
              elseif entry:get_kind() == text_kind then
                return 2
              else
                return 1
              end
            end
            local kind1 = get_adjusted_ranking(entry1)
            local kind2 = get_adjusted_ranking(entry2)

            if kind1 ~= kind2 then
              local diff = kind1 - kind2
              if diff < 0 then
                return true
              elseif diff > 0 then
                return false
              end
            end

            return nil
          end,

          function(...)
            return require("cmp_buffer"):compare_locality(...)
          end,
        },
      },
    })

    cmp.setup.cmdline("/", cmdline_search_config)
    cmp.setup.cmdline("?", cmdline_search_config)
    cmp.setup.cmdline(":", {
      formatting = {
        fields = { "abbr", "menu" },
        format = function(entry, vim_item)
          vim_item.menu = ({
            cmdline = "Cmdline",
            cmdline_history = "History",
            buffer = "Buffer",
            path = "Path",
          })[entry.source.name]
          vim_item.dup = 0
          return vim_item
        end,
      },
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        cmdline,
        cmdline_history,
        path,
        buffer,
      }),
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "DressingInput",
      group = autocmd_group,
      callback = function()
        -- setup because dessing.nvim also calls setup and I need mine to run after it so I can
        -- override it. Ideally dressing would let you configure the setup:
        --
        -- https://github.com/stevearc/dressing.nvim/blob/6f212262061a2120e42da0d1e87326e8a41c0478/lua/dressing/input.lua#L469
        vim.defer_fn(function()
          cmp.setup.buffer({
            enabled = true,
            sources = cmp.config.sources({
              path,
              buffer,
              -- dressing will set the omnifunc if `completion` was provided to vim.ui.input()
              omni,
            }),
          })
        end, 0)
      end,
    })

    -- TODO: Set a variable to indicate whether the documentation window is open. The variable is
    -- checked in my statusline to show mappings for scrolling the docs window. I'd like to use
    -- cmp.visible_docs(), but I get E565 when I try.
    --
    -- HACK: open() is a private API so this might cause issues later. I wanted to use WinNew, but
    -- it wasn't firing for the docs window. I think it's because nvim-cmp is passing noautocmd to
    -- nvim_open_win. Though even if WinNew fired I think I would run into another issue because
    -- WinNew currently doesn't offer a way to get the id of the new window:
    -- https://github.com/neovim/neovim/issues/25844
    local function make_docs_wrapper()
      local success, utils_window = pcall(require, "cmp.utils.window")
      if not success then
        vim.notify(
          "Unable to create nvim-cmp documentation wrapper, the original function was not found",
          vim.log.levels.ERROR
        )
        return
      end

      local original_open = utils_window.open
      ---@diagnostic disable-next-line: duplicate-set-field
      utils_window.open = function(...)
        local style = select(2, ...)
        local has_expected_argument_shape = type(style) == "table" and style.border ~= nil
        if not has_expected_argument_shape then
          vim.notify(
            "nvim-cmp documentation wrapper is not receiving the expected argument shape",
            vim.log.levels.ERROR
          )

          -- set open back to the original
          utils_window.open = original_open

          return
        end
        local border = style.border

        -- I only set border to "none" for the autocmplete window, not the docs window so if
        -- the border isn't "none" I'm assuming the docs window is being opened.
        if border ~= "none" then
          IsCmpDocsOpen = true
        end

        original_open(...)
      end

      vim.api.nvim_create_autocmd("WinClosed", {
        group = autocmd_group,
        callback = function()
          if
            vim.bo[vim.api.nvim_win_get_buf(tonumber(vim.fn.expand("<amatch>")) or 0)].filetype
            == "cmp_docs"
          then
            IsCmpDocsOpen = false
          end
        end,
      })
      -- Only checking WinClosed wasn't enough so I use this event too for good measure
      cmp.event:on("menu_closed", function()
        IsCmpDocsOpen = false
      end)
    end
    make_docs_wrapper()
  end,
})
