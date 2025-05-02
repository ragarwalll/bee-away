//
//  StatusBarManager.swift
//  BeeAway
//
//  Created by Agarwal, Rahul on 01/05/25.
//

import AppKit
import Cocoa
import IOKit.ps
import SwiftUI
import UserNotifications

private func powerSourceChanged(
    _ context: UnsafeMutableRawPointer?
) {
    guard let context = context else { return }
    let manager = Unmanaged<StatusBarManager>
        .fromOpaque(context)
        .takeUnretainedValue()
    manager.updatePowerState()
}

class StatusBarManager: NSObject, NSWindowDelegate {
    // Status-bar Menu
    var statusBarItem: NSStatusItem?
    var movementTimer: DispatchSourceTimer?
    var eventMonitor: Any?
    private var lastUserEventTime = Date()

    // Menu Items
    var startItem: NSMenuItem!
    var stopItem: NSMenuItem!

    // Idle Timeouts
    private var batteryIdleTimeout: TimeInterval = 120
    private var acIdleTimeout: TimeInterval = 600
    private let safetyMargin: TimeInterval = 0.5

    // Windows
    var onboardingWindow: NSWindow?
    var preferencesWindow: NSWindow?

    // Others
    private let batteryLowThreshold: Int = 20
    var psRunLoopSrc: CFRunLoopSource?
    var durationTimer: Timer?
    private(set) var isOnAC = false

    override init() {
        super.init()
        subscribeToPowerNotifications()
        readPmsetIdleTimeouts()
        startUserInputMonitor()

        let defaults = UserDefaults.standard
        let firstRun = !defaults.bool(forKey: "HasLaunchedBefore")

        if firstRun && !AXIsProcessTrusted() {
            defaults.set(true, forKey: "HasLaunchedBefore")
            DispatchQueue.main.async { self.showOnboarding() }
        }
    }

    deinit {
        // 1) Remove the IOKit run‐loop source
        if let src = psRunLoopSrc {
            CFRunLoopRemoveSource(
                CFRunLoopGetCurrent(),
                src,
                CFRunLoopMode.defaultMode
            )
        }

        // 2) Remove your global event monitor
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }

        // 3) Remove any NotificationCenter observers you've registered
        NotificationCenter.default.removeObserver(self)
    }

    // Main function to setup the status bar
    func setupStatusBar() {
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let statusBarItem = statusBarItem else { return }
        guard let button = statusBarItem.button else { return }

        if let img = NSImage(named: "BeeVector") {
            img.isTemplate = false
            button.image = img
        } else {
            button.title = "🐝"
        }
        button.image?.isTemplate = true
        button.target = self
        button.action = #selector(showMenu(_:))

        // setup menu
        let menu = NSMenu()
        menu.autoenablesItems = false

        // setup start menu
        self.startItem = NSMenuItem(
            title: "Start Keep-Alive",
            action: #selector(startKeepAlive),
            keyEquivalent: "s"
        )

        guard let startItem = startItem else { return }

        startItem.target = self
        startItem.isEnabled = true

        // setup stop menu
        self.stopItem = NSMenuItem(
            title: "Stop Keep-Alive",
            action: #selector(stopKeepAlive),
            keyEquivalent: "t"
        )

        guard let stopItem = stopItem else { return }

        stopItem.target = self
        stopItem.isEnabled = false

        // add start-stop to menu
        menu.addItem(startItem)
        menu.addItem(stopItem)

        menu.addItem(.separator())

        // setup active for
        let durationItem = NSMenuItem(
            title: "Activate for Duration",
            action: nil,
            keyEquivalent: ""
        )

        let durationSubmenu = NSMenu()
        func addDuration(_ title: String, seconds: TimeInterval?) {
            let singleMenuItem = NSMenuItem(
                title: title,
                action: #selector(durationSelected(_:)),
                keyEquivalent: ""
            )
            singleMenuItem.target = self
            // Store the seconds in the item's representedObject
            singleMenuItem.representedObject = seconds as NSNumber?
            durationSubmenu.addItem(singleMenuItem)
        }

        addDuration("Indefinitely (Default)", seconds: nil)
        addDuration("1 minutes", seconds: 60)
        addDuration("5 minutes", seconds: 5 * 60)
        addDuration("10 minutes", seconds: 10 * 60)
        addDuration("15 minutes", seconds: 15 * 60)
        addDuration("30 minutes", seconds: 30 * 60)
        addDuration("1 hour", seconds: 60 * 60)
        addDuration("2 hours", seconds: 2 * 60 * 60)
        addDuration("5 hours", seconds: 5 * 60 * 60)

        if let first = durationSubmenu.items.first {
            first.state = .on
        }

        durationItem.submenu = durationSubmenu
        durationItem.target = self
        durationItem.isEnabled = true
        menu.addItem(durationItem)

        // setup user preferences menu
        let preferencesMenuItem = NSMenuItem(
            title: "Preferences…",
            action: #selector(showPreferences),
            keyEquivalent: ","
        )

        preferencesMenuItem.target = self
        preferencesMenuItem.isEnabled = true
        menu.addItem(preferencesMenuItem)

        menu.addItem(.separator())

        let resetMenuItem = NSMenuItem(
            title: "Reset",
            action: #selector(resetPermissions),
            keyEquivalent: "."
        )

        resetMenuItem.target = self
        resetMenuItem.isEnabled = true
        menu.addItem(resetMenuItem)

        // setup quit menu
        let quitMenuItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )

        quitMenuItem.target = self
        quitMenuItem.isEnabled = true
        menu.addItem(quitMenuItem)

        statusBarItem.menu = menu
    }

    @objc func durationSelected(_ sender: NSMenuItem) {
        // 1) Clear any existing auto-stop timer
        durationTimer?.invalidate()
        durationTimer = nil

        // 2) Update submenu checkmarks
        if let menu = sender.menu {
            for item in menu.items {
                item.state = (item == sender) ? .on : .off
            }
        }

        // 3) Immediately start keep-alive
        startKeepAlive()

        // 4) If sender.representedObject = nil → indefinite → bail
        guard let num = sender.representedObject as? NSNumber,
              num.doubleValue > 0
        else { return }

        // 5) Schedule auto-stop
        let secs = num.doubleValue
        durationTimer = Timer.scheduledTimer(
            withTimeInterval: secs,
            repeats: false
        ) { [weak self] _ in
            self?.stopKeepAlive()
        }
    }

    @objc private func showMenu(_: Any?) {
        // menu is auto-shown on click
    }

    // get if user in on ac or battery
    private var currentInterval: TimeInterval {
        return isOnAC ? acIdleTimeout : batteryIdleTimeout
    }

    // funciton to start the process
    @objc func startKeepAlive() {
        guard AXIsProcessTrusted() else {
            showOnboarding()
            return
        }

        scheduleWiggleTimer()

        startItem?.isEnabled = false
        stopItem?.isEnabled = true
        print("▶️ Keep-Alive started")
    }

    // function to stop the process
    @objc func stopKeepAlive() {
        movementTimer?.cancel()
        movementTimer = nil

        startItem?.isEnabled = true
        stopItem?.isEnabled = false
        print("❌ Keep-Alive stopped")
    }

    // function to calcuate if wiggle or not
    private func scheduleWiggleTimer() {
        movementTimer?.cancel()
        updatePowerState()

        // calcuate next idle in
        let idleNeeded = currentInterval * safetyMargin
        let idleSoFar = Date().timeIntervalSince(lastUserEventTime)
        let nextIn = max(0, idleNeeded - idleSoFar)

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + nextIn)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            let idle = Date().timeIntervalSince(self.lastUserEventTime)
            if idle >= idleNeeded {
                self.moveMouseSlightly()
                self.pingBoundApps()
            }
            self.lastUserEventTime = Date()
            self.scheduleWiggleTimer()
        }
        timer.resume()
        movementTimer = timer
    }

    // check if user in handling
    private func startUserInputMonitor() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.eventMonitor = NSEvent.addGlobalMonitorForEvents(
                matching: [.mouseMoved, .leftMouseDown, .rightMouseDown,
                           .keyDown, .keyUp]
            ) { [weak self] _ in
                guard let self = self else { return }
                self.lastUserEventTime = Date()
                if self.stopItem.isEnabled {
                    self.scheduleWiggleTimer()
                }
            }
        }
        print("👀 User input monitor started")
    }

    // handler for moving the mouse
    private func moveMouseSlightly() {
        let loc = NSEvent.mouseLocation
        let newRight = CGPoint(x: loc.x + 1, y: loc.y)
        let newLeft = CGPoint(x: loc.x, y: loc.y)
        let src = CGEventSource(stateID: .hidSystemState)

        CGEvent(
            mouseEventSource: src, mouseType: .mouseMoved,
            mouseCursorPosition: newRight, mouseButton: .left
        )?.post(tap: .cghidEventTap)

        CGEvent(
            mouseEventSource: src, mouseType: .mouseMoved,
            mouseCursorPosition: newLeft, mouseButton: .left
        )?.post(tap: .cghidEventTap)

        print("🐭 Mouse wiggle")
    }

    // subscribe to when the user connects/disconnets power
    private func subscribeToPowerNotifications() {
        let runLoop = CFRunLoopGetCurrent()
        // Create a raw context pointer to self
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        // Create the run‐loop source using the C callback
        if let source = IOPSNotificationCreateRunLoopSource(
            powerSourceChanged,
            ctx
        )?.takeRetainedValue() {
            CFRunLoopAddSource(runLoop, source, .defaultMode)
        }
    }

    func updatePowerState() {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?
              .takeRetainedValue() as? [CFTypeRef],
              let powerState = list.first,
              let desc = IOPSGetPowerSourceDescription(info, powerState)?
              .takeUnretainedValue() as? [String: Any]
        else { return }

        let prevOnAC = isOnAC
        isOnAC = (desc[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue

        // If on battery, read current capacity and max
        if !isOnAC {
            if let current = desc[kIOPSCurrentCapacityKey] as? Int,
               let max = desc[kIOPSMaxCapacityKey] as? Int {
                let pct = Int((Double(current) / Double(max)) * 100.0)
                // If below threshold, auto-stop
                if pct <= batteryLowThreshold {
                    if stopItem.isEnabled {
                        stopKeepAlive()
                        notifyBatteryLow(pct)
                    }
                }
            }
        }
        // If we switched to AC or battery has recovered above threshold, reschedule
        if prevOnAC != isOnAC,
           stopItem.isEnabled {
            scheduleWiggleTimer()
        }
    }

    private func notifyBatteryLow(_ pct: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Battery Low (\(pct)%): Keep-Alive Paused"
        content.body = "Your battery is below \(batteryLowThreshold)% — auto-stop triggered."
        content.sound = .default

        // Deliver immediately
        let req = UNNotificationRequest(
            identifier: "BatteryLowKeepAlivePause",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(req) { error in
            if let error = error {
                print("Notification error:", error)
            }
        }
    }

    // read user preferences for timeout
    private func readPmsetIdleTimeouts() {
        let proces = Process()
        proces.launchPath = "/usr/bin/pmset"
        proces.arguments = ["-g", "custom"]

        let out = Pipe()
        proces.standardOutput = out
        proces.launch()
        proces.waitUntilExit()

        let data = out.fileHandleForReading.readDataToEndOfFile()
        guard let str = String(data: data, encoding: .utf8) else { return }

        for line in str.split(separator: "\n") {
            let comps = line
                .trimmingCharacters(in: .whitespaces)
                .components(separatedBy: .whitespaces)
            if comps.count >= 3, comps[0] == "Battery", comps[1] == "Sleep" {
                batteryIdleTimeout = TimeInterval(Int(comps[2]) ?? Int(batteryIdleTimeout))
            }
            if comps.count >= 3, comps[0] == "AC", comps[1] == "Sleep" {
                acIdleTimeout = TimeInterval(Int(comps[2]) ?? Int(acIdleTimeout))
            }
        }

        print("Battery idle timeout: \(batteryIdleTimeout) seconds")
        print("AC idle timeout: \(acIdleTimeout) seconds")
    }

    func pokeApp(bundleID: String) {
        guard let app = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleID)
            .first else { return }

        // Bring the app to front (makes it key).
        app.activate(options: [.activateAllWindows])

        // Optionally return focus to ourselves:
        if let runningApp = NSRunningApplication
            .runningApplications(
                withBundleIdentifier:
                Bundle.main.bundleIdentifier!
            )
            .first {
            runningApp.activate(options: [.activateAllWindows])
        }
    }

    @discardableResult
    func pingBoundApps() -> Bool {
        let bound = UserDefaults.standard
            .stringArray(forKey: "BoundApps") ?? []
        var didPoke = false
        var stillInstalled: [String] = []

        for bundleID in bound {
            let running = NSRunningApplication
                .runningApplications(withBundleIdentifier: bundleID)
            guard running.first != nil else {
                // app not running (or uninstalled) → skip it
                continue
            }
            // if we get here, it’s running
            stillInstalled.append(bundleID)
            pokeApp(bundleID: bundleID)
            didPoke = true
        }

        // Optional: prune preferences so you don’t keep dead bundleIDs
        if stillInstalled.count != bound.count {
            UserDefaults.standard.set(stillInstalled, forKey: "BoundApps")
        }

        return didPoke
    }

    @objc func showPreferences() {
        if let win = preferencesWindow {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            preferencesWindow = nil
        }

        // 2) Create your window and immediately stash it
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        preferencesWindow = window
        window.delegate = self // so we know when it actually closes

        // 3) Build your SwiftUI view, injecting a “close” callback
        let prefsView = PreferencesView {
            window.close() // this will trigger windowWillClose
        }

        // 4) Host the view _after_ you’ve stored the window
        window.contentViewController = NSHostingController(rootView: prefsView)
        window.center()
        window.title = "Preferences"

        // 5) Show it
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showOnboarding() {
        guard onboardingWindow == nil else { return }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 240),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.center()
        window.title = "Welcome to BeeAway"
        window.isReleasedWhenClosed = false
        window.delegate = self

        // Create the view‐model with your two callbacks
        let vm = OnboardingViewModel(
            onGrant: { self.openAccessibilityPrefs() },
            onContinue: { window.close() }
        )

        // Instantiate the SwiftUI view with that model
        let view = OnboardingView(model: vm)

        window.contentView = NSHostingView(rootView: view)
        window.makeKeyAndOrderFront(nil)
        onboardingWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === onboardingWindow {
            onboardingWindow = nil
        }
    }

    func openAccessibilityPrefs() {
        let url = URL(
            string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        )!
        NSWorkspace.shared.open(url)
    }

    @objc func resetPermissions() {
        // Clear first-run so A) next launch can show, B) your “firstRun” logic is reset
        UserDefaults.standard.set(false, forKey: "HasLaunchedBefore")

        // Clear running keep-alive state and duration
        stopKeepAlive()
        durationTimer?.invalidate()
        durationTimer = nil

        // Reset duration submenu checks back to “Indefinitely”
        if let menu = statusBarItem?.menu {
            for item in menu.items {
                if let sub = item.submenu {
                    sub.items.forEach { $0.state = .off }
                    sub.items.first?.state = .on
                    break
                }
            }
        }

        // Close prefs or onboarding if they’re open
        preferencesWindow?.close()
        onboardingWindow?.close()

        // Only show onboarding immediately if still untrusted:
        if !AXIsProcessTrusted() {
            DispatchQueue.main.async { self.showOnboarding() }
        }
    }

    // Manage app lifecycle
    // Quit app before confirmation
    @objc private func quitApp() {
        let alert = NSAlert()
        alert.messageText = "Quit BeeAway 😔"
        alert.informativeText = "Are you sure you want to be away & offline?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Cancel")

        if let window = NSApp.keyWindow {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn {
                    NSApp.terminate(self)
                }
            }
        } else {
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSApp.terminate(self)
            }
        }
    }
}
