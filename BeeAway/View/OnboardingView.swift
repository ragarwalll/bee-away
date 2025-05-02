//
//  OnboardingView.swift
//  BeeAway
//
//  Created by Agarwal, Rahul on 01/05/25.
//

import Combine
import SwiftUI

public struct OnboardingView: View {
    @StateObject private var model: OnboardingViewModel

    // Add a timer publisher to the view
    private let pollTimer = Timer
        .publish(every: 1.0, on: .main, in: .common)
        .autoconnect()

    public init(model: OnboardingViewModel) {
        _model = StateObject(wrappedValue: model)
    }

    public var body: some View {
        VStack(spacing: 20) {
            if model.isTrusted {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                Text("Accessibility Granted")
                    .font(.headline)
                Text("Thank you! BeeAway now has the permissions it needs.")
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Continue") {
                    model.continueTapped()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!model.isTrusted)

            } else {
                Image(systemName: "shield.slash")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                Text("Grant Accessibility Permission")
                    .font(.headline)
                Text("""
                To keep you online by simulating input, BeeAway \
                requires Accessibility access. Click “Open Settings” below, \
                then add this app under System Settings → Privacy & Security → \
                Accessibility.
                """)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 20) {
                    Button("Open Settings") {
                        model.grantTapped()
                    }
                    Button("I’ve Granted Access") {
                        model.refresh()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!model.isTrusted)
                }
            }
        }
        .padding()
        .frame(minWidth: 360, minHeight: 240)
        // Listen to the timer and refresh the model every second:
        .onReceive(pollTimer) { _ in
            model.refresh()
        }
    }
}
