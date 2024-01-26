-- Dependencies: nvim-lspconfig
Plug("SmiteshP/nvim-navic", {
  config = function()
    require("nvim-navic").setup({
      -- Allow control of the colors used through highlights
      highlight = true,
      -- click on a breadcrumb to jump there
      click = true,
    })
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        if vim.api.nvim_buf_line_count(0) > 10000 then
          -- For large files, only get update on CursorHold, not CursorMoved.
          ---@diagnostic disable-next-line: inject-field
          vim.b.navic_lazy_update_context = true
        end
      end,
    })
  end,
})

local path_segments_cache = {}
local path_segment_delimiter = "%#NavicSeparator# > "
local path_segment_delimiter_length = 3
-- NOTE: I'm misusing the `minwid` parameter in order to signify which path segment to jump to.
function WinbarPath(path_segment_index)
  local buffer = vim.fn.winbufnr(vim.fn.getmousepos().winid)
  local path = vim.api.nvim_buf_get_name(buffer)
  local segments = vim.split(path, "/", { trimempty = true })
  local path_to_segment = ""
  for i = 1, path_segment_index do
    path_to_segment = path_to_segment .. "/" .. segments[i]
  end
  require("nvim-tree.api").tree.find_file({ buf = path_to_segment, open = true, focus = true })
end
local function create_path_segment_from_string(segment, segment_index)
  return {
    length = #segment,
    text = "%#NavicText#%" .. segment_index .. "@v:lua.WinbarPath@" .. segment .. "%X",
  }
end
-- Most of this logic was taken from here:
-- https://github.com/utilyre/barbecue.nvim/blob/d38a2a023dfb1073dd0e8fee0c9be08855d3688f/lua/barbecue/ui/components.lua#L10
local function get_path_segments(path)
  if path_segments_cache[path] ~= nil then
    return path_segments_cache[path]
  end

  local path_segments = {}

  if path == "." then
    path_segments_cache[path] = {}
    return {}
  end

  local protocol_start_index = path:find("://")
  if protocol_start_index ~= nil then
    path = path:sub(protocol_start_index + 3)
  end

  local path_segment_strings = vim.split(path, "/", { trimempty = true })
  for index, segment_string in ipairs(path_segment_strings) do
    table.insert(path_segments, 1, create_path_segment_from_string(segment_string, index))
  end

  path_segments_cache[path] = path_segments
  return path_segments
end
function Winbar()
  local buffer = vim.api.nvim_get_current_buf()
  local window = vim.api.nvim_get_current_win()
  local winbar = ""
  local winbar_length = 0

  local ok, nvim_navic = pcall(require, "nvim-navic")
  if ok and nvim_navic and nvim_navic.is_available(buffer) then
    winbar = nvim_navic.get_location(nil, buffer)
    for _, datum in ipairs(nvim_navic.get_data(buffer) or {}) do
      -- the 5 is for the delimiter ' > ' and 2 more for the icon
      winbar_length = winbar_length + #datum.name + 5
    end
  end

  if vim.bo[buffer].filetype ~= "help" then
    local path = vim.api.nvim_buf_get_name(buffer)
    local path_segments = get_path_segments(path)
    local path_segments_count = #path_segments
    local max_winbar_length = vim.api.nvim_win_get_width(window)
    local abbreviation_text = "…" .. path_segment_delimiter
    local abbreviation_text_length = 1 + path_segment_delimiter_length
    for index, segment in ipairs(path_segments) do
      local potential_length = winbar_length + segment.length
      local has_more_segments = index < path_segments_count
      if
        (has_more_segments and potential_length <= (max_winbar_length - abbreviation_text_length))
        or ((not has_more_segments) and potential_length <= max_winbar_length)
      then
        if winbar_length ~= 0 then
          winbar = path_segment_delimiter .. winbar
          winbar_length = winbar_length + path_segment_delimiter_length
        end
        winbar = segment.text .. winbar
        winbar_length = winbar_length + segment.length
      else
        winbar = abbreviation_text .. winbar
        winbar_length = winbar_length + abbreviation_text_length
        break
      end
    end
  end

  return winbar
end
vim.o.winbar = "%{%v:lua.Winbar()%}"
