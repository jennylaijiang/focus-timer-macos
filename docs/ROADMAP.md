# Focus roadmap

Last reviewed: 21 October 2026. **v1.0 is released**, as reported by the user.

Focus helps you complete one task at a time without losing the thoughts that arise along the way. Keep the timer and thought capture central; this is not intended to become a full task manager.

Version numbers are provisional milestones with no committed dates; revisit priorities after each release. Begin a feature only when requested. Check an item when it is implemented and verified, linking its PR/commit and evidence in [verification notes](verification.md). Mark a milestone released only after completing the [release checklist](release-checklist.md).

Standing engineering rules live in [AGENTS.md](../AGENTS.md), and current user instructions in [README.md](../README.md). Add persisted fields only when implementing the feature that needs them.

## Release overview

| Milestone | Scope | Status |
| --- | --- | --- |
| v1.0 | Countdown, overtime, thought capture, history, optional floating window | Released |
| v1.1 | Session editing, reflections, deadline chime, elapsed thought timestamps | Next; planned |
| v1.2 | Optional local ambient audio / 白噪音 | Planned |
| v1.3 | Optional one-way Apple Calendar export | Planned |
| v1.4 | Time-estimation comparisons and simple study statistics | Planned |
| Unscheduled | Capture shortcut, menu-bar access, expanded history | Ideas |

## Confirmed starting point

Source inspection on 21 October 2026 confirms:

- Active-session and history editing are not implemented.
- Thoughts have clock timestamps; elapsed active time at capture is not yet stored or displayed.
- A finish summary already exists. Session reflections and deadline audio are not implemented.

This is a source inspection, not a new runtime verification. See [verification notes](verification.md) for actual test results and outstanding checks, including simulated save failures. Current persistence tests cover reopening the current schema, not migration from v1.0 to a future schema.

## v1.1 — Editing, reflection, and timing feedback

Implement in small, separately reviewable changes. Recommended order: migration groundwork → elapsed thought timestamps → task-name editing → reflection → target-duration editing → deadline chime. The last two are closely related: define revised-deadline behavior before adding sound.

### Data preservation groundwork

- [ ] Establish a repeatable migration test using a disposable on-disk store created with the released v1.0 schema and synthetic sessions/thoughts.
- [ ] Choose and document the migration strategy before changing models; prefer additive fields where suitable rather than unnecessary renames.
- [ ] Verify old records, stable IDs, relationships, durations, statuses, and active-session recovery after migration and a second reopen.
- [ ] Verify migration for each subsequent schema change and direct upgrades from released versions. An in-memory store alone cannot prove an on-disk upgrade works.

Never test against the live user database or replace an unreadable store with an empty one. Follow the [README backup instructions](../README.md#data-and-privacy). Review the temporary-store cleanup diagnostic recorded in [verification notes](verification.md) when extending persistence tests.

### Elapsed timestamps for thoughts

- [ ] Store nullable active elapsed time at submission, sampled from the authoritative timer together with the capture time.
- [ ] Display clock time first, then a subtle separator and timer icon with elapsed time; keep Copy aligned right in the existing metadata row, in both the sidebar and history.
- [ ] Use `mm:ss` below one hour and `h:mm:ss` from one hour onward.
- [ ] Test capture while running, paused, and in overtime, plus saving/reopening and thought capture through Finish.

Example: `17:56 · ◷ 21:33`. Elapsed time excludes pauses, continues through overtime, and stays fixed after capture. Old thoughts show only their clock time; do not infer missing active time from wall timestamps.

Suggested additive field: `activeElapsedAtCaptureSeconds: TimeInterval?`. Exact names should follow existing code.

### Task-name editing

- [ ] Allow renaming during running/paused sessions and correcting completed names in history.
- [ ] Preserve session identity, timestamps, accumulated time, and thoughts; reject blank names.
- [ ] Verify saved changes survive reopening and failed saves remain visible and retryable.

Before-start editing already exists. Keep timer state, repository data, and the displayed summary consistent when editing.

### Optional session reflection

- [ ] Add an optional session-level comment, separate from captured thoughts; old sessions have no comment.
- [ ] Extend the existing finish summary with an optional comment field and an obvious way to skip it.
- [ ] Support adding/editing the comment later in history.
- [ ] Show planned and actual active duration, plus overtime or time under target; distinguish original and revised targets when they differ.
- [ ] Test finishing without a comment, later edits, failed saves, and reopening.

Finish should stop timing immediately and save the completed session before requesting reflection. Preserve the existing unsubmitted-thought safeguard and make failed saves retryable. The current controller saves a pending thought before stopping the engine; implementing immediate stop therefore needs explicit failure-path handling, not just an extra text field. Do not claim a session is saved while its save is failing.

Suggested additive field: `sessionComment: String?`.

### Planned-duration editing

- [ ] Allow revising the target during a running or paused session, retaining the existing positive-duration/24-hour validation.
- [ ] Preserve the original estimate separately from the current/final target. For v1.0 records, the stored planned duration supplies the original estimate because target editing was unavailable.
- [ ] Recalculate countdown, overtime, and ring without resetting accumulated time, session identity, start time, or thoughts.
- [ ] Keep paused sessions paused after edits. Targets at/below elapsed active time show overtime; future targets restore countdown.
- [ ] Verify repeated revisions, save/reopen, recovery, and save failures. Do not silently edit completed timing records.

Example: at 20 active minutes on a 15-minute target, changing the target to 30 minutes changes `+05:00` to `10:00` remaining. The initial estimate remains 15 minutes.

Prefer retaining `plannedDurationSeconds` as the current/final target and adding an original-estimate field if that makes migration simpler. Future statistics compare actual time with the original estimate; overtime uses the current/final target.

### One-time deadline chime

- [ ] Add “Play sound when time is up,” initially enabled, with a short gentle chime following system volume.
- [ ] Play once when running active time crosses the applicable target, including while the app is in the background. Continue into overtime without interruption.
- [ ] Prevent duplicate playback on refresh, pause/resume, and recovery of an already-overtime session.
- [ ] Do not sound retroactively when an edit moves the target to/below elapsed time. A changed target in the future may arm one new alert; saving an unchanged target must not rearm it.
- [ ] Test disabled sound, repeated target edits, deadline crossings, recovery, and sleep/wake.

**Preserve sleep semantics:** sleep pauses active time and wake leaves the session paused. Passing the original wall-clock deadline while asleep does not cause a wake-time chime. After manual resume, sound when remaining active time actually expires. Keep deadline playback independent of future ambient audio.

### Release gate

- [ ] Complete the [release checklist](release-checklist.md), including evidence for the feature-specific checks above.

## v1.2 — Optional local ambient audio / 白噪音

Start with local file import, not an extensive bundled sound library. The preferred mood is natural forest rain and thunder. The supplied Bilibili recording (`BV1d3411t7dV`) is a listening reference only, not an asset to extract or redistribute without permission.

- [ ] Provide compact controls for enabling audio, play/pause, source selection, looping, and independent volume. Default off.
- [ ] Import a user-authorized local audio file in a format supported by native playback; no streaming is required.
- [ ] Choose an import/storage strategy that preserves access after relaunch, avoids unnecessary copies, and handles missing/moved/deleted files gracefully.
- [ ] Remember sound selection and volume; aim for near-seamless looping and verify supported formats.
- [ ] Continue through overtime, pause with the session initially, and stop on Finish. Keep ambient audio paused after sleep/recovery until the user resumes.
- [ ] Allow the deadline chime without stopping ambient playback; keep playback controls independent.
- [ ] Test import, looping, volume, relaunch, unavailable files, and timer transitions; document and release.

Focus must remain fully usable without a sound configured. Keep imported files out of Git. Configurable pause behavior may follow later.

## v1.3 — Optional Apple Calendar export

Use EventKit for one-way creation of events from completed sessions. Local history stays authoritative. No proprietary server, two-way sync, calendar import, or conflict-resolution system is planned.

- [ ] Provide “Save completed sessions to Calendar,” default off, with permission requested only when enabled and target-calendar selection where supported.
- [ ] Define the required permission scope and event lookup/retry strategy before implementation.
- [ ] Create an event titled `Focus: <task name>` spanning actual session start/end wall times. Include original/final planned duration, active time, paused time, overtime, and separately recorded unobserved time where relevant.
- [ ] Decide when export occurs relative to optional reflection, whether comments are included, and how later name/comment edits affect an existing event.
- [ ] Persist export status and event identity; handle retry and the case where Calendar saves successfully but Focus cannot save the identifier. An identifier alone does not resolve that duplicate risk.
- [ ] Define behavior for events deleted outside Focus and for interrupted sessions; avoid silently recreating intentionally deleted events.
- [ ] Keep local saving independent of permission denial, unavailable calendars, or export failure; provide clear status and deliberate retry.
- [ ] Verify opt-in, permission changes, creation, failures, duplicate prevention, relaunch, and externally deleted events; document and release.

Calendar wall time may include pauses and unobserved gaps; do not label the entire event as active focus time. Explain that the selected calendar may sync through iCloud or another configured provider. This is an explicit optional extension to the current local-only behavior.

## v1.4 — Simple statistics and estimation insights

- [ ] Compare original estimate, revised target, and actual active duration per session. Derive estimate difference as `actual − original` and estimate ratio as `actual / original`.
- [ ] Start with daily/weekly active focus totals, session counts, and a simple planned-versus-actual comparison.
- [ ] Define treatment of interrupted sessions, sessions spanning midnight, missing values, and date ranges before aggregating.
- [ ] Explore thought counts and timing over active session time; omit unavailable legacy elapsed values from timing distributions rather than inventing them.
- [ ] Verify calculations on synthetic records with pauses, overtime, target revisions, interruptions, and legacy data; document and release.

Keep the presentation descriptive and small. Overtime is not failure, a captured thought is not necessarily a distraction, and Finish does not prove the task itself was completed. No AI classification or large analytics dashboard is needed.

## Unscheduled ideas

- [ ] In-app shortcut to focus thought input, revealing the sidebar if needed. Consider global capture and restoring the prior working context only as a later extension.
- [ ] Compact menu-bar access to the current timer.
- [ ] History search and date filters.
- [ ] Export sessions, thoughts, and comments.
- [ ] Optional task categorization.
- [ ] Small bundled ambient library with suitable distribution rights.

These are candidates, not release commitments. Prioritize changes that reduce capture friction or make existing records more useful.

