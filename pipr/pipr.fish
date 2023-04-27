if not status is-interactive
  exit
end

abbr --add --global pipr 'pipr --no-isolation'
bind-no-focus \cp pipr-widget

function pipr-widget
  set -l commandline (commandline -b)
  set -l result (pipr --no-isolation --default "$commandline")
  commandline --replace $result
  commandline -f repaint
end
