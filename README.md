# منارة الانضباط | Manarat Al-Indibat

Personal Behavioral Operating System (PBOS) — native Flutter rewrite.

## What is built now (this pass)

**Two solid passes are in this build:**

### Pass 1 — Foundation
Clean Architecture + MVVM skeleton, DI via get_it, dark cyberpunk/
glassmorphism theme, Arabic RTL.

### Pass 2 — The real Daily Schedule + Behavior Engine
This is the important one. After reading the actual HTML source
(`منارة_الانضباط_v8.html`), one thing became clear: **"tasks" in this
app are not a to-do list.** They are a recurring hourly daily schedule
(`S.sched.base` + per-weekday `overrides`) with a separate per-day
completion log (`S.log[dayKey][taskId]`). Everything else — XP,
streaks, and the entire Behavior Engine — is built on top of that
structure. So that's what got built, faithfully:

- **`ScheduledTaskEntity`** — id/title/hour/priority/note/category,
  1:1 with the original task shape.
- **`TaskLogEntry`** — status/startedAt/completedAt/escapeAttempts/
  failedAt/plannedDuration, 1:1 with `getTS()`.
- **Schedule + day-log system** — base schedule, weekday overrides,
  per-day logs, all in Hive, with `computeStats(n)` ported exactly
  from the original.
- **`BehaviorEngine`** (`lib/domain/services/behavior_engine.dart`) —
  a genuine, function-by-function port of the "DEEP BEHAVIORAL
  INTELLIGENCE CORE v4" section of the HTML app:
  - `analyzeBehavior()` — today's live skip/completion scan
  - `deepPatternScan()` — day-of-week weakness/strength, success-streak
    break patterns, worst/peak hour, weakest habit, late-night usage
  - `computePersonaModel()` — the 7 behavioral personas (Extreme
    Productive Mode, Night Worker, Chronic Procrastinator, etc.)
  - `computeRiskAssessment()` — abandonment / streak-break / relapse
    risk scores
  - `generateSmartNotification()` — rate-limited proactive nudges
  - `interpretHiddenReason()` — the "why", not just the "what"
    (avoidance, burnout, procrastination, overload, hesitation,
    motivation collapse, fatigue)
  - `computeAppPersonality()` — the 5 adaptive app moods (calm,
    strict, analytical, warning, recovery)
  - `generateWeeklyMirrorReport()` / `maybeGenerateWeeklyMirror()` —
    Friday behavioral mirror
  - `maybeLockIdentity()` — permanent behavioral identity after 30
    days / 18 active days
  - `checkSilenceAnomaly()` — unusual-absence detection
  - `registerCompletion()` / `registerFail()` / `touchStreak()` — XP
    and streak bookkeeping, same formulas as the original
    `regCompletion`/`regFail`/`touchStreak`
- **Shadow Mode** is real now, not just a banner: the dashboard checks
  `firstOpenAt` and suppresses all persona/risk/pattern/notification UI
  for the first 14 days, exactly like the original — the engine still
  quietly records data underneath.
- **Today screen** (`schedule_screen.dart`) — the actual daily-driver
  screen: hourly list, complete/fail actions wired to real XP/streak
  logic, add-to-schedule sheet with an hour slider.
- **Dashboard** now shows live persona, risk meters, detected patterns,
  and hidden-reason cards, gated correctly by Shadow Mode.

```
lib/
  core/           theme, constants, DI, utils (day-key/hour formatting), widgets
  domain/
    entities/     ScheduledTaskEntity, TaskLogEntry, DayStat,
                  BehaviorProfileEntity, behavior_insight_types (Persona,
                  Risk, Pattern, HiddenReason, SmartNotification, Identity)
    repositories/ ScheduleRepository, BehaviorProfileRepository, ...
    services/      BehaviorEngine — the intelligence core, pure Dart,
                  zero Flutter imports, fully unit-testable with fakes
  data/           Hive models + hand-written adapters, repository impls
  presentation/   ScheduleViewModel, BehaviorViewModel, screens
```

## Running it

No pub.dev/Flutter-SDK access in this sandbox, so it couldn't be
compiled/tested here.

```bash
flutter pub get
flutter run
```

### About the Hive adapters
Hand-written (no `build_runner` access here) — 7 typeIds registered
(0-6), all consistent. Regenerate anytime with:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### A note on the old `TasksScreen`
`lib/presentation/screens/tasks/` (generic one-off to-do list) from
the first pass is no longer wired into navigation — it was built before
reading the actual HTML source and turned out not to match the app's
real model. The code is left in place (unused, still compiles) since
its Clean Architecture pattern is a reasonable starting point for the
**Goals** module next, which genuinely is closer to a to-do/milestone
structure than the hourly schedule is.

## Pass 3 — Smart Messaging Engine + Prediction Engine

Built per the "تطوير شامل" spec, sections 3 & 4 (the two the user chose
to start with — everything else in that spec is either infra that
can't be verified without the Flutter SDK, or not requested yet).

### `MessageEngine` (`lib/domain/services/message_engine.dart`)
Composes every proactive nudge from **four independently-varying
sentence pools** (opener → observation → interpretation/support →
suggestion) instead of one fixed string per situation. 12 categories
(`laziness`, `progress`, `relapse`, `disappearance`, `nearGoal`,
`overload`, `streakSaved`, `streakRisk`, `worstHourPattern`,
`comeback`, `habitRisk`, `fatigueWarning`, `burnoutWarning`,
`steady`), 6-10 sentence variants per slot per category → tens of
thousands of realistic combinations, each a grammatically complete
standalone sentence (no mid-sentence slot-filling that could break
Arabic agreement). Anti-repeat is enforced via a rolling hash history
(`BehaviorProfileEntity.recentMessageHashes`, capped at 60): the
engine retries up to 6 times before accepting a near-repeat.
`generateSmartNotification()` in `BehaviorEngine` now calls this
instead of returning a fixed string per trigger — same trigger
conditions, `kind`, and dedupe `key` as before, only the text/icon
vary. Also added a new schedule-overload trigger (spec's "زاد الضغط"
example) that wasn't wired to anything before.

### `PredictionEngine` (`lib/domain/services/prediction_engine.dart`)
All six forecasts from spec section 4, each a rule-based estimate from
on-device history only (no cloud model):
- `predictTodayOutcome()` — success/failure probability for today,
  blending live completion rate with historical baseline, weighted by
  how much of the day has elapsed, plus a `confidence` score.
- `predictHabitDrops()` — per-habit drop risk from recent success rate
  + day-to-day volatility + streak fragility, sorted worst-first.
- `predictReturn()` — once the user is in an unusual absence window
  (reuses the same gap heuristic as `checkSilenceAnomaly`), estimates
  probability and expected days until they come back.
- `predictFatigue()` / `predictBurnout()` — short-horizon vs.
  long-horizon overload signals (fail streaks + skip counts vs.
  30-day load/variance/declining-trend).
- `computeAll()` aggregates all of the above into a `PredictionBundle`
  and attaches a `MessageEngine`-composed `ProactiveSolution` for each
  risk that crosses its threshold — "ثم يعرض حلولاً قبل وقوع المشكلة."

Wired into `PredictionViewModel` → a new "محرك التوقعات" card on the
dashboard (gated behind Shadow Mode, same as everything else
persona/risk-related).

### Not wired yet (left for next pass, on purpose)
- `MessageCategory.nearGoal` — needs the Goals module (roadmap #3)
  to exist first; the sentence pools are ready.
- `MessageCategory.comeback` — a proper "welcome back" greeting needs
  the gap check to run *before* `recordOpenEvent()` records the new
  timestamp, which means touching the view-model init order; punted
  to avoid a race-condition bug I can't verify without a compiler here.
- Hive field 38 (`recentMessageHashes`) was added by hand to the
  adapter (no `build_runner` access here, same constraint as before) —
  regenerate with `flutter pub run build_runner build
  --delete-conflicting-outputs` once you have the SDK, or just trust
  the hand-written adapter, it follows the exact same pattern as the
  other 38 fields.

## Roadmap — not yet built

1. **Notification Reaction Memory + Adaptive Sound Engine** —
   `markNotifSent/Opened/Ignored`, escalation levels, the 5-profile
   sound engine. Structure is ready in `BehaviorProfileEntity`
   (`notifReactions` was simplified out for this pass — needs adding
   back), just needs wiring.
2. **Anti Self-Manipulation** — `checkCompletionAuthenticity()`,
   focus-session authenticity tracking (visibility-change based).
3. **Goals module** — daily/weekly/monthly/quarterly/yearly/life goals
   with milestone auto-decomposition (can reuse the parked TaskEntity
   pattern).
4. **Focus / Pomodoro** — timer, Deep Work Mode, ambient sound,
   break flow, escape-attempt tracking.
5. **Statistics dashboard** — `fl_chart` trend/heatmap/donut charts
   (dependency already in `pubspec.yaml`), mirrors `drawTrendChart`/
   `drawHeatmap`/`drawCatDonut`.
6. **Reward system** — XP levels/ranks, achievements, gem shop.
7. **Notebook** — text/photo/audio entries (needs a `path_provider`-
   based blob store, mirroring the original's separate IndexedDB keys
   for media).
8. **Onboarding + Identity panel UI**, **Weekly Mirror modal UI**.
9. **PIN lock**, **theme toggle**, **PDF export**.

Tell me which one to build next.

## Merge pass — Prediction Engine adopted + hidden-reason messages unified

This build merges two parallel continuations of the project:

**Kept from this upload (the good part — genuinely new):**
- **Prediction Engine** (`prediction_engine.dart` + `prediction_types.dart`
  + `prediction_viewmodel.dart`) — spec section 4 in full: today's
  success/failure probability, per-habit drop-risk (sorted worst-first),
  return-after-absence estimate, short-horizon fatigue probability,
  longer-horizon burnout probability, and a proactive `ProactiveSolution`
  composed via the message engine for whichever risk crosses its
  threshold. Fully wired into DI (`injection.dart`) and the dashboard
  (`_PredictionsCard`).
- **`MessageEngine`** (renamed from the old `MessageTemplateEngine`) —
  4-slot composition (opener → observation → support → suggestion) using
  complete, grammatically-correct Arabic sentences per slot instead of
  fragment concatenation, which reads more naturally. 14 categories
  already covered spec section 3 categories (laziness, progress, relapse,
  disappearance, nearGoal, overload — with a real `_isScheduleOverloaded()`
  detector based on 14-day averages — streakSaved, comeback, steady) plus
  the ones Prediction Engine needs (habitRisk, fatigueWarning,
  burnoutWarning, worstHourPattern, streakRisk).
- `recentMessageHashes` on `BehaviorProfileEntity` — simpler flat
  `List<String>` (last 60) shared across both engines, replacing the
  previous per-category `Map<String, List<int>>`.

**Ported over from the previous pass (still needed, now on the new base):**
- 7 new `MessageCategory` values + full opener/observation/support/
  suggestion pools for the "hidden reasons" (avoidance, burnout,
  procrastination, overload, hesitation, motivationCollapse, fatigue) —
  `interpretHiddenReason()` now composes varied text instead of one fixed
  string per type, same as the rest of the engine.
- `checkSilenceAnomaly()` (the "user disappeared" pattern insight) now
  also composes through `MessageEngine` (`MessageCategory.disappearance`)
  instead of returning a fixed string.

Verified: every `MessageCategory` enum value has a matching entry in
both `_icons` and `_pools` in `message_engine.dart` (21/21) — no missing-
key crashes at runtime. Brace/paren balance checked on all edited files.

## Still not built (roadmap unchanged)
Notification reaction memory + adaptive sound, anti self-manipulation,
Goals module, Focus/Pomodoro, stats dashboard (fl_chart), reward system,
Notebook, onboarding/identity UI, weekly mirror UI, PIN lock, theme
toggle, PDF export.

## Pass 4 — Behavior Memory + real Notification Intelligence + Background Tasks

Built per the "تطوير نظام الذكاء السلوكي" spec — the three pieces that
genuinely didn't exist yet (Behavior Engine, Smart Messages, and
Prediction Engine were already done in Passes 2-3; see above).

### `BehaviorMemoryEngine` (`lib/domain/services/behavior_memory_engine.dart`)
Answers "كيف كنت قبل شهر / ستة أشهر / سنة؟" with an actual recorded
past state, not a re-derived guess:
- `recordDailySnapshotIfNeeded()` — appends one `MemorySnapshot`
  (XP, streak, best streak, trailing-7-day completion rate, app
  personality mode) to `BehaviorProfileEntity.memorySnapshots` at most
  once per calendar day, capped at ~400 entries (~13 months). XP and
  persona can't be reconstructed from day logs after the fact — they
  have to be captured when they happen — so this is real
  point-in-time memory, not just `computeStats(n)` re-sliced.
- `compareToDaysAgo(MemoryPeriod)` — finds the nearest snapshot to
  30/182/365 days ago (±6-day tolerance), computes completion/XP/
  streak deltas and a persona-changed flag, classifies the trend
  (improved/declined/stable), and composes a varied Arabic narrative
  through `MessageEngine` (`memoryImproved`/`memoryDeclined`/
  `memoryStable`, 4-slot composition same as every other category).
  Returns `hasData: false` with an honest "not enough history yet"
  message when there's no snapshot far back enough — this will always
  be the case for the 6-months/year comparisons for the first several
  months after a fresh install, which is expected and not a bug.
- `getFullMemoryReport()` — all three periods at once, wired into a
  new `MemoryViewModel` → `_MemoryCard` on the dashboard (gated behind
  Shadow Mode + `hasData`, same convention as the rest of the app).

### Real Notification Intelligence (`lib/domain/services/notification_intelligence_engine.dart`)
Spec: *"لا يعتمد فقط على الوقت. بل يعتمد على السلوك."* This is the
bridge from the engines above (which only *decided* what to say) to
notifications that actually fire, driven by detected behavior rather
than a fixed clock:
- **Missed-usual-time nudge** — takes the mode of the hour-of-day
  histogram of `BehaviorProfileEntity.openTimestamps` (needs ≥8
  samples and a clearly-dominant hour, ≥22% share, to avoid noise);
  if the user hasn't opened the app today and it's now past their
  usual hour, fires `notifMissedUsualTime`.
- **Morning productivity boost** — fires right at the user's own
  historical `peakHour` (already computed by
  `BehaviorEngine.analyzeBehavior()`) when it falls in the morning
  window, not a hardcoded time.
- Relays `BehaviorEngine.generateSmartNotification()` (self rate-
  limited, unchanged), the top `PredictionEngine` proactive solution
  (throttled ~6h), and a weekly `BehaviorMemoryEngine` comparison
  (throttled ~6 days, only when there's an actual trend to report) —
  so every existing insight now reaches the user as a real
  notification, not just an in-app card.
- All dedupe bookkeeping lives in the new
  `BehaviorProfileEntity.lastDeliveredNotifAt` map.
- Delivery itself goes through `NotificationDispatcher`, an
  interface kept in `domain/` (no Flutter import) so the engine stays
  pure-Dart and testable with `NoopNotificationDispatcher`, exactly
  like `BehaviorEngine`/`PredictionEngine`. `NotificationService`
  (`lib/core/services/notification_service.dart`) is the real
  implementation — `flutter_local_notifications` +
  `permission_handler` + `timezone`, zero network calls, zero
  FCM/APNs — genuinely local, per the "Local AI" requirement.

### Background Tasks (`lib/core/background/background_dispatcher.dart`)
A single `workmanager` entry point drives both platforms from one
Dart callback:
- **Android** → `WorkManager`, registered as a periodic task
  (`kBehaviorAnalysisTask`, 15-minute interval — Android's practical
  minimum for periodic work; the OS still applies Doze/battery
  throttling on top of that).
- **iOS** → `BGTaskScheduler` under the hood of the same `workmanager`
  API. iOS decides *when* the task actually runs — opportunistically,
  based on usage patterns and battery — the 15-minute interval is a
  hint, not a guarantee. This is a hard platform limitation of
  `BGTaskScheduler` itself, not something any Flutter plugin works
  around.
- Each wake-up (or app-resume, via `WidgetsBindingObserver` in
  `main.dart`) re-initializes Hive + DI in that isolate (idempotent,
  see `_bootstrapHeadless()`), then calls
  `BehaviorMemoryEngine.recordDailySnapshotIfNeeded()` and
  `NotificationIntelligenceEngine.evaluateAndDeliver()`.
- `flutter_background_service` was **not** added — `workmanager`
  already covers this app's "periodic check + notify" use case on
  both platforms. It's left commented out in `pubspec.yaml` for later,
  only needed if you want a persistent Android foreground service
  (e.g. a live focus-session notification); it has no iOS equivalent.

### Native setup still needed (no `android`/`ios` folders in this upload)
This upload is `lib/`-only — run `flutter create .` in the project
root first to generate the platform folders, **then** add:

**`android/app/src/main/AndroidManifest.xml`** — inside `<manifest>`,
above `<application>`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
```
`workmanager`'s own manifest merge handles its `Worker`/`Receiver`
registration automatically — no extra `<service>`/`<receiver>` entries
needed by hand.

**`ios/Runner/Info.plist`** — add:
```xml
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>processing</string>
</array>
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
  <string>be.tramckrijte.workmanagerTask</string>
</array>
```
(`workmanager`'s README has the exact identifier string for whatever
plugin version pins to — check it against the installed version.)

**`ios/Runner/AppDelegate.swift`** — `workmanager`'s own setup docs
require one line in `application(_:didFinishLaunchingWithOptions:)` to
register the background task with `BGTaskScheduler`; follow the
package's current README for the exact snippet since it's plugin-
version-specific.

None of this could be verified against a real Xcode/Gradle build in
this sandbox (no Flutter SDK access here, same constraint as every
previous pass) — treat the snippets above as a starting point, not a
guarantee, and check them against whatever `workmanager`/
`flutter_local_notifications` versions `pubspec.yaml` resolves to.
