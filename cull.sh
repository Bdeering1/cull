#!/usr/bin/env bash

export COLUMNS

AGE_DAYS=90
MIN_SIZE_MB=0
DRY_RUN=false

usage() {
    echo
    echo "Cull - Interactive disk cleanup tool for macOS"
    echo
    echo "Usage: cull [options]"
    echo ""
    echo "Options:"
    echo "  --age <days>      Minimum days since last accessed  (default: $AGE_DAYS)"
    echo "  --min-size <mb>   Minimum directory size in MB      (default: $MIN_SIZE_MB)"
    echo "  --dry             Preview without deleting"
    echo "  --help            Show this help message"
    echo
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --age) AGE_DAYS="$2"; shift ;;
        --min-size) MIN_SIZE_MB="$2"; shift ;;
        --dry) DRY_RUN=true ;;
        --help) usage; exit 0 ;;
        *) ;;
    esac
    shift
done

# Core Functions
find_dirs() {
    local pattern="$1"
    local days="${2:-$AGE_DAYS}"

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
hr() {
    width=$(stty size 2>/dev/null | cut -d' ' -f2 || echo 80)
    printf '%*s\n' "$width" '' | tr ' ' '-';
}

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

pink "$(hr)"; newline
pink "Cull - Interactive disk cleanup tool for macOS"; newline; newline
pink "Finding stale caches, logs, and unneeded files using these criteria:"; newline
pink "  - last accessed more than: $AGE_DAYS days ago"; newline
pink "  - size greater than: ${MIN_SIZE_MB}MB"; newline
pink "$(hr)"; newline

pink "Continue? [Y/n] "; confirm "y" || exit 0

TOTAL_SAVED_MB=0
for root_dir in "${cull_directories[@]}"; do
    dirs=$(find_dirs "$root_dir")
    [ -z "$dirs" ] && continue

    filter_sum=$(filter_and_sum "$dirs")
    targets=$(echo "$filter_sum" | sed '$d')
    total=$(echo "$filter_sum" | tail -n 1)
    [ -z "$targets" ] && continue

    newline
    blue "$root_dir"; newline
    blue "$(hr)"; newline
    echo "$targets"

    newline
    orange "Total size: $total"; newline; newline

    if $DRY_RUN; then
        red "Skipped directory removal (dry run)."; newline
        green "Continue? [Y/n] "
        confirm "y" || exit 0
        continue
    fi

    red "Delete these directories? [y/N] "
    if ! confirm; then
        green "Skipped directory removal."; newline
        continue
    fi

    delete_dirs "$targets"
    green "Removed $total of files."; newline
    TOTAL_SAVED_MB=$(echo "$TOTAL_SAVED_MB + $(to_mb "$total")" | bc)
done

if [ "$TOTAL_SAVED_MB" = 0 ]; then exit 0; fi
newline
green "$(hr)"; newline
green "Total space saved: $(format_mb "$TOTAL_SAVED_MB")"; newline
green "$(hr)"; newline; newline
