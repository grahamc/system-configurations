vim.opt.sessionoptions:remove("blank")
vim.opt.sessionoptions:remove("options")
vim.opt.sessionoptions:append("tabpages")
vim.opt.sessionoptions:remove("folds")

local session_dir = vim.fn.stdpath("data") .. "/sessions"

local function save_session()
  local has_active_session = string.len(vim.v.this_session) > 0
  if has_active_session then
    vim.cmd({
      cmd = "mksession",
      args = { vim.fn.fnameescape(vim.v.this_session) },
      bang = true,
    })
  end
end

local function restore_or_create_session()
  -- We only want to restore/create a session if:
  --  1. neovim was called with no arguments. The first element in `vim.v.argv` will always be the
  --  path to the vim -- executable and the second will be '--embed' so if no arguments were passed
  --  to neovim, the size of `vim.v.argv` -- will be two.
  --  2. neovim's stdin is a terminal. If neovim's stdin isn't the terminal, then that means
  --  content is being -- piped in and we should load that instead.
  local is_neovim_called_with_no_arguments = #vim.v.argv == 2
  local has_ttyin = vim.fn.has("ttyin") == 1
  if is_neovim_called_with_no_arguments and has_ttyin then
    local session_name = string.gsub(vim.fn.getcwd(), "/", "%%") .. "%vim"
    vim.fn.mkdir(session_dir, "p")
    local session_full_path = session_dir .. "/" .. session_name
    local session_full_path_escaped = vim.fn.fnameescape(session_full_path)
    if vim.fn.filereadable(session_full_path) ~= 0 then
      vim.cmd("silent source " .. session_full_path_escaped)
    else
      vim.cmd({
        cmd = "mksession",
        args = { session_full_path_escaped },
        bang = true,
      })
    end

    local save_session_group_id = vim.api.nvim_create_augroup("SaveSession", {})

    -- Save the session whenever the window layout or active window changes
    vim.api.nvim_create_autocmd({ "BufEnter" }, {
      callback = save_session,
      group = save_session_group_id,
    })

    -- save session before vim exits
    vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
      callback = save_session,
      group = save_session_group_id,
    })
  end
end

-- Restore/create session after vim starts.
vim.api.nvim_create_autocmd({ "VimEnter" }, {
  callback = restore_or_create_session,
  group = vim.api.nvim_create_augroup("RestoreOrCreateSession", {}),
  -- The 'nested' option tells vim to fire events normally while this autocommand is executing. By
  -- default, no events are fired during the execution of an autocommand to prevent infinite loops.
  nested = true,
})

local function delete_current_session()
  local session = vim.v.this_session

  local has_active_session = string.len(session) > 0
  if not has_active_session then
    vim.cmd.echoerr([['ERROR: No session is currently active.']])
    return
  end

  -- Stop saving the current session
  pcall(vim.api.nvim_del_augroup_by_name, "SaveSession")

  local exit_code = vim.fn.delete(session)
  if exit_code == -1 then
    vim.cmd.echoerr(string.format([["Failed to delete current session '%s'."]], session))
  end
end
local function delete_all_sessions()
  -- Stop saving the current session, if there is one.
  pcall(vim.api.nvim_del_augroup_by_name, "SaveSession")

  if not vim.fn.isdirectory(session_dir) then
    vim.cmd.echoerr(
      string.format([["Unable to delete all sessions, '%s' is not a directory."]], session_dir)
    )
    return
  end

  local sessions = vim.fn.split(vim.fn.globpath(session_dir, "*"), "\n")
  for _, session in ipairs(sessions) do
    local exit_code = vim.fn.delete(session)
    if exit_code == -1 then
      vim.cmd.echoerr(
        string.format(
          [["Failed to delete session '%s'. Aborting the rest of the operation..."]],
          session
        )
      )
      return
    end
  end
end
vim.api.nvim_create_user_command(
  "DeleteCurrentSession",
  delete_current_session,
  { desc = "Delete the current session" }
)
vim.api.nvim_create_user_command(
  "DeleteAllSessions",
  delete_all_sessions,
  { desc = "Delete all sessions" }
)
