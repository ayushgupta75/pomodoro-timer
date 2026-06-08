# Pomodoro Timer — iOS Project Standards

## Stack
- Swift 5.9+, iOS 17+, SwiftUI only (no UIKit, no Storyboards)
- `@Observable` macro for ViewModels (not the older `ObservableObject`)
- Async/Await for all async work — no callbacks or completion handlers

## Architecture: MVVM
- **Model**: plain `struct` / `enum`, zero UI knowledge, `Codable` if persisted
- **ViewModel**: `@Observable` class, owns business logic and timer state
- **View**: purely declarative, renders state, forwards actions to ViewModel — no logic

## Project Structure
```
pomodoro timer/
├── App/
│   └── pomodoro_timerApp.swift
├── Models/
│   └── TimerSession.swift
├── ViewModels/
│   └── PomodoroViewModel.swift
├── Views/
│   ├── ContentView.swift
│   ├── TimerView.swift
│   └── SettingsView.swift
└── Services/
    └── NotificationService.swift
```

## State Management Rules
| Tool | When to use |
|---|---|
| `@State` | Local, ephemeral view state only |
| `@Observable` / `@StateObject` | ViewModel owned by a view |
| `@Environment` / `@EnvironmentObject` | Shared state down the tree |
| `@AppStorage` | Simple settings persistence via UserDefaults |

## Code Standards
- No force unwraps (`!`) — use `guard`, `if let`, or defaults
- No singletons except where platform requires (e.g. `UNUserNotificationCenter`)
- No logic inside Views
- Model timer states as `enum` (idle, running, paused, finished) — not boolean flags
- Dependency injection: ViewModels are injected into Views, never created inside them
- All types `PascalCase`, all vars/functions `camelCase`
- Private internals always marked `private`
- Extensions grouped by protocol conformance

## Collaboration Rules
- When unsure about any design decision (UI, UX, feature scope, data model), ask the user before implementing
- Document every design decision made in the "Design Decisions" section below as we go
- Never assume — always ask when ambiguous

## Design Decisions
<!-- Decisions get logged here as we make them -->

## What We Never Do
- No UIKit
- No Storyboards
- No singletons (except platform-mandated)
- No logic in Views
- No force unwraps
- No callbacks (use async/await)
