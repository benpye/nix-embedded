source $stdenv/setup

sources_=($sources)
targets_=($targets)

objects=($objects)
symlinks=($symlinks)

# Remove the initial slash from a path, since genisofs likes it that way.
stripSlash() {
    res="$1"
    if test "${res:0:1}" = /; then res=${res:1}; fi
}

# Add the individual files.
for ((i = 0; i < ${#targets_[@]}; i++)); do
    stripSlash "${targets_[$i]}"
    mkdir -p "$(dirname "$res")"
    cp -a "${sources_[$i]}" "$res"
done


# Add the closures of the top-level store objects.
chmod +w .
mkdir -p nix/store
for i in $(< $closureInfo/store-paths); do
    cp -a "$i" "${i:1}"
done

# Add symlinks to the top-level store objects.
for ((n = 0; n < ${#objects[*]}; n++)); do
    object=${objects[$n]}
    symlink=${symlinks[$n]}
    if test "$symlink" != "none"; then
        mkdir -p $(dirname ./$symlink)
        ln -s $object ./$symlink
    fi
done

$extraCommands

rm env-vars

time mksquashfs . $out -all-root -b 1048576 -comp $comp $extraArgs
