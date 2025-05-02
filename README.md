# BeeAway <img src="logo.svg" width="24" />

BeeAway is a lightweight macOS menu-bar utility that keeps your Mac “active” by simulating user input just before the system idle timeout. It can wiggle the mouse or “ping” selected menu-bar app icons (e.g. Teams) so that apps never mark you as “away.” It adapts to battery vs. AC power, supports custom activation durations, and pauses itself when battery is low.

Please find more details [here](https://therahulagarwal.com/bee-away)

## Table of Contents

- [Installation](#installation)
  - [Download & Drag-and-Drop](#download--drag-and-drop)
  - [Homebrew](#homebrew)
- [Features](#features)
- [Usage](#usage)
- [Permissions](#permissions)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Installation

### Download & Drag-and-Drop
1. Download the latest signed & notarized `.dmg` from the [Releases](#) page.  
2. Open the `.dmg` and drag **BeeAway** to your **Applications** folder.  
3. Launch **BeeAway**. Grant Accessibility and Notification permissions when prompted.

### Homebrew
If you prefer Homebrew:
```bash
brew install --cask BeeAway
```

You can also tap a custom repo:
```bash
brew tap ragarwalll/tap
brew install BeeAway
```

## Features

- **Menu-Bar Utility**  
  Installs a status-bar icon you click to open its menu.

- **Keep-Alive Methods**  
  - **Mouse Wiggle:** Moves the cursor by 1 px right/left at the scheduled interval.  
  - **App Ping:** Activates/bounces bound apps by their menu-bar icons (no mouse movement).

- **Power-Aware Scheduling**  
  - Reads your system’s idle sleep timeout via `pmset`.  
  - Uses separate intervals for battery vs. AC power.  
  - Automatically pauses on low battery (default ≤ 20%) and resumes on AC.

- **Custom Activation Duration**  
  Choose from “Indefinitely,” 1 min, 5 min, 10 min, 15 min, 30 min, 1 hr, 2 hr, 5 hr. The selected duration shows a ✔︎.

- **App Binding**  
  In Preferences, select which installed apps (by bundle ID) to ping instead of mouse wiggle.

- **User-Activity Aware**  
  Monitors global mouse & keyboard events. If you interact, the keep-alive timer resets.

- **First-Run Onboarding**  
  Detects and guides you through granting Accessibility and Notification permissions with a SwiftUI window.

- **Notifications**  
  Notifies you when it auto-pauses due to low battery.

- **Reset & Preferences**  
  - **Reset Permissions:** Clear first-run state and re-invoke onboarding.  
  - **Preferences:** Choose bound apps and manage “Launch at Login” (if enabled).

## Usage

1. Click the menu-bar icon to open the menu.  
2. Select **Activate for Duration** → choose a duration.  
   - ✔︎ indicates the current selection (defaults to “Indefinitely”).  
3. Optionally open **Preferences** (⌘ ,) to bind apps:  
   - Toggle any running apps to have them pinged each interval.  
4. To stop keep-alive at any time, choose **Stop Keep-Alive** (⌃ T).  
5. The app auto-pauses if battery falls below the low-battery threshold (default 20%) and resumes on AC.

## Permissions

- **Accessibility**  
  Required to simulate mouse events and control other apps. Grant in **System Settings → Privacy & Security → Accessibility**.

- **Notifications**  
  Used to notify on low battery. Grant in **System Settings → Notifications → BeeAway**.

The first-run onboarding window will guide you through granting these automatically.

## Troubleshooting

- **No Status-Bar Icon**  
  Ensure Accessibility access is granted; check Console for Core Graphics errors.

- **Notifications Not Delivered**  
  Verify Notification permission in System Settings.

## Contributing

Contributions and bug reports are welcome! Please open issues or pull requests on [GitHub](https://github.com/yourorg/BeeAway).

## License

This project is provided under the MIT License. See the [LICENSE](LICENSE) file for details.
