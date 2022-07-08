if not status is-interactive
  exit
end

function _ls-after-directory-change --on-variable PWD
  ls -x --classify --color=never --hyperlink=auto
end
