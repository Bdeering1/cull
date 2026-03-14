#!/usr/bin/env bash

DAYS="${1:-90}"
MIN_SIZE_MB="${2:-0}"

# Core Functions
find_dirs() {
    local pattern="$1"
    local days="${2:-$DAYS}"

    for dir in $pattern; do
        [ -d "$dir" ] || continue
        find "$dir" -maxdepth 1 -mindepth 1 -type d -atime +"$days" 2>/dev/null
    done
}
get_sizes() {
    echo "$1" | tr '\n' '\0' | xargs -0 du -sh
}
filter_out_small() {
    awk -v min="$MIN_SIZE_MB" '
        {
            unit = substr($1, length($1))
            value = substr($1, 1, length($1)-1) + 0

            if (unit == "K") value = value / 1024
            else if (unit == "G") value = value * 1024

            if (value > min) print $0
        }
    '
}
print_targets() {
    get_sizes "$1" | filter_out_small | sed "s|$HOME|~|g" | sort -rh
}

# CLI Functions
clr()        { printf "\e[38;5;%sm%s\e[0m" "$2" "$1"; }
red()       { clr "$1" 9; }
green()      { clr "$1" 10; }
orange()     { clr "$1" 11; }
blue()       { clr "$1" 12; }
pink()       { clr "$1" 13; }
newline() { echo; }
hr=--------------------------------------------------------------------------------

confirm() {
    local default="${1:-n}"
    local reply

    read -r reply
    reply="${reply:-$default}"
    [[ "$reply" =~ ^[Yy]$ ]]
}

cull_directories=(
    "$HOME/Library/Caches"
    "$HOME/Library/Logs"
    "$HOME/Library/Containers/*/Data/Library/Caches"
    "$HOME/Library/Group Containers/*/Library/Caches"

    "$HOME/Library/Developer/CoreSimulator"
    "$HOME/Library/Developer/Xcode/DerivedData"
    "$HOME/Library/Developer/Xcode/IOS DeviceSupport"
    "$HOME/Library/Application Support/MobileSync/Backup"
)

pink $hr; newline
pink "Cull will find directories using the following criteria:"; newline
pink "- last read more than: $DAYS days ago"; newline
pink "- size greater than: ${MIN_SIZE_MB}MB"; newline
pink $hr; newline

pink "Continue? [Y/n] "; confirm "y" || exit 1

for root_dir in "${cull_directories[@]}"; do
    dirs=$(find_dirs "$root_dir")
    [ -z "$dirs" ] && continue

    newline
    blue "$root_dir"; newline
    blue $hr; newline
    print_targets "$dirs"; newline

    red "Continue? [Y/n] "; confirm "y" || exit 1
done
