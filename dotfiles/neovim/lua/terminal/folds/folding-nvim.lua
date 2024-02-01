-- This is a fork of the following plugin:
-- https://github.com/pierreglaser/folding-nvim/tree/5d2b3d98c47c8c16aade06ebfd411bc74ad6d205
--
-- TODO: I should upstream this

local lsp = vim.lsp
local api = vim.api

local AUTOCMD_GROUP_ID = vim.api.nvim_create_augroup("FoldingNvim", {})
local START_LINE = "startLine"
local END_LINE = "endLine"

local M = {}

-- TODO: per-buffer fold table?
M.current_buf_folds = {}

M.fold_support_by_client_id = {}

M.capabilities = {
  textDocument = {
    foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    },
  },
}

function M.on_attach()
  M.setup_plugin()
  M.update_folds()
end

function M.setup_plugin()
  local buffer = vim.api.nvim_get_current_buf()
  local events = { "BufEnter", "BufWritePost" }
  vim.api.nvim_clear_autocmds({
    event = events,
    buffer = buffer,
    group = AUTOCMD_GROUP_ID,
  })
  vim.api.nvim_create_autocmd(events, {
    group = AUTOCMD_GROUP_ID,
    buffer = buffer,
    callback = M.update_folds,
  })
end

function M.update_folds()
  if not M.is_foldmethod_overridable() then
    return
  end

  local clients = lsp.buf_get_clients(0)
  for _, client in pairs(clients) do
    -- TODO: This is the recommended way to do it, but bash_ls returns true when I try it
    -- despite not supporting it. Not sure where the bug is.
    -- if not client.supports_method(lsp.protocol.Methods.textDocument_foldingRange) then
    local server_supports_folding = client["server_capabilities"]["foldingRangeProvider"] or false
    if not server_supports_folding then
      goto continue
    end

    -- TODO: better to pass callback in this method or add it directly in the config?
    -- client.config.callbacks['textDocument/foldingRange'] = M.fold_handler
    local buffer = api.nvim_get_current_buf()
    local params = { uri = vim.uri_from_bufnr(buffer) }
    client.request(
      lsp.protocol.Methods.textDocument_foldingRange,
      { textDocument = params },
      M.fold_handler,
      buffer
    )

    ::continue::
  end
end

function M.debug_folds()
  for _, table in ipairs(M.current_buf_folds) do
    local start_line = table[START_LINE]
    local end_line = table[END_LINE]
    print(START_LINE, start_line, END_LINE, end_line)
  end
end

function M.fold_handler(err, result, ctx, _)
  local current_bufnr = api.nvim_get_current_buf()
  -- Discard the folding result if buffer focus has changed since the request was
  -- done.
  if current_bufnr ~= ctx.bufnr then
    return
  end

  if err ~= nil then
    vim.notify(err.message, vim.log.levels.DEBUG)
    return
  end

  -- client wont return a valid result in early stages after initialization
  -- XXX: this is dirty
  if result == nil then
    vim.defer_fn(M.update_folds, 100)
  end

  for _, fold in ipairs(result) do
    fold[START_LINE] = M.adjust_foldstart(fold[START_LINE])
    fold[END_LINE] = M.adjust_foldend(fold[END_LINE])
  end
  table.sort(result, function(a, b)
    return a[START_LINE] < b[START_LINE]
  end)
  M.current_buf_folds = result

  -- We need to check the foldmethod again since it may have changed since we launched the request.
  if not M.is_foldmethod_overridable() then
    return
  end
  vim.wo.foldmethod = "expr"
  vim.wo.foldexpr =
    [[luaeval(printf('require"terminal.folds.folding-nvim".get_fold_indic(%d)', v:lnum))]]
end

function M.adjust_foldstart(line_no)
  return line_no + 1
end

function M.adjust_foldend(line_no)
  if vim.bo.filetype == "lua" then
    return line_no + 2
  else
    return line_no + 1
  end
end

function M.get_fold_indic(lnum)
  local fold_level = 0
  local is_foldstart = false
  local is_foldend = false

  for _, table in ipairs(M.current_buf_folds) do
    local start_line = table[START_LINE]
    local end_line = table[END_LINE]

    -- can exit early b/c folds get pre-orderered manually
    if lnum < start_line then
      break
    end

    if lnum >= start_line and lnum <= end_line then
      fold_level = fold_level + 1
      if lnum == start_line then
        is_foldstart = true
      end
      if lnum == end_line then
        is_foldend = true
      end
    end
  end

  if is_foldend and is_foldstart then
    -- If line marks both start and end of folds (like ``else`` statement),
    -- merge the two folds into one by returning the current foldlevel
    -- without any marker.
    return fold_level
  elseif is_foldstart then
    return string.format(">%d", fold_level)
  elseif is_foldend then
    return string.format("<%d", fold_level)
  else
    return fold_level
  end
end

function M.is_foldmethod_overridable()
  return not vim.tbl_contains({ "marker", "diff" }, vim.wo.foldmethod)
end

return M
