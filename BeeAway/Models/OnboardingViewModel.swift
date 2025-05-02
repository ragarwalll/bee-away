//
//  OnboardingViewModel.swift
//  BeeAway
//
//  Created by Agarwal, Rahul on 02/05/25.
//

import ApplicationServices
import Combine
import Foundation

public protocol AccessibilityChecker {
    func isTrusted() -> Bool
}

// Must be public so it can be used as a default for a public init
public struct SystemAccessibilityChecker: AccessibilityChecker {
    public init() {} // public initializer
    public func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }
}

public final class OnboardingViewModel: ObservableObject {
    @Published public private(set) var isTrusted: Bool

    private let checker: AccessibilityChecker

    public var onGrant: () -> Void
    public var onContinue: () -> Void

    // public init with public default arguments
    public init(
        checker: AccessibilityChecker = SystemAccessibilityChecker(),
        onGrant: @escaping () -> Void = {},
        onContinue: @escaping () -> Void = {}
    ) {
        self.checker = checker
        self.onGrant = onGrant
        self.onContinue = onContinue
        isTrusted = checker.isTrusted()
    }

    public func refresh() {
        isTrusted = checker.isTrusted()
    }

    public func grantTapped() {
        onGrant()
    }

    public func continueTapped() {
        onContinue()
    }
}
