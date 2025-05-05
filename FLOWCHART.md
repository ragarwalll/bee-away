## BeeAway Flowchart

Please refer to the following diagrams for a high-level overview of the BeeAway app architecture and its components.

## Table of Contents
- [High Level Components Diagram](#high-level-components-diagram)
- [Detailed Sequence Diagram (Start Keep-Alive → Wiggle → Power Change)](#detailed-sequence-diagram-start-keep-alive--wiggle--power-change)
- [Component & Data‐Flow Diagram (high‐to‐low level)](#component--data-flow-diagram-high-to-low-level)
- [Deep Sequence Diagram (App Launch → Full Keep-Alive Lifecycle)](#deep-sequence-diagram-app-launch--full-keep-alive-lifecycle)

## High Level Components Diagram

```mermaid
flowchart TB
  subgraph App
    A[BeeAwayApp] --> B[StatusBarManager]
    A --> C[NotificationAuthorizing]
  end

  subgraph StatusBarManager
    B --> D[Menu Bar Icon & Menu]
    B --> E[IOKit Power Watcher]
    B --> F[User Input Monitor]
    B --> G[Wiggle Scheduler]
    B --> H[PMSet Timeout Reader]
    B --> I[Accessibility Onboarding]
    B --> J[Preferences Window]
  end

  C -- requests --> K[UNUserNotificationCenter]
  E -- powerSourceChanged() --> B
  F -- global/local events --> B
  G -- DispatchSourceTimer --> B
  H -- pmset -g custom --> B
  I -- AXIsProcessTrusted --> B
  J -- SwiftUI PreferencesView --> B
```

## Detailed Sequence Diagram (Start Keep-Alive → Wiggle → Power Change)

```mermaid
sequenceDiagram
  autonumber
  participant User
  participant App as BeeAwayApp
  participant SBM as StatusBarManager
  participant AX as Accessibility (System Prefs)
  participant IOKit as IOKit
  participant Timer as DispatchSourceTimer
  participant PM as pmset
  participant UN as UNUserNotificationCenter

  User->>App: Launch
  App->>SBM: setupStatusBar()
  App->>UN: requestAuthorization(.alert,.sound)
  UN-->>App: granted?
  App->>App: setActivationPolicy(.accessory)

  User->>SBM: Click “Start Keep-Alive”
  SBM->>AX: AXIsProcessTrusted()
  alt not trusted
    AX-->>SBM: false
    SBM->>I: showOnboarding()
  else trusted
    AX-->>SBM: true
    SBM->>SBM: setDisplayAssertion(on)
    SBM->>SBM: scheduleWiggleTimer()
  end

  Note over SBM: scheduleWiggleTimer computes nextIn = idle*0.5

  SBM->>Timer: start timer(after nextIn)
  Timer-->>SBM: timer fired
  SBM->>SBM: check idleTime >= needed?
  alt idle
    SBM->>SBM: moveMouseSlightly()
    SBM->>SBM: pingBoundApps()
  end
  SBM->>SBM: scheduleWiggleTimer()  loop

  IOKit->>SBM: powerSourceChanged()
  SBM->>SBM: updatePowerState()
  alt on battery & batteryLow
    SBM->>SBM: stopKeepAlive()
    SBM->>UN: notifyBatteryLow()
  else switched power
    SBM->>SBM: rescheduleWiggleTimer()
  end
```

## Component & Data‐Flow Diagram (high‐to‐low level)

```mermaid
flowchart LR
  A["BeeAwayApp @main"]
  B["StatusBarManager.shared"]
  C["UNUserNotificationCenter"]
  D["Settings Scene"]
  E["CFRunLoopSource (IOKit)"]
  F["GlobalEventMonitor"]
  G["LocalEventMonitor"]
  H["Process: pmset -g custom"]
  I["DispatchSourceTimer"]
  J["AXIsProcessTrusted()"]
  K["PreferencesView / OnboardingView"]
  L["requestAuthorization(.alert, .sound)"]

  A --> B
  A --> C
  A --> D

  C --> L
  L --> A

  B --> E
  B --> F
  B --> G
  B --> H
  B --> I
  B --> J
  B --> K

  E --> B
  F --> B
  G --> B
  H --> B
  I --> B

```

## Deep Sequence Diagram (App Launch → Full Keep-Alive Lifecycle)

```mermaid
sequenceDiagram
  participant User
  participant App as BeeAwayApp
  participant SBM as StatusBarManager
  participant UN as UNUserNotificationCenter
  participant IOK as IOKit
  participant PM as Process(pmset)
  participant Timer as DispatchSourceTimer
  participant AX as Accessibility
  participant UI as Onboarding/Prefs

  Note over App: App startup
  App->>SBM: init()
  SBM->>SBM: subscribeToPowerNotifications()
  SBM->>PM: readPmsetIdleTimeouts() async
  PM-->>SBM: batteryIdleTimeout, acIdleTimeout
  SBM->>SBM: startUserInputMonitor()
  SBM->>SBM: observe willSleep/didWake
  App->>UN: requestAuthorization(.alert,.sound)
  UN-->>App: granted?
  App->>App: setActivationPolicy(.accessory)
  App->>SBM: setupStatusBar()

  Note over User,SBM: User clicks “Start Keep-Alive”
  User->>SBM: startKeepAlive()
  SBM->>AX: AXIsProcessTrusted()
  alt Not Trusted
    AX-->>SBM: false
    SBM->>UI: showOnboarding()
    User->>UI: grant in System Prefs
    UI->>AX: user grants trust
    AX-->>SBM: now true
    SBM->>SBM: startKeepAlive()  (via trustPollTimer or re-click)
  else Trusted
    AX-->>SBM: true
    SBM->>SBM: setDisplayAssertion(on)
    SBM->>SBM: scheduleWiggleTimer()
  end

  Note over SBM: Wiggle cycle
  loop IdleCycle
    SBM->>SBM: compute nextIn = currentInterval*0.5 - idleSoFar
    SBM->>Timer: schedule(after nextIn)
    Timer-->>SBM: fired
    SBM->>SBM: check idle >= needed?
    alt Idle Enough
      SBM->>SBM: moveMouseSlightly()
      SBM->>SBM: pingBoundApps()
      SBM->>SBM: lastUserEventTime = now
    else User Active
      SBM->>SBM: lastUserEventTime updated by input monitor
    end
  end

  Note over IOK: Power events
  IOK->>SBM: powerSourceChanged()
  SBM->>SBM: updatePowerState()
  alt on Battery & low%
    SBM->>SBM: stopKeepAlive()
    SBM->>UN: notifyBatteryLow()
  else switched
    SBM->>SBM: scheduleWiggleTimer()
  end

  Note over User,SBM: User stops or app quits
  User->>SBM: stopKeepAlive()
  SBM->>SBM: wiggleTimer cancel, assertion release
  User->>SBM: quitApp()
  SBM->>UI: alertSheet
  User->>SBM: confirm
  SBM->>App: NSApp.terminate()
```

