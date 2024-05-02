local function is_virtual_line()
  return vim.v.virtnum < 0
end

local function is_wrapped_line()
  return vim.v.virtnum > 0
end

-- Fold column calculation was taken from the following files in the plugin
-- statuscol.nvim:
-- https://github.com/luukvbaal/statuscol.nvim/blob/98d02fc90ebd7c4674ec935074d1d09443d49318/lua/statuscol/ffidef.lua
-- https://github.com/luukvbaal/statuscol.nvim/blob/98d02fc90ebd7c4674ec935074d1d09443d49318/lua/statuscol/builtin.lua
local ffi = require("ffi")
-- I moved this call to `cdef` outside the fold function because I was getting
-- the error "table overflow" a few seconds into using neovim. Plus, not calling
-- this during the fold function is faster.
ffi.cdef([[
  int next_namespace_id;
  uint64_t display_tick;
  typedef struct {} Error;
  typedef struct {} win_T;
  typedef struct {
    int start;  // line number where deepest fold starts
    int level;  // fold level, when zero other fields are N/A
    int llevel; // lowest level that starts in v:lnum
    int lines;  // number of lines from v:lnum to end of closed fold
  } foldinfo_T;
  foldinfo_T fold_info(win_T* wp, int lnum);
  win_T *find_window_by_handle(int Window, Error *err);
  int compute_foldcolumn(win_T *wp, int col);
  int win_col_off(win_T *wp);
]])
local function get_fold_section()
  local wp =
    ffi.C.find_window_by_handle(vim.g.statusline_winid, ffi.new("Error"))
  local foldinfo = ffi.C.fold_info(wp, vim.v.lnum)
  local string = "%#FoldColumn#"
  local level = foldinfo.level

  if is_virtual_line() or is_wrapped_line() or level == 0 then
    return "  "
  end

  if foldinfo.start == vim.v.lnum then
    local closed = foldinfo.lines > 0
    if closed then
      string = string .. ""
    else
      string = string .. ""
    end
  else
    string = string .. " "
  end
  string = string .. " "

  return string
end

function StatusColumn()
  local buffer = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
  local border_highlight = "%#NonText#"
  local gitHighlights = {
    SignifyAdd = "SignifyAdd",
    SignifyRemoveFirstLine = "SignifyDelete",
    SignifyDelete = "SignifyDelete",
    SignifyDeleteMore = "SignifyDelete",
    SignifyChange = "SignifyChange",
  }
  -- There will be one item at most in this list since I supplied a buffer
  -- number.
  local signsPerBuffer = vim.fn.sign_getplaced(
    buffer,
    { lnum = vim.v.lnum, group = "" }
  ) or {}
  if next(signsPerBuffer) ~= nil then
    for _, sign in ipairs(signsPerBuffer[1].signs) do
      local name = sign.name
      local highlight = gitHighlights[name]
      if highlight ~= nil then
        border_highlight = "%#" .. highlight .. "#"
        break
      end
    end
  end
  local border_char = vim.v.virtnum > 0 and "┋" or "┃"
  if border_highlight == "%#NonText#" then
    border_char = " "
  end
  local border_section = border_highlight .. border_char

  local line_number_section = nil
  if not ShowLineNumbers then
    line_number_section = ""
  else
    local last_line_digit_count =
      #tostring(vim.fn.line("$", vim.g.statusline_winid))
    if is_virtual_line() or is_wrapped_line() then
      line_number_section = string.rep(" ", last_line_digit_count)
    else
      local line_number = tostring(vim.v.lnum)
      local line_number_padding =
        string.rep(" ", last_line_digit_count - #line_number)
      line_number_section = line_number_padding .. line_number
    end
  end

  local fold_section = get_fold_section()
  local sign_section = "%s"
  local align_right = "%="

  return align_right
    .. line_number_section
    .. border_section
    .. sign_section
    .. fold_section
end

vim.o.statuscolumn = "%!v:lua.StatusColumn()"
vim.o.signcolumn = "yes:2"
