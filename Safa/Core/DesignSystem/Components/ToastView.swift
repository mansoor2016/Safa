// MARK: - ToastView.swift
// PURPOSE: Toast notification system for displaying brief messages
// DEPENDENCIES: SwiftUI

import SwiftUI

// MARK: - Toast Model

struct Toast: Identifiable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: TimeInterval
    let actionTitle: String?
    let action: (() -> Void)?

    enum ToastType {
        case info
        case success
        case warning
        case comingSoon

        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .comingSoon: return "clock.fill"
            }
        }

        var color: Color {
            switch self {
            case .info: return .blue
            case .success: return .green
            case .warning: return .orange
            case .comingSoon: return .purple
            }
        }
    }

    init(message: String, type: ToastType = .info, duration: TimeInterval = 2.5, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.message = message
        self.type = type
        self.duration = duration
        self.actionTitle = actionTitle
        self.action = action
    }

    static func comingSoon(_ featureName: String) -> Toast {
        Toast(
            message: "\(featureName) coming soon",
            type: .comingSoon,
            duration: 2.0
        )
    }

    static func undoAction(message: String, type: ToastType = .success, onUndo: @escaping () -> Void) -> Toast {
        Toast(
            message: message,
            type: type,
            duration: 4.0,
            actionTitle: "Undo",
            action: onUndo
        )
    }
}

// MARK: - Toast Service

@Observable
final class ToastService {
    static let shared = ToastService()

    private(set) var currentToast: Toast?
    private var dismissTask: Task<Void, Never>?

    private init() {}

    func show(_ toast: Toast) {
        dismissTask?.cancel()

        currentToast = toast

        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(toast.duration))
            guard !Task.isCancelled else { return }
            currentToast = nil
        }
    }

    func showComingSoon(_ featureName: String) {
        show(.comingSoon(featureName))
    }

    func dismiss() {
        dismissTask?.cancel()
        currentToast = nil
    }
}

// MARK: - Toast View

struct ToastView: View {
    let toast: Toast

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(toast.type.color)

            Text(toast.message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)

            if let actionTitle = toast.actionTitle, let action = toast.action {
                Spacer()

                Button {
                    action()
                    ToastService.shared.dismiss()
                } label: {
                    Text(actionTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(toast.type.color)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        }
    }
}

// MARK: - Toast Container Modifier

struct ToastContainerModifier: ViewModifier {
    @State private var toastService = ToastService.shared

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast = toastService.currentToast {
                    ToastView(toast: toast)
                        .padding(.top, 60)
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(999)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: toastService.currentToast?.id)
    }
}

extension View {
    func toastContainer() -> some View {
        modifier(ToastContainerModifier())
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Button("Show Coming Soon") {
            ToastService.shared.showComingSoon("AI Chat")
        }

        Button("Show Success") {
            ToastService.shared.show(Toast(message: "Prayer logged!", type: .success))
        }
    }
    .toastContainer()
}
