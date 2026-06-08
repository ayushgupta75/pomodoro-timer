# Pomodoro Timer

A clean, distraction-free Pomodoro timer for iOS built with SwiftUI and Swift 6.

## Features

- **Seamless sessions** — timer auto-advances from work → short break → long break with no interaction needed
- **Daily goal tracking** — set a target number of sessions, track progress with a live bar on the main screen. Timer stops automatically when goal is reached
- **Session counter** — dots fill as you complete work+break pairs within a cycle
- **Ambient sound** — choose brown noise, pink noise, or white noise to play during work sessions, generated on-device via AVAudioEngine
- **Countdown sounds** — soft tock at 7 seconds, sharp beep at 3 seconds, chime on completion
- **Skip button** — jump to the next session instantly at any point
- **Notifications** — local alerts when sessions end, even when app is backgrounded
- **Stats tab** — today's sessions, all-time count, cycle progress, daily goal progress bar with session log
- **Fully customizable** — work duration, short/long break durations, sessions per cycle, daily goal, ambient sound type
- **Reset all data** — one-tap wipe of all session history and settings
- **Bug reporting** — files GitHub issues directly from the app with device info attached automatically

## Architecture

Follows **MVVM** with strict separation of concerns:

```
pomodoro timer/
├── App/
│   └── pomodoro_timerApp.swift
├── Models/
│   └── PomodoroModels.swift        # SessionType, TimerState, PomodoroSettings, SessionRecord
├── ViewModels/
│   └── PomodoroViewModel.swift     # Timer logic, state machine, persistence
├── Views/
│   ├── ContentView.swift           # TabView root
│   ├── TimerView.swift             # Main timer screen
│   ├── StatsView.swift             # Session history and daily goal
│   ├── SettingsView.swift          # All user preferences
│   ├── BugReportView.swift         # GitHub issue reporter
│   └── AboutView.swift             # App info
└── Services/
    ├── NotificationService.swift   # UNUserNotificationCenter wrapper
    ├── SoundService.swift          # AudioToolbox countdown sounds
    ├── AmbientSoundService.swift   # AVAudioEngine noise generator
    └── GitHubService.swift         # GitHub Issues API client
```

## Tech Stack

- **Swift 6** with `@MainActor` default isolation
- **SwiftUI** — no UIKit, no Storyboards
- **`@Observable`** macro for reactive ViewModels (iOS 17+)
- **`async/await` + `Task`** for the timer loop — no `Timer.scheduledTimer`
- **`AVAudioEngine`** for procedurally generated ambient noise
- **`AudioToolbox`** for system countdown sounds
- **`UNUserNotificationCenter`** for local notifications
- **`UserDefaults`** for settings and session log persistence
- **GitHub REST API** for in-app bug reporting

## Session Model

A **session** = 1 work period + 1 break period (the pair).

```
Work → Short Break   ← session 1 complete
Work → Short Break   ← session 2 complete
Work → Short Break   ← session 3 complete
Work → Long Break    ← session 4 complete (cycle resets)
Work → Short Break   ← session 5 complete
...
```

- **Sessions per cycle** — how many sessions before a long break triggers
- **Daily goal** — total sessions to complete today; timer stops automatically when reached

## Setup

1. Clone the repo
2. Create `pomodoro timer/Config.swift` (gitignored):
```swift
enum Config {
    static let githubToken = "your_github_pat_here"
    static let githubRepo  = "your_username/pomodoro-timer"
}
```
3. Open `pomodoro timer.xcodeproj` in Xcode
4. Run on simulator or device (iOS 17+)

> The GitHub token requires **Issues: Read & Write** on the target repository. Use a classic PAT with `repo` scope or a fine-grained PAT scoped to the repository.

## Requirements

- iOS 17+
- Xcode 15+
