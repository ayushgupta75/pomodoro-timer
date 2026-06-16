# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Stack
- Swift 6, iOS 17+, SwiftUI only (no UIKit, no Storyboards)
- `@Observable` macro for ViewModels (not `ObservableObject`)
- Async/Await for all async work — no callbacks or completion handlers
- Backend: FastAPI + PostgreSQL (optional sync feature, not wired to UI yet)

## Build & Run

**iOS App**: Open `pomodoro timer.xcodeproj` in Xcode, run on simulator or device (iOS 17+).

**Build via CLI** (simulator):
```bash
xcodebuild -project "pomodoro timer.xcodeproj" \
  -scheme "pomodoro timer" \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -configuration Debug build
```

**Install + launch on booted simulator**:
```bash
xcrun simctl install booted /path/to/DerivedData/.../pomodoro\ timer.app
xcrun simctl launch booted com.stackforge.pomodoro-timer
```

**Backend (local dev)**:
```bash
cd backend
docker-compose up           # starts API (port 8000), postgres, nginx (port 80)
```

**Backend tests**:
```bash
cd backend && pytest tests/
pytest tests/test_sessions.py   # single file
```

**DB migrations**:
```bash
cd backend
alembic upgrade head
alembic revision --autogenerate -m "description"
```

## Setup Requirements

Create `pomodoro timer/Config.swift` (gitignored — required for the bug report feature):
```swift
enum Config {
    static let githubToken = "your_github_pat_here"  // Issues: Read & Write
    static let githubRepo  = "your_username/pomodoro-timer"
}
```

Copy `backend/.env.example` → `backend/.env` and fill in values before running the backend.

## Architecture: MVVM

**Model** (`Models/PomodoroModels.swift`): Plain structs/enums. `SessionRecord` has a custom `Decodable` init for backward-compatible decoding — old records missing `startedAt` or `durationSeconds` fall back to derived values.

**ViewModel** (`ViewModels/PomodoroViewModel.swift`): Single source of truth. Owns the `Task`-based timer loop, `SessionRecord` persistence to `UserDefaults`, Live Activity lifecycle, and ambient sound. The timer loop uses `Task.sleep` — never `Timer.scheduledTimer`.

**Views** (`Views/`): Purely declarative, no logic. `ContentView` is a `TabView` root with Timer / Stats / Settings tabs. `StatsView` links to `MonthlyStatsView`.

**Services** (`Services/`):
- `NotificationService` — `UNUserNotificationCenter` wrapper
- `SoundService` — `AudioToolbox` countdown sounds (tock at 7s, beep at 3s, chime on completion)
- `AmbientSoundService` — `AVAudioEngine` procedurally generates noise; 30-second buffer looped
- `APIClient` — bare `URLSession` REST client; snake_case ↔ camelCase via encoder/decoder strategies; `baseURL` hardcoded to `http://localhost`
- `SyncService` — network monitor + `APIClient`; opt-in, not wired to UI
- `GitHubService` — GitHub Issues REST API for in-app bug reporting

## Multi-Target Structure

| Target | Purpose |
|---|---|
| `pomodoro timer` | Main iOS app |
| `PomodoroWidget` | WidgetKit + Live Activity extension |
| `PomodoroWidgetExtension` | Separate entitlements for the widget |

**SharedTypes** is a local Swift Package (`SharedTypes/Package.swift`) defining `PomodoroActivityAttributes` — the Live Activity payload shared between app and widget. Anything crossing the app/extension boundary must live here.

**App Group**: `group.com.stackforge.pomodoro-timer` — shared `UserDefaults` between app and widget (key: `liveActivityLastToggle` for lock-screen toggle sync).

## Session & Timer Model

A **session** = 1 work period + 1 break period (the pair). `SessionRecord` is written only when a **break ends** (completing the pair).

```
Work → Short Break   ← session 1 complete
...
Work → Long Break    ← session N complete (cycle resets, N = sessionsPerCycle)
```

Key fields in `PomodoroViewModel`:
- `workSessionRunningSeconds` — accumulates actual elapsed seconds during a work period only (not wall clock). Saved as `SessionRecord.durationSeconds` when the break ends.
- `workSessionStartedAt` — stamped when `start()` is called for a fresh work period.
- `SessionRecord.completedAt` — wall-clock time the **break** ended (not work ended). Used for calendar grouping. `startedAt + durationSeconds` gives the actual work end time.
- `sessionsPerCycle` — controls when a long break triggers (`workPeriodsCompleted % sessionsPerCycle == 0`).
- Timer auto-stops when `dailyGoalReached` (`todaysTotalSeconds >= dailyGoalHours * 3600`).

## Background / Foreground Handling

When backgrounded, the `Task`-based timer is cancelled. On foreground, `handleForeground()` reconciles elapsed wall time against `sessionEndDate`:
- If session expired while backgrounded and it was a work session, `remainingSeconds` is added to `workSessionRunningSeconds` before calling `advanceSession()` — this ensures background time is correctly credited.
- If still time remaining, restarts the task with corrected `remainingSeconds`.

## State Management

| Tool | When to use |
|---|---|
| `@State` | Local, ephemeral view state only |
| `@Observable` / `@StateObject` | ViewModel owned by a view |
| `@Environment` / `@EnvironmentObject` | Shared state down the tree |
| `@AppStorage` | Simple settings persistence via UserDefaults |

## UserDefaults Keys

| Key | Content |
|---|---|
| `pomodoroSettings` | JSON-encoded `PomodoroSettings` |
| `sessionLog` | JSON-encoded `[SessionRecord]` |
| `liveActivityLastToggle` | `Date` — App Group, written by widget |

## Code Standards
- No force unwraps (`!`) — use `guard`, `if let`, or defaults
- No singletons except platform-mandated (`UNUserNotificationCenter`)
- No logic inside Views
- Timer states modeled as `enum TimerState` (idle, running, paused) — not booleans
- Dependency injection: ViewModels injected into Views, never created inside them
- All types `PascalCase`, all vars/functions `camelCase`
- Private internals always marked `private`
- Extensions grouped by protocol conformance

## Collaboration Rules
- When unsure about any design decision (UI, UX, feature scope, data model), ask the user before implementing
- Document every design decision made in the "Design Decisions" section below

## Design Decisions
- **Visual style**: Minimal & Clean — white background, large thin rounded timer font, blue accent, gray secondary elements
- **Timer ring**: Circular progress ring, blue stroke, `lineCap: .round`, animates with `.linear(duration: 1)`
- **Session dots**: Small circles below session label, filled blue for completed sessions in current cycle
- **Controls**: Reset (gray circle, left), Play/Pause (blue filled circle, center), Skip (right)
- **Settings**: Scrollable form with collapsible `WheelPickerRow` components; changes auto-saved via `.onChange(of: viewModel.settings)`
- **Notifications**: Requested on launch; fired when a session ends
- **Session definition**: `SessionRecord` is appended when the **work period ends** (not at break end), so stats update immediately after work finishes
- **Daily goal unit**: Hours of focus time; measured by summing `durationSeconds` of today's `SessionRecord`s
- **Ambient noise**: Generated on-device via `AVAudioEngine` — no audio files bundled
- **Session time display**: Recent sessions show `startedAt – (startedAt + durationSeconds)` (work period only, not including break)

## What We Never Do
- No UIKit
- No Storyboards
- No singletons (except platform-mandated)
- No logic in Views
- No force unwraps
- No callbacks (use async/await)
