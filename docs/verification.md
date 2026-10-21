# Development verification

See the [README](../README.md) for build and test commands.

## Current verification

Reported by the user on 21 October 2026:

- **Passed:** built the app on their laptop.
- **Passed:** tried the app for one focus session and reported that it worked.
- **Not yet verified:** automated tests for this version and the individual checks below. The successful session does not establish that every feature or recovery scenario has been tested.

## Historical results

These results were recorded during initial implementation with Swift 6.3.3 Command Line Tools and no full Xcode. They are historical, not verification of the current checkout. The later successful laptop build and session trial are recorded above.

- **Passed:** all 8 timer-engine tests.
- **Passed:** Xcode project and app plist syntax validation; shell-script syntax checks.
- **Passed with a limited scope:** SwiftUI/AppKit/controller type-check using temporary observable model and repository stand-ins, because the SwiftData macro plugin is absent. These stand-ins are not included in the project and are not an app implementation.
- **Blocked by tooling at that time:** full app compilation, `.app` packaging, SwiftData integration tests, and actual UI testing. That initial environment did not produce a working binary.

## Manual release checklist

The following checks remain unverified individually. Use this checklist for further release testing:

1. Start a `0.1`-minute session. It begins at `00:06`, reaches red `+00:00`, and keeps counting. Pause/resume before and after zero, then finish; confirm durations.
2. Submit thoughts with Return, including whitespace-only input and Unicode. Confirm immediate clearing, newest-first order, and no blank entry. Test Copy and Copy all by pasting into TextEdit.
3. Open history while timing. Verify it keeps running, then finish, quit, relaunch, and verify saved thoughts and complete details.
4. Force-quit an active session after at least one checkpoint. Relaunch and confirm paused recovery, preserved thoughts, and excluded downtime. Test both resume and “End as interrupted.”
5. Close the active window. Confirm Cancel leaves it open, Keep Running hides it, and Dock reopen preserves the same session. Quit and relaunch; confirm paused recovery.
6. Toggle Always on Top on/off while switching between ordinary app windows. Collapse the sidebar, resize, and check light/dark appearance and long task/thought text.
7. Sleep and wake the Mac during countdown and overtime. Confirm it stays paused on wake and requires manual resume.
8. On a disposable test store, simulate a write failure. Confirm errors remain visible, thought input survives a failed submission, final save can be retried, and quit does not discard unsaved state.

