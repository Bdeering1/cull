# Cull

Reclaim disk space by removing stale caches, logs, and unneeded files.

## Usage

```sh
git clone https://github.com/bdeering1/cull.git
cd cull && ./cull
```

## Options

| Flag | Description | Default |
|---|---|---|
| `--age <days>` | Minimum days since a directory was last accessed | `90` |
| `--min-size <mb>` | Minimum directory size in MB | `0` |
| `--dry` | Preview results without deleting anything | `false` |
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

## Safety

- Cull operates only on the directories listed above and never touches system files
- Every deletion requires explicit confirmation
- Use `--dry` to preview exactly what would be removed with risk of deletion
