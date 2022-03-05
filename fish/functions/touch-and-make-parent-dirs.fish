function touch-and-make-parent-dirs --description 'Create file and make parent directories' --argument-names filepath
    set -l parent_folder (dirname $filepath)
    mkdir -p $parent_folder
    touch $filepath
end
