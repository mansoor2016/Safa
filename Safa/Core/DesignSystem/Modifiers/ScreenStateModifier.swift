// MARK: - ScreenStateModifier.swift
// PURPOSE: View modifier to replace content with ErrorView when an error occurs
// DEPENDENCIES: SwiftUI, ErrorView

import SwiftUI

struct ScreenErrorModifier: ViewModifier {
    let error: Error?
    let retry: (() async -> Void)?

    func body(content: Content) -> some View {
        if error != nil {
            ErrorView.loadFailed(retry: retry)
        } else {
            content
        }
    }
}

extension View {
    func screenError(_ error: Error?, retry: (() async -> Void)? = nil) -> some View {
        modifier(ScreenErrorModifier(error: error, retry: retry))
    }
}
