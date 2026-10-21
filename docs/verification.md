# Development verification

See the [README](../README.md) for build and test commands.

## Current verification

Reported by the user on 21 October 2026:

- **Passed:** built the app on their laptop.
- **Passed:** used the app manually for three focus sessions, as reported in the follow-up to the readiness audit.
- **Passed in subsequent manual checks:** recovery and sleep/wake, reported by the user as all passing and behaving as expected after following the supplied test steps. This covers force-quit recovery (paused state, preserved submitted thoughts, excluded downtime, resume and end-as-interrupted), ordinary save-and-quit/reopen, and sleep/wake during countdown and overtime.
- **Still unverified:** simulated save failures and the other manual checks not marked passed below. Automated test results are recorded separately in the audit below.

### v1.0 readiness audit — 21 October 2026

Audited commit `427726c` on `main`, version **1.0 (build 1)**, using Xcode 27.1 (27A9275) on macOS 26.6.2, Apple Silicon. The working tree was clean at the start; remote `main` matched this commit. No remote tags or GitHub releases were present. Version 1.0/build 1 is suitable for the first release; later distributed builds should increment the build number.

- **Passed:** the README's Xcode Release build command. The resulting app at `build/DerivedData/Build/Products/Release/Focus.app` contains both `arm64` and `x86_64`; its plist reports version 1.0/build 1 and macOS 14.0 minimum. `codesign --verify --deep --strict` passed. Signing is ad-hoc, not Developer ID; notarization remains unconfigured.
- **Passed:** `./scripts/build-app.sh` and strict signature verification of `build/Focus.app`. This SwiftPM build contains only `arm64` on this machine; use the universal Xcode Release app when distributing one download for both Apple Silicon and Intel Macs.
- **Passed after the build-artifact cleanup described below:** the README's `xcodebuild ... test` command, all **10 tests in 2 suites** (8 timer-engine tests and 2 SwiftData persistence tests). Tests ran on Apple Silicon using temporary/in-memory stores. The result bundle is `build/DerivedData/Logs/Test/Test-Focus-2026.10.21_22-30-27-+0100.xcresult` (ignored by Git).
- **Test-harness issue observed:** SQLite logged that the temporary `Test.store` and sidecar files were unlinked while still open during persistence-test cleanup. All assertions passed. Review the temporary container lifetime/cleanup in `PersistenceTests.swift`; this diagnostic concerns the disposable test store, not evidence of corruption in the user's store.
- **Passed:** plist/project syntax validation and shell-script syntax checks.
- **Not performed in this audit:** interactive app testing, sleep/wake, force-quit recovery, simulated save failures, or runtime testing on Intel/macOS 14. All eight manual checks were open at the time; subsequent user-reported results are recorded above and below. Existing tests cover the core engine and repository, not the app controller or window lifecycle.
- **At the end of the audit:** manual checks, release notes, final commit/push, tag, ZIP, and GitHub Release were still pending. Subsequent preparation is recorded below.

Initial sandboxed build attempts could not run compiler plugins or access SwiftPM caches; builds were retried outside that sandbox. The first Xcode test attempt stopped before running tests because `codesign` rejected `com.apple.FinderInfo` on the generated `FocusTests.xctest` bundle in the OneDrive workspace. Only that attribute on the generated bundle was removed before retrying; source files and saved sessions were not changed. If this recurs, use a DerivedData directory outside the synced folder.

### Release preparation — 21 October 2026

- Saved the agreed public [v1.0 release notes](release-notes-v1.0.md). Detailed testing status remains in this document.
- Confirmed app source and build settings still match audited commit `427726c`; only documentation has changed. No additional app build or test run was needed for these documentation edits.
- Rechecked the universal Release app: version 1.0/build 1, `arm64` and `x86_64`, valid strict code signature.
- Packaged it as `build/releases/Focus-1.0-universal.zip` with a companion `.zip.sha256` checksum file. ZIP integrity passed; extraction into a temporary directory preserved every app file's contents and passed strict signature verification. SHA-256: `7ac9415f1380691ad61e56c0c48436654f1a3ee25a448cfed10a919d1a40ca33`.
- The ZIP has not been confirmed launched on another Mac. Recovery and sleep/wake subsequently passed user testing; remaining manual checks are listed below. At the end of this preparation stage, the final documentation commit/push, release tag, and GitHub Release attachment were still pending. Publication is tracked on the [GitHub Releases page](https://github.com/jennylaijiang/focus-timer-macos/releases).

## Historical results

These results were recorded during initial implementation with Swift 6.3.3 Command Line Tools and no full Xcode. They are historical, not verification of the current checkout. The later successful laptop build and session trial are recorded above.

- **Passed:** all 8 timer-engine tests.
- **Passed:** Xcode project and app plist syntax validation; shell-script syntax checks.
- **Passed with a limited scope:** SwiftUI/AppKit/controller type-check using temporary observable model and repository stand-ins, because the SwiftData macro plugin is absent. These stand-ins are not included in the project and are not an app implementation.
- **Blocked by tooling at that time:** full app compilation, `.app` packaging, SwiftData integration tests, and actual UI testing. That initial environment did not produce a working binary.

## Manual release checklist

Results marked passed are user-reported on 21 October 2026. Unmarked checks remain unverified individually.

1. Start a `0.1`-minute session. It begins at `00:06`, reaches red `+00:00`, and keeps counting. Pause/resume before and after zero, then finish; confirm durations.
2. Submit thoughts with Return, including whitespace-only input and Unicode. Confirm immediate clearing, newest-first order, and no blank entry. Test Copy and Copy all by pasting into TextEdit.
3. Open history while timing. Verify it keeps running, then finish, quit, relaunch, and verify saved thoughts and complete details.
4. **Passed:** force-quit an active session after at least one checkpoint. Relaunch and confirm paused recovery, preserved thoughts, and excluded downtime. Test both resume and “End as interrupted.”
5. **Partially verified:** ordinary save-and-quit/relaunch with paused recovery passed. Still check closing the active window: Cancel leaves it open, Keep Running hides it, and Dock reopen preserves the same session.
6. Toggle Always on Top on/off while switching between ordinary app windows. Collapse the sidebar, resize, and check light/dark appearance and long task/thought text.
7. **Passed:** sleep and wake the Mac during countdown and overtime. Confirm it stays paused on wake and requires manual resume.
8. On a disposable test store, simulate a write failure. Confirm errors remain visible, thought input survives a failed submission, final save can be retried, and quit does not discard unsaved state.

