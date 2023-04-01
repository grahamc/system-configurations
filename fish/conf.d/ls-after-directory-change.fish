if not status is-interactive
  exit
end

function _ls-after-directory-change --on-variable PWD
  # These directories have too many files to always call ls on
  set blacklist /nix/store /tmp
  if contains "$PWD" $blacklist
    return
  end

  ls --hyperlink=auto
end
