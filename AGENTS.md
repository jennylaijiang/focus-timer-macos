# Project guidance

## Overview and stack

Focus is a small, offline macOS focus timer with thought capture and local session history. Keep the core workflow simple: start a task, capture distractions, and review completed sessions.

The app uses Swift, SwiftUI, AppKit, and SwiftData, targets macOS 14 or later, and has no third-party dependencies. Full Xcode is required for app builds and persistence tests; see [README.md](README.md) for requirements and commands.

## Architecture

- `Sources/FocusKit/TimerEngine.swift`: timer state and elapsed-time calculations.
- `Sources/FocusKit/Models.swift` and `SessionRepository.swift`: SwiftData models and persistence.
- `Sources/Focus/App/`: session coordination, app lifecycle, and window behavior.
- `Sources/Focus/Views/` and `Utilities/`: SwiftUI components and helpers.
- `Tests/FocusKitTests/`: timer and persistence tests.
- `Focus.xcodeproj`, `Package.swift`, and `scripts/`: Xcode and SwiftPM build paths and packaging.

## Coding conventions

- Follow the style and naming of nearby code; reuse existing SwiftUI components before introducing new abstractions.
- Keep timer calculations in the core engine and persistence operations in the repository, rather than adding them to views.
- Preserve timestamp-based timing; do not calculate elapsed time by counting UI refreshes.
- When adding or moving source files, check both Xcode and SwiftPM target membership.

## Working rules and constraints

- Make focused changes that address the requested task. Avoid unrelated refactoring and new dependencies for simple features.
- Preserve offline behavior. Add networking, accounts, analytics, or cloud sync only when explicitly included in the requested scope.
- Preserve existing sessions and thoughts when changing persistence. Plan and verify migrations for schema changes; do not silently reset an unreadable store.
- Never run destructive tests against live user data. Use temporary or in-memory stores, or disposable copies for migration testing.
- Keep databases, build products, credentials, and Xcode user state out of Git.
- Use judgment for routine implementation choices. Clarify scope before destructive data changes or major changes to the app's privacy or compatibility expectations unless already authorized.

## Testing

- Use the build and test commands in [README.md](README.md). Run relevant tests after code changes and build the app when changes affect the app target.
- Add or update tests for changed timer or persistence behavior, especially pause/resume, overtime, recovery, and saving/reopening sessions.
- For UI or lifecycle changes, manually exercise the affected behavior when possible. Use the [manual checklist](docs/verification.md) for broader release testing.
- The timer-only script does not verify SwiftData or the app. State tooling limitations rather than treating a partial check as full verification.
- Report what was actually tested and what remains unverified. Documentation-only edits require a content and link check, not an app rebuild.

## Documentation and known limitations

- Update the README when setup or user-facing behavior changes. Keep detailed verification results in [docs/verification.md](docs/verification.md).
- Distinguish confirmed bugs, intentional behavior, and untested scenarios. A successful focus session does not establish that every recovery scenario works.
- Sleep and recovery intentionally leave sessions paused; unobserved time after a crash is excluded. Preserve these semantics unless the requested change explicitly revises them.
- Local builds use ad-hoc signing. Developer ID distribution signing and notarization are not configured.
- Keep this file focused on durable project guidance; put feature ideas and version plans in a separate roadmap.
