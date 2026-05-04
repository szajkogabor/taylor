# taylor

`taylor` is a Swift command-line reminder tool for macOS.

It is designed to feel like a fast terminal-native workflow while storing reminders through Apple's EventKit ecosystem.

## Status

This project is in active development.

- The CLI contract is being finalized around: `add`, `remove`, `list`, `help`, `version`, and `author`.
- EventKit-backed reminder operations are the current foundation.
- Behavior documented here is the intended public contract for Phase 1.

## Why taylor

- Native macOS reminders integration via EventKit
- Simple command surface for automation and shell workflows
- Deterministic output for scripts (`list` ordering is stable)
- Granular POSIX-style exit codes

## Command Overview

Planned command shape:

```text
taylor <command> [options]
```

Core commands:

- `add <title> [--notes <text>] [--due <iso8601>] [--list <name>]`
- `remove <id>`
- `list [--list <name>] [--all]`
- `help [command]`
- `version`
- `author`

Aliases can be added later, but are not required for the initial EventKit-focused release.

## Usage Examples

```bash
# Add a reminder
taylor add "Pay rent" --due 2026-05-10T09:00:00Z --notes "bank transfer"

# List reminders
taylor list

# List reminders from a specific reminders list/calendar
taylor list --list Personal

# Remove by identifier
taylor remove <id>

# Show command help
taylor help
taylor help add

# Show version and author metadata
taylor version
taylor author
```

## List Ordering Contract

`list` output is deterministic and sorted by:

1. Due date ascending (`nil`/missing due date is always last)
2. Title ascending (case-insensitive)
3. Stable fallback key (for deterministic ties)

This contract is intended for both user readability and script stability.

## POSIX-Style Return Codes

`taylor` uses explicit non-zero exit codes so shell scripts can branch reliably.

| Code | Meaning |
| --- | --- |
| `0` | Success |
| `2` | Invalid top-level usage or argument parsing failure |
| `64` | Command-specific usage error (missing/invalid command arguments) |
| `69` | Service unavailable (EventKit store unavailable) |
| `73` | Cannot create (failed to save a new reminder) |
| `74` | Read/list operation failure |
| `77` | Permission denied/restricted by EventKit authorization |
| `78` | Configuration/state error (for example, unknown reminders list) |
| `1` | Unclassified runtime failure (fallback) |

## EventKit Permissions

`taylor` requires reminders access.

- On first run, macOS may prompt for Reminders permission.
- If permission is denied, the CLI exits with code `77`.
- You can manage access in System Settings -> Privacy & Security -> Reminders.

## Development

This repository currently contains an Xcode project (`taylor.xcodeproj`).

Typical local development flow:

```bash
# Open the project
open taylor.xcodeproj
```

As command implementation lands, this README will be updated with exact build/run commands.

## Testing

Planned Phase 1 unit-test focus:

- parser behavior for all supported commands
- command handler success/failure paths
- deterministic `list` ordering (due date, then title)
- exit code mapping validation
- EventKit-independent tests using protocol-based fakes/mocks

## Contributing

Issues and pull requests are welcome.

Please include:

- a clear problem statement
- reproduction or CLI examples when relevant
- tests for behavioral changes

## License

MIT. See `LICENSE`.
