function touch-and-make-parent-dirs --description 'Create file and make parent directories' --argument-names path_to_file
    set -l parent_folder (dirname $path_to_file)
    mkdir -p $parent_folder
    touch $path_to_file
end
