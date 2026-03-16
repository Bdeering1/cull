# Cull

Reclaim disk space by removing stale caches, logs, and unneeded files.

The goal of this project is to provide a safe and transparent tool for removing unneeded bloat on macOS. Cull operates only on the directories listed below and never touches system files. Confirmation is explicitly requested before every deletion. The only pre-requisite is Bash 3.2+ which ships with macOS by default.

## Installation

**Quick install**
```sh
curl -fsSL https://raw.githubusercontent.com/Bdeering1/cull/main/install.sh | bash
```

**From source**
```sh
git clone https://github.com/yourname/cull.git
cd cull
./install.sh
```

## Usage
```sh
cull [options]
```

> Note: Cull requires Full Disk Access to scan all target directories.
> Grant access to your terminal in *System Settings → Privacy & Security → Full Disk Access*,
> then restart your terminal before running.

## Options

| Flag | Description | Default |
|---|---|---|
| `--age <days>` | Minimum days since a directory was last accessed | `90` |
| `--min-size <mb>` | Minimum directory size in MB | `0` |
| `--dry` | Preview without risk of deletion | `false` |
| `--help` | Show usage information | |

## Target Directories

| Directory | Contents |
|---|---|
| `~/Library/Caches` | Application cache files |
| `~/Library/Logs` | Application log files |
| `~/Library/Containers/*/Data/Library/Caches` | Sandboxed app caches |
| `~/Library/Developer/CoreSimulator` | iOS simulator data |
| `~/Library/Developer/Xcode/DerivedData` | Xcode build artifacts |
| `~/Library/Developer/Xcode/iOS DeviceSupport` | iOS device symbols |
| `~/Library/Application Support/MobileSync/Backup` | iOS device backups |

### Notes on specific directories

**Xcode DerivedData**: Xcode rebuilds this automatically the next time you build a project. Safe to delete entirely.

**iOS DeviceSupport**: Contains debugging symbols for specific iOS versions. Safe to delete for iOS versions you no longer test against.

**MobileSync Backup**: Local iOS device backups. Before deleting, ensure your device is backed up to iCloud or you have another backup available.

**CoreSimulator**: Data for iOS simulators. Safe to delete for simulators you no longer use.
