function pipr-widget
  set -l commandline (commandline -b)
  set -l result (pipr --default "$commandline")
  commandline --replace $result
  commandline -f repaint
end
