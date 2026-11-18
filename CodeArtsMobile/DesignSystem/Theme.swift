import SwiftUI
import UIKit

enum Theme {
    static let accent = Color(red: 0.106, green: 0.396, blue: 0.878)
    static let blue = Color(red: 0.129, green: 0.427, blue: 0.898)
    static let purple = Color(red: 0.443, green: 0.298, blue: 0.898)
    static let green = Color(red: 0.114, green: 0.596, blue: 0.396)
    static let orange = Color(red: 0.937, green: 0.541, blue: 0.129)
    static let teal = Color(red: 0.098, green: 0.573, blue: 0.612)
    static let pink = Color(red: 0.851, green: 0.267, blue: 0.514)
    static let indigo = Color(red: 0.341, green: 0.373, blue: 0.851)
    static let brown = Color(red: 0.545, green: 0.435, blue: 0.322)

    enum Radius {
        static let card: CGFloat = 16
        static let control: CGFloat = 12
    }

    enum Spacing {
        static let tight: CGFloat = 8
        static let regular: CGFloat = 16
        static let loose: CGFloat = 24
    }

    static var background: Color {
        Color(uiColor: .systemGroupedBackground)
    }

    static var surface: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }
}

struct CardContainer<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Theme.Spacing.regular)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
}

struct SettingRow: View {
    let symbol: String
    let title: String
    var value: String? = nil
    var tint: Color = Theme.accent
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(title)
                .font(.body)

            Spacer(minLength: 8)

            if let value {
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .contentShape(Rectangle())
    }
}

struct ToastView: View {
    let message: ToastMessage

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: message.symbol)
                .foregroundStyle(.white)
            Text(message.text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.82), in: Capsule())
        .padding(.bottom, 28)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}