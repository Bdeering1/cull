#!/usr/bin/env bash

DAYS="${1:-90}"
MIN_SIZE_MB="${2:-0}"
TOTAL_SAVED_MB=0

# Core Functions
find_dirs() {
    local pattern="$1"
    local days="${2:-$DAYS}"

    for dir in $pattern; do
        [ -d "$dir" ] || continue
        find "$dir" -maxdepth 1 -mindepth 1 -type d -atime +"$days" 2>/dev/null
    done
}

filter_and_sum() {
    get_sizes "$1" | sort -rh | sed "s|$HOME|~|g" | awk -v min="$MIN_SIZE_MB" '
        function to_mb(size,    unit, value) {
            unit = substr(size, length(size))
            value = substr(size, 1, length(size)-1) + 0
            if (unit == "K") return value / 1024
            if (unit == "G") return value * 1024
            return value
        }
        {
            mb = to_mb($1)
            if (mb > min) {
                print $0
                total += mb
            }
        }
        END {
            if (total >= 1024) printf "%.1fG\n", total / 1024
            else printf "%.1fM\n", total
        }
    '
}

get_sizes() { echo "$1" | tr '\n' '\0' | xargs -0 du -sh; } # $1 must be non-empty

to_mb() {
    local size="$1"
    local unit="${size: -1}"
    local value="${size%?}"
    if [[ "$unit" == "G" ]]; then echo "$value * 1024" | bc
    elif [[ "$unit" == "K" ]]; then echo "scale=4; $value / 1024" | bc
    else echo "$value"
    fi
}

format_mb() {
    local mb="$1"
    if (( $(echo "$mb >= 1024" | bc) )); then
        printf "%.1fG" "$(echo "scale=1; $mb / 1024" | bc)"
    else
        printf "%.1fM" "$mb"
    fi
}

delete_dirs() {
    while IFS= read -r line; do
        local dir
        dir=$(echo "$line" | cut -f2 | sed "s|~|$HOME|g")
        [ -d "$dir" ] || continue

        rm -rf "$dir"
    done <<< "$1"
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

    "$HOME/Library/Developer/CoreSimulator"
    "$HOME/Library/Developer/Xcode/DerivedData"
    "$HOME/Library/Developer/Xcode/iOS DeviceSupport"
    "$HOME/Library/Application Support/MobileSync/Backup"
)

pink "$hr"; newline
pink "Cull will find directories using the following criteria:"; newline
pink "- last read more than: $DAYS days ago"; newline
pink "- size greater than: ${MIN_SIZE_MB}MB"; newline
pink "$hr"; newline

pink "Continue? [Y/n] "; confirm "y" || exit 1

for root_dir in "${cull_directories[@]}"; do
    dirs=$(find_dirs "$root_dir")
    [ -z "$dirs" ] && continue

    filter_sum=$(filter_and_sum "$dirs")
    targets=$(echo "$filter_sum" | sed '$d')
    total=$(echo "$filter_sum" | tail -n 1)
    [ -z "$targets" ] && continue

    newline
    blue "$root_dir"; newline
    blue $hr; newline
    echo "$targets"

    newline
    orange "Total size: $total"; newline; newline

    red "Delete these directories? [y/N] "; confirm || continue
    delete_dirs "$targets"
    green "Removed $total of files."; newline
    TOTAL_SAVED_MB=$(echo "$TOTAL_SAVED_MB + $(to_mb "$total")" | bc)
done

[ "$TOTAL_SAVED_MB" = 0 ] && exit 0
newline
green "$hr"; newline
green "Total space saved: $(format_mb "$TOTAL_SAVED_MB")"; newline
green "$hr"; newline; newline
