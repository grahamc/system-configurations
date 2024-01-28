vim.o.complete = ".,w,b,u"
vim.o.pumheight = 6

Plug("windwp/nvim-autopairs", {
  config = function()
    require("nvim-autopairs").setup({
      -- Don't add bracket pairs after quote.
      enable_afterquote = false,
    })
  end,
})

Plug("windwp/nvim-ts-autotag")

-- Automatically add closing keywords (e.g. function/endfunction in vimscript)
Plug("RRethy/nvim-treesitter-endwise", {
  config = function()
    -- this way endwise triggers on `o`
    vim.keymap.set("n", "o", "A<CR>", { remap = true })
  end,
})

-- for autocomplete
Plug("blankname/vim-fish")

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

Plug("L3MON4D3/LuaSnip", {
  config = function()
    require("luasnip").config.set_config({
      history = true,
      delete_check_events = "TextChanged",
    })
    require("luasnip.loaders.from_vscode").lazy_load()
  end,
})

Plug("saadparwaiz1/cmp_luasnip")

Plug("rafamadriz/friendly-snippets")

Plug("hrsh7th/nvim-cmp", {
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    local cmp_buffer = require("cmp_buffer")

    cmp.event:on(
      "confirm_done",
      require("nvim-autopairs.completion.cmp").on_confirm_done({
        filetypes = {
          nix = false,
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

    -- helpers
    local is_cursor_preceded_by_nonblank_character = function()
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      return col ~= 0
        and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s")
          == nil
    end
    local cmdline_search_config = {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        buffer,
        cmdline_history,
      },
    }

    cmp.setup({
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
          luasnip.lsp_expand(args.body)
        end,
      },
      window = {
        documentation = {
          winhighlight = "NormalFloat:CmpDocumentationNormal,FloatBorder:CmpDocumentationBorder",
          border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
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
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
          elseif is_cursor_preceded_by_nonblank_character() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<C-k>"] = cmp.mapping.scroll_docs(-4),
        ["<C-j>"] = cmp.mapping.scroll_docs(4),
        ["<C-h>"] = cmp.mapping(function(_)
          if luasnip.jumpable(-1) then
            luasnip.jump(-1)
          end
        end, { "i", "s" }),
        ["<C-l>"] = cmp.mapping(function(_)
          if luasnip.jumpable(1) then
            luasnip.jump(1)
          end
        end, { "i", "s" }),
      }),
      -- The order of the sources controls which entry will be chosen if multiple sources return
      -- entries with the same names. Sources at the bottom of this list will be chosen over the
      -- sources above them.
      sources = cmp.config.sources({
        lsp_signature,
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
            local function get_adjusted_ranking(kind)
              if kind == text_kind then
                return 2
              else
                return 1
              end
            end
            local kind1 = get_adjusted_ranking(entry1:get_kind())
            local kind2 = get_adjusted_ranking(entry2:get_kind())

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
            return cmp_buffer:compare_locality(...)
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
            cmdline = "Commandline",
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
  end,
})
