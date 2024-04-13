local M = {}

function M.get_max_line_length()
  local editorconfig = vim.b["editorconfig"]
  if editorconfig ~= nil and editorconfig.max_line_length ~= nil then
    return tonumber(editorconfig.max_line_length)
  end

  return ({
    -- default for black
    python = 88,
  })[vim.bo.filetype] or 80
end

function M.get_visual_selection()
  local mode_char = vim.fn.mode()
  -- "\x16" is the code for ctrl+v i.e. visual-block mode
  local in_visual_mode = mode_char == "v"
    or mode_char == "V"
    or mode_char == "\x16"
  if not in_visual_mode then
    return ""
  end

  vim.cmd('noau normal! "vy"')
  local text = vim.fn.getreg("v") or ""
  vim.fn.setreg("v", {})

  -- remove trailing newline
  if mode_char == "V" then
    text = text:sub(1, -2)
  end

  return text
end

function M.escape_percent(string_to_escape)
  return string_to_escape:gsub("([^%w])", "%%%1")
end

function M.get_char()
  local ret_val, char_num = pcall(vim.fn.getchar)
  -- Return nil if error (e.g. <C-c>) or for control characters
  if not ret_val or char_num < 32 then
    return nil
  end
  local char = vim.fn.nr2char(char_num)

  return char
end

function M.table_concat(t1, t2)
  for i = 1, #t2 do
    t1[#t1 + 1] = t2[i]
  end
  return t1
end

return M
