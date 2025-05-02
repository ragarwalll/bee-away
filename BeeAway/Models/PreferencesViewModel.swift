//
//  PreferencesViewModel.swift
//  BeeAway
//
//  Created by Agarwal, Rahul on 02/05/25.
//

import AppKit
import Foundation
import UniformTypeIdentifiers

struct AppEntry: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleID: String

    static func == (a: AppEntry, b: AppEntry) -> Bool {
        return a.bundleID == b.bundleID
            && a.name == b.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(bundleID)
        hasher.combine(name)
    }
}

final class PreferencesViewModel: ObservableObject {
    @Published var apps: [AppEntry] = []
    @Published var selection: Set<UUID> = []

    private let defaultsKey = "BoundApps"

    init() {
        load()
    }

    func load() {
        let stored = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        apps = stored.compactMap { bundleID in
            guard
                let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
                let bundle = Bundle(url: url),
                let name = bundle.object(forInfoDictionaryKey: "CFBundleName")
                as? String
            else { return nil }
            return AppEntry(name: name, bundleID: bundleID)
        }
    }

    func save() {
        let ids = apps.map(\.bundleID)
        UserDefaults.standard.set(ids, forKey: defaultsKey)
    }

    func add(urls: [URL]) {
        var didChange = false
        for url in urls {
            guard
                let bundle = Bundle(url: url),
                let bundleID = bundle.bundleIdentifier,
                let name = bundle.object(forInfoDictionaryKey: "CFBundleName")
                as? String
            else { continue }
            let entry = AppEntry(name: name, bundleID: bundleID)
            if !apps.contains(entry) {
                apps.append(entry)
                didChange = true
            }
        }
        if didChange { save() }
    }

    func removeSelected() {
        let before = apps.count
        apps.removeAll { selection.contains($0.id) }
        if apps.count != before {
            save()
            selection.removeAll()
        }
    }
}
