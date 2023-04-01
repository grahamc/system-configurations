if not status is-interactive
  exit
end

if command -s fzf-share >/dev/null
  source (fzf-share)/key-bindings.fish
end

fzf_key_bindings
