# TODO: handle '-o' argument
function rust --description 'run the given rust source file' --wraps rustc
    if test (count $argv) -eq 0
        echo -s \
            (set_color red) \
            'ERROR: You must provide at least one argument, the source file to be run' >/dev/stderr
        return 1
    end

    set source_file $argv[-1]
    set executable_name (basename $source_file .rs)
    rustc $argv
        and begin
            ./$executable_name
            rm $executable_name
        end
end
