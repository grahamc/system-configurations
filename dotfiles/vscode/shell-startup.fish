#!/usr/bin/env fish

set session_name (prompt_pwd)
if not tmux attach-session -d -t "$session_name"
  tmux new-session -s "$session_name"
end