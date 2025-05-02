//
//  PreferencesView.swift
//  BeeAway
//
//  Created by Agarwal, Rahul on 01/05/25.
//

import SwiftUI

struct PreferencesView: View {
    @StateObject private var model = PreferencesViewModel()
    var close: () -> Void = {}

    var body: some View {
        VStack {
            HStack {
                Text("Bound Apps").font(.headline)
                Spacer()
                Button(action: openPanel) {
                    Image(systemName: "plus")
                }.help("Add a new app")
                Button(action: model.removeSelected) {
                    Image(systemName: "minus")
                }
                .help("Remove selected app(s)")
                .disabled(model.selection.isEmpty)
            }
            List(selection: $model.selection) {
                ForEach(model.apps) { app in
                    Text(app.name).tag(app.id)
                }
            }
            .frame(width: 360, height: 300)

            HStack {
                Spacer()
                Button("Done") {
                    close()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
    }

    private func openPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.applicationBundle]
        panel.title = "Select Application(s)"

        guard panel.runModal() == .OK else { return }
        model.add(urls: panel.urls)
    }
}
