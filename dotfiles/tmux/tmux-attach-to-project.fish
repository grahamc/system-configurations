#!/usr/bin/env fish

# Some characters can't be used in a session name so I'll substitute them the same way tmux would if I were to pass
# the original name to `tmux new-session -s <original_name>`.
set session_name (prompt_pwd | string replace --all '.' '_')

if not tmux attach-session -t "$session_name"
  tmux new-session -s "$session_name"
end
