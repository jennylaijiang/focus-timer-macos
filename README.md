# Focus

An small, offline count-down timer with thoughts dumping space for personal use. Help you focusing on one thing at a time.

## Requirements

- macOS 14 or later.
- Full Xcode 16 or later to build the app and run the complete test suite.
- No third-party packages, accounts, or API keys.

## Build and run

1. Open `Focus.xcodeproj` in Xcode.
2. Select the **Focus** scheme and **My Mac** destination.
3. Press **⌘R** to build and run. Local builds use ad-hoc signing; no development team is required.

For command-line builds, select full Xcode under **Xcode → Settings → Locations → Command Line Tools**. Apple Command Line Tools alone may lack the SwiftData compiler plugin.

To build a standalone app from Terminal:

```sh
./scripts/build-app.sh
open build/Focus.app
```

You can copy `build/Focus.app` to Applications. Alternatively, build a release with Xcode:

```sh
xcodebuild -project Focus.xcodeproj -scheme Focus \
  -configuration Release -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData build
```

The Xcode build is at `build/DerivedData/Build/Products/Release/Focus.app`. Distribution to other Macs without Gatekeeper warnings requires Developer ID signing and notarization; these are not configured.

## Using Focus

- Enter a task and a duration in minutes, then choose **Start focus**. Decimal minutes are supported, up to 1,440 minutes (24 hours).
- When the countdown ends, the ring turns red and the timer counts upward from **+00:00** until you finish.
- **Pause / Resume** excludes paused time. **Finish** saves the session and its thoughts, including any unsubmitted thought.
- Type a thought and press **Return** to save it. Use **Copy** or **Copy all** to copy saved thoughts.
- Collapse the thought sidebar for a smaller window, or use the pin toggle for **Always on Top**.
- Open **History** to review saved sessions without interrupting the timer.

Keyboard shortcuts: **⇧⌘P** pauses/resumes; **⇧⌘F** finishes; **⇧⌘H** opens history; **⇧⌘S** toggles the thought sidebar. Escape closes history.

## Closing, sleep, and recovery

Closing an active window asks whether to keep the timer running. Click the Dock icon to return; use **⌘Q** to quit.

Quitting saves and pauses the session. Sleep also pauses it; waking or reopening the app does not resume it automatically. If saving fails during quit, the app stays open and shows an error.

After a crash or force-quit, Focus recovers the latest saved state, paused. Time since the last save is excluded, so a small amount of recent focus time may be lost. You can resume the session or end it as interrupted.

## Data and privacy

Sessions and thoughts stay on your Mac. The app does not send data anywhere. The database is stored at:

```text
~/Library/Application Support/Focus/Focus.store
```

To back it up, quit Focus and copy the entire `Focus` support folder, including any database sidecar files. Session databases, build products, and Xcode user state are excluded by `.gitignore`.

## Tests

In Xcode, choose **Product → Test (⌘U)** with the Focus scheme, or run:

```sh
xcodebuild -project Focus.xcodeproj -scheme Focus \
  -destination 'platform=macOS' -derivedDataPath build/DerivedData test
```

With full Xcode selected, `swift test` also runs the core and persistence tests. Tests use temporary or in-memory stores, not your saved sessions.

With only recent Swift Command Line Tools, use `./scripts/test-engine.sh` for the timer-only tests; this does not test SwiftData or the app.

See [development verification](docs/verification.md) for historical test results and the manual release checklist.
