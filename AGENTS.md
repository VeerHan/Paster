# Agents

## Cursor Cloud specific instructions

### Project overview

Paster is a **native macOS clipboard history manager** built with Swift 5.9 / SwiftUI / AppKit. It has no external package dependencies — all imports are Apple system frameworks. See `README.md` for full details.

### Environment limitations

This is a macOS-only Xcode project. On the Linux Cloud Agent VM:

- **Cannot build or run** the application (`xcodebuild` requires macOS + Xcode).
- **Can lint** with SwiftLint: `swiftlint lint` (runs against all 12 `.swift` files under `Paster/`).
- **Can syntax-parse** individual files: `swiftc -parse Paster/**/*.swift` (uses the Linux Swift toolchain; validates syntax but not macOS-specific type checking).

### Available tools

| Tool | Command | Notes |
|------|---------|-------|
| SwiftLint | `swiftlint lint` | Static Linux binary at `/usr/local/bin/swiftlint`. Runs without SourceKit (`statement_position` rule is skipped). |
| Swift compiler (syntax) | `swiftc -parse <file.swift>` | Requires `. "$HOME/.local/share/swiftly/env.sh"` first. Only validates syntax, not types (macOS frameworks like AppKit/SwiftUI are unavailable). |

### Linting

Run from the repo root:

```bash
swiftlint lint
```

The project currently has ~25 lint warnings/errors (pre-existing). There is no `.swiftlint.yml` config file, so default SwiftLint rules apply.

### Build & Run (macOS only)

Per `README.md` and the workspace rule in `.cursor/rules/deploy-and-restart.mdc`:

```bash
xcodebuild -scheme Paster -configuration Debug -derivedDataPath build build
```

This is **not runnable** on the Cloud Agent Linux VM.

### Key caveats

- No automated test suite exists in this repository (no XCTest targets).
- No package manager dependencies to install (no SPM, CocoaPods, or Carthage).
- The `.cursor/rules/deploy-and-restart.mdc` rule prescribes a macOS-specific build-install-restart cycle that does not apply on Linux.
