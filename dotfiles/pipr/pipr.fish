if not status is-interactive
  exit
end

if not uname | grep -q Linux
  exit
end

abbr --add --global pipr 'pipr --no-isolation'
mybind --no-focus \cp widget-pipr

function widget-pipr
  set -l commandline (commandline -b)
  set -l result (pipr --no-isolation --default "$commandline")
  commandline --replace $result
  commandline -f repaint
end
