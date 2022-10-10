if not status is-interactive
  exit
end

function _ls-after-directory-change --on-variable PWD
  ls --hyperlink=auto
end
