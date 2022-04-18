# wrapper for 'dict' that pipes output through $PAGER
function dict --wraps dict
  command dict $argv | eval "$PAGER"
end
