# Launch a gui silently

# TODO: Have it wrap sudo so it autocompletes program names.
# I should write my own completion script though since this will
# also autocomplete sudo flags.
function gui --wraps sudo
  # Redirecting the i/o files on the command itself still resulted in some output being sent to the
  # terminal, but putting the command in a block and redirecting the i/o files of the block does
  # the trick.
  begin
    $argv & disown
  end >/dev/null 2>/dev/null </dev/null
end
