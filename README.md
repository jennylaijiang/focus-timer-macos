# Focus

A small, offline macOS study timer with a thought parking lot. Work on one task, capture distractions with Return, and keep going in overtime until you choose to finish.

## Requirements

- macOS 14 or later.
- **Full Xcode 16 or later** for building the app and running the complete test suite. Tests use Swift Testing. Apple Command Line Tools alone may lack the SwiftData macro compiler plugin.
- No third-party packages, accounts, network services, or API keys.

## Open and run

1. Open `Focus.xcodeproj` in Xcode.
2. Select the shared **Focus** scheme and **My Mac** destination.
3. Build and run with **⌘R**. Local builds use ad-hoc signing; no development team is required.

If command-line builds report missing SwiftData macros, select your full Xcode installation under **Xcode → Settings → Locations → Command Line Tools**.

From Terminal, with full Xcode selected:

```sh
xcodebuild -project Focus.xcodeproj -scheme Focus \
  -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData build
open build/DerivedData/Build/Products/Debug/Focus.app
```

## Standalone app

The Xcode target produces a native `.app`, not a terminal or web application. In Xcode, expand Products, right-click **Focus.app**, and choose **Show in Finder**. Copy it to Applications if desired. For a release build:

```sh
xcodebuild -project Focus.xcodeproj -scheme Focus \
  -configuration Release -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData build
```

The app is at `build/DerivedData/Build/Products/Release/Focus.app`.

Alternatively, the included SwiftPM packaging script builds and ad-hoc signs the same native app:

```sh
./scripts/build-app.sh
open build/Focus.app
```

This script also requires full Xcode for SwiftData compilation. Xcode's **Product → Archive** provides the normal export route. Ad-hoc signing is for local use; distributing to other Macs without Gatekeeper warnings requires your own Developer ID signing and notarization. No remote repository or distribution service is configured.

## Using Focus

- Enter a task and a positive duration in minutes, then choose **Start focus**. Decimal minutes are supported, up to 1,440 minutes (24 hours).
- The green ring drains during the countdown. At the deadline the session stays active, the ring becomes full in muted red, and the display counts upward from **+00:00**.
- **Pause / Resume** excludes paused time from focus time, including during overtime. **Finish** saves a summary and the session's thoughts. Any unsubmitted thought is saved when finishing or quitting.
- Type in the thought field and press **Return** to save immediately. Newest thoughts appear first. **Copy** copies a single thought; **Copy all** includes the task, session date, and timestamped thoughts. Confirmation is shown briefly on the button.
- Use the sidebar toolbar button to collapse thoughts, then resize the window smaller. A compact thought field remains available under the timer.
- The pin toggle enables **Always on Top** using the native floating window level.
- **History** opens without interrupting the timer. Select a session to see its timestamps, durations, status, and saved thoughts.

Keyboard shortcuts: **⇧⌘P** pauses/resumes; **⇧⌘F** finishes; **⇧⌘H** opens history; **⇧⌘S** toggles the thought sidebar. Escape closes history.

## Closing, sleep, and recovery

There is one main window and one session controller. The app has no New Window command, and its bundle prohibits multiple instances.

Closing an active window asks whether to keep the session running. Confirming hides the window while timing continues. Click the Dock icon to return. Closing an idle window also leaves Focus available in the Dock. Quit explicitly with **⌘Q**.

Quitting during a session asks to save and quit. Focus pauses, saves, and recovers paused on next launch. If saving fails, quitting is cancelled and the error remains visible. Sleep also pauses the session; waking does **not** resume it automatically. Known paused time includes sleep, but active focus time does not.

Active records are checkpointed about every five seconds and on pause, resume, thought capture, finish, sleep, and quit. After a crash or force-quit, the latest checkpoint is recovered paused. Time since that checkpoint is marked **unobserved** and is excluded from both active and known paused time. You can resume or end the recovered session as interrupted. This conservative policy may lose work since the last successful checkpoint (normally up to five seconds; longer if the OS suspended the process or storage failed). It never assumes the unobserved period was productive work. Captured thoughts are saved when submitted.

History distinguishes completed and interrupted sessions. A recovered session that you resume and finish normally is completed. Its excluded time remains recorded. Start and end dates are wall-clock timestamps; measured active and paused intervals use a continuous monotonic clock, so manually adjusting the system clock does not change measured focus time.

## Persistence and privacy

SwiftData stores sessions and thoughts locally at:

```text
~/Library/Application Support/Focus/Focus.store
```

SQLite sidecar files may sit beside it. The app does not send data anywhere. Back up the entire Focus support directory while the app is closed. Never put the live store in Git. Stores, build products, Xcode user state, and common secrets are excluded by `.gitignore`.

Store-open and save failures are shown in the UI, with Retry where applicable. The app does not silently replace an unreadable store with a blank database. A failed final save blocks starting another session until the saved state is repaired.

## Architecture

- `Sources/FocusKit/TimerEngine.swift`: UI-independent state machine with an injectable clock. Elapsed time is derived from active and paused intervals, never from decrementing ticks. Overtime is derived from active duration. Finish is idempotent.
- `Sources/FocusKit/Models.swift`: SwiftData session and thought models with stable UUIDs, timestamps, and a cascading relationship. Overtime is computed, not redundantly stored.
- `Sources/FocusKit/SessionRepository.swift`: explicit SwiftData saves, fetches, relationship updates, and persistent-container creation.
- `Sources/Focus/App/SessionController.swift`: one observable controller connecting the timer, persistence, recovery, and UI refresh. The 250 ms refresh controls presentation only.
- `Sources/Focus/App/WindowConfiguration.swift`: AppKit floating level, close/reopen behavior, sleep handling, and quit protection.
- `Sources/Focus/Views/`: setup, timer ring, summary, thought capture, history, and session detail views. Native semantic colors support light/dark mode; the overtime transition respects Reduce Motion.
- `Sources/Focus/Utilities/Clipboard.swift`: system pasteboard copying and readable multi-thought formatting.

The Xcode app target compiles the source directly. The hostless test target compiles the core sources separately, so tests do not launch the app or touch your live history. SwiftPM exposes those same sources as `FocusKit`. Stable session IDs and start/end dates leave room for future calendar integration without adding calendar services to this version.

## Automated tests

In Xcode, choose **Product → Test (⌘U)** with the Focus scheme. Or:

```sh
xcodebuild -project Focus.xcodeproj -scheme Focus \
  -destination 'platform=macOS' -derivedDataPath build/DerivedData test
```

With full Xcode selected, `swift test` runs the same core and persistence tests. Persistence tests use temporary or in-memory stores and never your real data. The disk round-trip test destroys its writer scope and reopens the store in a fresh container.

For a machine with only recent Swift Command Line Tools, run the independent timer suite:

```sh
./scripts/test-engine.sh
```

The script selects engine-only sources, configures available Swift Testing libraries, and keeps caches and products under `.build/`. This does **not** exercise SwiftData or the app. It disables SwiftPM's nested sandbox for this local, dependency-free test build.

Coverage includes a 15-minute session, countdown and 100/50/0% progress, overtime at zero and beyond, pauses before and after zero, multiple resumes, active-versus-paused accounting, finishing early/late/paused, duplicate prevention, finish idempotency, input validation, eight-hour sessions, recovery, wall-clock changes, and time formatting. Persistence tests cover session/thought disk round-tripping, timestamps/relationships, newest-first thoughts, blank submissions, duplicate active records, and active checkpoints.

## Verification status and remaining checks

Implementation environment: macOS with Swift 6.3.3 Command Line Tools, no full Xcode.

- **Passed:** all 8 timer-engine tests.
- **Passed:** Xcode project and app plist syntax validation; shell-script syntax checks.
- **Passed with a limited scope:** SwiftUI/AppKit/controller type-check using temporary observable model and repository stand-ins, because the SwiftData macro plugin is absent. These stand-ins are not included in the project and are not an app implementation.
- **Blocked by tooling:** full app compilation, `.app` packaging, SwiftData integration tests, and actual UI testing. No working binary is claimed or supplied from this environment.

Before considering this release verified, build and run in full Xcode and check:

1. Start a `0.1`-minute session. It begins at `00:06`, reaches red `+00:00`, and keeps counting. Pause/resume before and after zero, then finish; confirm durations.
2. Submit thoughts with Return, including whitespace-only input and Unicode. Confirm immediate clearing, newest-first order, and no blank entry. Test Copy and Copy all by pasting into TextEdit.
3. Open history while timing. Verify it keeps running, then finish, quit, relaunch, and verify saved thoughts and complete details.
4. Force-quit an active session after at least one checkpoint. Relaunch and confirm paused recovery, preserved thoughts, and excluded downtime. Test both resume and “End as interrupted.”
5. Close the active window. Confirm Cancel leaves it open, Keep Running hides it, and Dock reopen preserves the same session. Quit and relaunch; confirm paused recovery.
6. Toggle Always on Top on/off while switching between ordinary app windows. Collapse the sidebar, resize, and check light/dark appearance and long task/thought text.
7. Sleep and wake the Mac during countdown and overtime. Confirm it stays paused on wake and requires manual resume.
8. On a disposable test store, simulate a write failure. Confirm errors remain visible, thought input survives a failed submission, final save can be retried, and quit does not discard unsaved state.

This MVP intentionally omits charts, sync, calendar integration, search, thought editing/deletion, break schedules, and global shortcuts. Thought capture is a single-line field; multiline Shift+Return is not implemented. Floating windows follow ordinary macOS Space/full-screen behavior. App Store sandboxing, distribution signing, and notarization are not configured.
